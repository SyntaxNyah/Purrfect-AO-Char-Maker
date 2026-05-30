import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../../imaging/button_maker.dart' show IntRect;
import '../../imaging/codecs.dart';
import '../../imaging/color_ops.dart';
import '../../imaging/compositor.dart';
import '../../platform/folder_picker.dart';
import '../app_state.dart';
import '../widgets/checker_image.dart';

/// "Frankensprite" mixer: snip a region from one sprite and place it on another
/// (e.g. one character's head on another's body), then save it as a new emote.
///
/// Performance: the preview is **debounced** and rendered on a **downscaled**
/// copy into a [ValueNotifier], so dragging a slider no longer re-decodes and
/// re-composites at full resolution on every frame (only "Save" bakes full-res).
class MixerScreen extends StatefulWidget {
  const MixerScreen({super.key});

  @override
  State<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends State<MixerScreen> {
  String? _base; // body base, always from the project
  String? _overlay; // base to snip from, within the chosen source
  String? _partsSource; // null = "this project", else a MixSource label
  bool _ellipse = true;

  // crop of the overlay (fractions 0..1)
  double _cx = 0.25, _cy = 0.0, _cw = 0.5, _ch = 0.45;
  // placement on the base (fractions) + transform
  double _px = 0.5, _py = 0.22, _scale = 1.0, _angle = 0, _opacity = 1.0;
  // snip post-processing
  bool _flipH = false, _flipV = false;
  double _feather = 0;
  double _snipHue = 0, _snipSat = 1, _snipBri = 1;
  // output crop (fractions of the final image)
  double _cropL = 0, _cropT = 0, _cropR = 0, _cropB = 0;

  final TextEditingController _name = TextEditingController(text: 'mix');
  final ValueNotifier<Uint8List?> _preview = ValueNotifier<Uint8List?>(null);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _compute();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _preview.dispose();
    _name.dispose();
    super.dispose();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _compute);
  }

  Future<void> _compute() async {
    final AppState app = context.read<AppState>();
    final Uint8List? bytes = await _composite(app, preview: true);
    if (mounted) _preview.value = bytes;
  }

  /// Base names available to snip from, given the selected parts source.
  List<String> _overlayBases(AppState app) {
    if (_partsSource == null) return app.spriteBases();
    return app.mixSources
            .firstWhereOrNull((MixSource m) => m.label == _partsSource)
            ?.bases ??
        const <String>[];
  }

  /// Resolve the chosen overlay base to a file path (project or parts source).
  String? _overlayRel(AppState app) {
    if (_overlay == null) return null;
    return _partsSource == null
        ? app.relForBase(_overlay!)
        : app.relForMixBase(_partsSource!, _overlay!);
  }

  Future<Uint8List?> _composite(AppState app, {required bool preview}) async {
    final String? baseRel = _base == null ? null : app.relForBase(_base!);
    final String? ovRel = _overlayRel(app);
    if (baseRel == null || ovRel == null) return null;
    img.Image? base = await app.decodeFirstFrame(baseRel);
    img.Image? ov = await app.decodeFirstFrame(ovRel);
    if (base == null || ov == null) return null;

    // Live preview works on a downscaled copy; Save bakes full resolution.
    if (preview) {
      base = _downscale(base, 480);
      ov = _downscale(ov, 480);
    }

    final IntRect rect = IntRect(
      (_cx * ov.width).round().clamp(0, ov.width - 1),
      (_cy * ov.height).round().clamp(0, ov.height - 1),
      (_cw * ov.width).round().clamp(1, ov.width),
      (_ch * ov.height).round().clamp(1, ov.height),
    );
    final CutResult cut =
        _ellipse ? Compositor.cutEllipse(ov, rect) : Compositor.cutRect(ov, rect);

    img.Image piece = cut.image;
    if (_flipH) piece = _flip(piece, horizontal: true);
    if (_flipV) piece = _flip(piece, horizontal: false);
    if (_feather > 0.5) piece = _featherEdges(piece, _feather.round());
    final List<ColorOp> snipOps = <ColorOp>[
      if (_snipHue.abs() > 0.5)
        ColorOp('hueShift', nums: <String, double>{'degrees': _snipHue}),
      if ((_snipSat - 1).abs() > 0.01)
        ColorOp('saturation', nums: <String, double>{'amount': _snipSat}),
      if ((_snipBri - 1).abs() > 0.01)
        ColorOp('brightness', nums: <String, double>{'amount': _snipBri}),
    ];
    if (snipOps.isNotEmpty) ImageOps.applyAll(piece, snipOps);

    final int topLeftX = (_px * base.width - piece.width * _scale / 2).round();
    final int topLeftY = (_py * base.height - piece.height * _scale / 2).round();
    img.Image result = Compositor.place(
      base,
      piece,
      x: topLeftX,
      y: topLeftY,
      scale: _scale,
      angle: _angle,
      opacity: _opacity,
    );

    if (_cropL > 0 || _cropT > 0 || _cropR > 0 || _cropB > 0) {
      final int x0 = (_cropL * result.width).round();
      final int y0 = (_cropT * result.height).round();
      final int x1 = result.width - (_cropR * result.width).round();
      final int y1 = result.height - (_cropB * result.height).round();
      final int w = x1 - x0, h = y1 - y0;
      if (w >= 1 && h >= 1) {
        result = img.copyCrop(result, x: x0, y: y0, width: w, height: h);
      }
    }
    return Codecs.encodePng(result);
  }

  // ---- image helpers (operate on owned copies, never the decode cache) -------

  img.Image _downscale(img.Image im, int maxEdge) {
    final int longest = im.width > im.height ? im.width : im.height;
    if (longest <= maxEdge) return im;
    final double s = maxEdge / longest;
    return img.copyResize(im,
        width: (im.width * s).round(),
        height: (im.height * s).round(),
        interpolation: img.Interpolation.average);
  }

  img.Image _flip(img.Image im, {required bool horizontal}) {
    final img.Image out = img.Image(width: im.width, height: im.height, numChannels: 4);
    for (int y = 0; y < im.height; y++) {
      for (int x = 0; x < im.width; x++) {
        final img.Pixel p = im.getPixel(
            horizontal ? im.width - 1 - x : x, horizontal ? y : im.height - 1 - y);
        out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), p.a.toInt());
      }
    }
    return out;
  }

  img.Image _featherEdges(img.Image im, int radius) {
    if (radius <= 0) return im;
    final img.Image src = im.clone();
    for (int y = 0; y < im.height; y++) {
      for (int x = 0; x < im.width; x++) {
        final img.Pixel p = src.getPixel(x, y);
        if (p.a.toInt() == 0) continue;
        int opaque = 0, total = 0;
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            total++;
            final int xx = x + dx, yy = y + dy;
            if (xx < 0 || yy < 0 || xx >= im.width || yy >= im.height) continue;
            if (src.getPixel(xx, yy).a.toInt() > 8) opaque++;
          }
        }
        final int na = (p.a.toInt() * (opaque / total)).round().clamp(0, 255);
        im.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), na);
      }
    }
    return im;
  }

  Future<void> _loadPartsFolder(AppState app) async {
    final List<PickedFolderFile>? files = await pickFolderFiles();
    if (files == null || files.isEmpty) return;
    await app.importMixParts(<PickedFile>[
      for (final PickedFolderFile f in files) PickedFile(f.name, f.bytes),
    ]);
    if (app.mixSources.isNotEmpty) {
      setState(() {
        _partsSource = app.mixSources.last.label;
        _overlay = null;
      });
    }
    _schedule();
  }

  void _reset() {
    setState(() {
      _cx = 0.25;
      _cy = 0;
      _cw = 0.5;
      _ch = 0.45;
      _px = 0.5;
      _py = 0.22;
      _scale = 1;
      _angle = 0;
      _opacity = 1;
      _flipH = false;
      _flipV = false;
      _feather = 0;
      _snipHue = 0;
      _snipSat = 1;
      _snipBri = 1;
      _cropL = _cropT = _cropR = _cropB = 0;
    });
    _schedule();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<String> bases = app.spriteBases();
    _base ??= bases.isNotEmpty ? bases.first : null;

    if (_partsSource != null &&
        app.mixSources.every((MixSource m) => m.label != _partsSource)) {
      _partsSource = null;
    }
    final List<String> overlayBases = _overlayBases(app);
    if (!overlayBases.contains(_overlay)) {
      _overlay = overlayBases.isNotEmpty ? overlayBases.first : null;
    }

    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: bases.isEmpty
                ? const Center(child: Text('Import sprites first.'))
                : ValueListenableBuilder<Uint8List?>(
                    valueListenable: _preview,
                    builder: (_, Uint8List? b, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CheckerImage(bytes: b),
                    ),
                  ),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 372, child: _controls(app, bases, overlayBases)),
      ],
    );
  }

  Widget _controls(AppState app, List<String> bases, List<String> overlayBases) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        Row(children: <Widget>[
          Expanded(
            child: Text('Frankensprite mixer',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          TextButton(onPressed: _reset, child: const Text('Reset')),
        ]),
        const SizedBox(height: 8),
        _howItWorks(),
        const SizedBox(height: 12),

        // ---- 1. Body ----
        Text('1 · Body', style: Theme.of(context).textTheme.labelLarge),
        _picker('Body (from your project)', _base, bases, (String? v) {
          setState(() => _base = v);
          _schedule();
        }),
        const Divider(),

        // ---- 2. The part to snip ----
        Text('2 · Part to graft on', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        _partsSourcePicker(app),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _loadPartsFolder(app),
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('Load a 2nd sprite folder…'),
        ),
        const SizedBox(height: 4),
        Text(
          _partsSource == null
              ? 'Snipping from your own project. To graft from another '
                  'character, dump their sprite folder above — it stays out of '
                  'your project and export.'
              : 'Snipping from the loaded folder "$_partsSource".',
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 8),
        overlayBases.isEmpty
            ? const Text('That source has no sprites yet.',
                style: TextStyle(fontSize: 12, color: Colors.orange))
            : _picker('Snip from', _overlay, overlayBases, (String? v) {
                setState(() => _overlay = v);
                _schedule();
              }),
        _switch('Ellipse snip (good for heads)', _ellipse, (bool v) => _ellipse = v),
        const Divider(),

        // ---- 3. Snip region (crop the part) ----
        Text('3 · Snip region (crop the part)',
            style: Theme.of(context).textTheme.labelLarge),
        _slider('X', _cx, (double v) => _cx = v),
        _slider('Y', _cy, (double v) => _cy = v),
        _slider('Width', _cw, (double v) => _cw = v, min: 0.02, max: 1),
        _slider('Height', _ch, (double v) => _ch = v, min: 0.02, max: 1),
        Row(children: <Widget>[
          Expanded(child: _switch('Flip H', _flipH, (bool v) => _flipH = v)),
          Expanded(child: _switch('Flip V', _flipV, (bool v) => _flipV = v)),
        ]),
        _slider('Feather', _feather, (double v) => _feather = v, min: 0, max: 6),
        const Divider(),

        // ---- 4. Match the part's colour to the body ----
        Text('4 · Recolour the part (match the body)',
            style: Theme.of(context).textTheme.labelLarge),
        _slider('Hue', _snipHue, (double v) => _snipHue = v, min: -180, max: 180),
        _slider('Saturation', _snipSat, (double v) => _snipSat = v, min: 0, max: 2),
        _slider('Brightness', _snipBri, (double v) => _snipBri = v, min: 0, max: 2),
        const Divider(),

        // ---- 5. Placement ----
        Row(children: <Widget>[
          Expanded(
            child: Text('5 · Placement (on the body)',
                style: Theme.of(context).textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _px = 0.5;
                _py = 0.5;
              });
              _schedule();
            },
            child: const Text('Center'),
          ),
        ]),
        _slider('Pos X', _px, (double v) => _px = v),
        _slider('Pos Y', _py, (double v) => _py = v),
        _slider('Scale', _scale, (double v) => _scale = v, min: 0.1, max: 3),
        _slider('Rotate', _angle, (double v) => _angle = v, min: -180, max: 180),
        _slider('Opacity', _opacity, (double v) => _opacity = v),
        const Divider(),

        // ---- 6. Crop the final result ----
        Text('6 · Crop output', style: Theme.of(context).textTheme.labelLarge),
        _slider('Left', _cropL, (double v) => _cropL = v, min: 0, max: 0.45),
        _slider('Top', _cropT, (double v) => _cropT = v, min: 0, max: 0.45),
        _slider('Right', _cropR, (double v) => _cropR = v, min: 0, max: 0.45),
        _slider('Bottom', _cropB, (double v) => _cropB = v, min: 0, max: 0.45),
        const Divider(),

        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'New sprite name'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            final Uint8List? png = await _composite(app, preview: false);
            if (png != null) await app.addCompositeSprite(_name.text, png);
          },
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save as new emote'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _howItWorks() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.lightbulb_outline, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Combine TWO sprite sets — e.g. character A\'s head on character '
              'B\'s body.\n'
              '• Body = a sprite from your loaded project.\n'
              '• Part = your project, or a 2nd folder you load below.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _partsSourcePicker(AppState app) {
    final List<DropdownMenuItem<String?>> items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('This project')),
      for (final MixSource m in app.mixSources)
        DropdownMenuItem<String?>(
          value: m.label,
          child: Text('📁 ${m.label}  (${m.groups.length})',
              overflow: TextOverflow.ellipsis),
        ),
    ];
    return Row(
      children: <Widget>[
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Snip parts from'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _partsSource,
                items: items,
                onChanged: (String? v) {
                  setState(() {
                    _partsSource = v;
                    _overlay = null;
                  });
                  _schedule();
                },
              ),
            ),
          ),
        ),
        if (_partsSource != null)
          IconButton(
            tooltip: 'Remove this loaded folder',
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              final String label = _partsSource!;
              setState(() {
                _partsSource = null;
                _overlay = null;
              });
              app.removeMixSource(label);
              _schedule();
            },
          ),
      ],
    );
  }

  Widget _picker(String label, String? value, List<String> items,
          ValueChanged<String?> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : null,
              items: <DropdownMenuItem<String>>[
                for (final String s in items)
                  DropdownMenuItem<String>(value: s, child: Text(s, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      );

  Widget _switch(String label, bool value, ValueChanged<bool> assign) =>
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 13)),
        value: value,
        onChanged: (bool v) {
          setState(() => assign(v));
          _schedule();
        },
      );

  Widget _slider(String label, double v, void Function(double) assign,
          {double min = 0, double max = 1}) =>
      Row(
        children: <Widget>[
          SizedBox(width: 64, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Slider(
              value: v.clamp(min, max),
              min: min,
              max: max,
              onChanged: (double nv) {
                setState(() => assign(nv));
                _schedule();
              },
            ),
          ),
        ],
      );
}
