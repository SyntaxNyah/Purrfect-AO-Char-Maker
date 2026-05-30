import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../../imaging/button_maker.dart' show IntRect;
import '../../imaging/codecs.dart';
import '../../imaging/compositor.dart';
import '../../platform/folder_picker.dart';
import '../app_state.dart';
import '../widgets/checker_image.dart';

/// "Frankensprite" mixer: snip a region from one sprite and place it on another
/// (e.g. one character's head on another's body), then save it as a new emote.
///
/// The **body** is a sprite from your loaded project; the part you snip can come
/// from the same project *or* from a **second folder** you dump in here as a
/// "parts" source (kept completely separate from your project + export).
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
  final TextEditingController _name = TextEditingController(text: 'mix');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
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

  Future<Uint8List?> _composite(AppState app) async {
    final String? baseRel = _base == null ? null : app.relForBase(_base!);
    final String? ovRel = _overlayRel(app);
    if (baseRel == null || ovRel == null) return null;
    final img.Image? base = await app.decodeFirstFrame(baseRel);
    final img.Image? ov = await app.decodeFirstFrame(ovRel);
    if (base == null || ov == null) return null;

    final IntRect rect = IntRect(
      (_cx * ov.width).round().clamp(0, ov.width - 1),
      (_cy * ov.height).round().clamp(0, ov.height - 1),
      (_cw * ov.width).round().clamp(1, ov.width),
      (_ch * ov.height).round().clamp(1, ov.height),
    );
    final CutResult cut =
        _ellipse ? Compositor.cutEllipse(ov, rect) : Compositor.cutRect(ov, rect);

    final int topLeftX = (_px * base.width - cut.image.width * _scale / 2).round();
    final int topLeftY = (_py * base.height - cut.image.height * _scale / 2).round();
    final img.Image result = Compositor.place(
      base,
      cut.image,
      x: topLeftX,
      y: topLeftY,
      scale: _scale,
      angle: _angle,
      opacity: _opacity,
    );
    return Codecs.encodePng(result);
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
        _overlay = null; // re-pick within the new source
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<String> bases = app.spriteBases();
    _base ??= bases.isNotEmpty ? bases.first : null;

    // Keep the parts source / overlay valid as sources come and go.
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
                : FutureBuilder<Uint8List?>(
                    future: _composite(app),
                    builder: (BuildContext c, AsyncSnapshot<Uint8List?> s) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CheckerImage(bytes: s.data),
                    ),
                  ),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 360, child: _controls(app, bases, overlayBases)),
      ],
    );
  }

  Widget _controls(AppState app, List<String> bases, List<String> overlayBases) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        Text('Frankensprite mixer', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _howItWorks(),
        const SizedBox(height: 12),

        // ---- 1. Body: always from the loaded project ----
        Text('1 · Body', style: Theme.of(context).textTheme.labelLarge),
        _picker('Body (from your project)', _base, bases,
            (String? v) => setState(() => _base = v)),
        const Divider(),

        // ---- 2. The part to snip: project OR a second folder ----
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
            : _picker('Snip from', _overlay, overlayBases,
                (String? v) => setState(() => _overlay = v)),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Ellipse snip (good for heads)'),
          value: _ellipse,
          onChanged: (bool v) => setState(() => _ellipse = v),
        ),
        const Divider(),
        Text('Snip region (of the part)', style: Theme.of(context).textTheme.labelLarge),
        _slider('X', _cx, (double v) => setState(() => _cx = v)),
        _slider('Y', _cy, (double v) => setState(() => _cy = v)),
        _slider('Width', _cw, (double v) => setState(() => _cw = v), min: 0.02, max: 1),
        _slider('Height', _ch, (double v) => setState(() => _ch = v), min: 0.02, max: 1),
        const Divider(),
        Text('Placement (on the body)', style: Theme.of(context).textTheme.labelLarge),
        _slider('Pos X', _px, (double v) => setState(() => _px = v)),
        _slider('Pos Y', _py, (double v) => setState(() => _py = v)),
        _slider('Scale', _scale, (double v) => setState(() => _scale = v), min: 0.1, max: 3),
        _slider('Rotate', _angle, (double v) => setState(() => _angle = v), min: -180, max: 180),
        _slider('Opacity', _opacity, (double v) => setState(() => _opacity = v)),
        const Divider(),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'New sprite name'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            final Uint8List? png = await _composite(app);
            if (png != null) await app.addCompositeSprite(_name.text, png);
          },
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save as new emote'),
        ),
      ],
    );
  }

  /// A short, friendly explanation of the two-folder workflow.
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

  /// Dropdown to choose where the snipped part comes from, plus a remove (✕)
  /// affordance for loaded folders.
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
                onChanged: (String? v) => setState(() {
                  _partsSource = v;
                  _overlay = null;
                }),
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

  Widget _slider(String label, double v, ValueChanged<double> onChanged,
          {double min = 0, double max = 1}) =>
      Row(
        children: <Widget>[
          SizedBox(width: 64, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Slider(
              value: v.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      );
}
