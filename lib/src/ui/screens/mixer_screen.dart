import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../../imaging/button_maker.dart' show IntRect;
import '../../imaging/codecs.dart';
import '../../imaging/compositor.dart';
import '../app_state.dart';
import '../widgets/checker_image.dart';

/// "Frankensprite" mixer: snip a region from one sprite and place it on another
/// (e.g. one character's head on another's body), then save it as a new emote.
class MixerScreen extends StatefulWidget {
  const MixerScreen({super.key});

  @override
  State<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends State<MixerScreen> {
  String? _base;
  String? _overlay;
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

  Future<Uint8List?> _composite(AppState app) async {
    final String? baseRel = _base == null ? null : app.relForBase(_base!);
    final String? ovRel = _overlay == null ? null : app.relForBase(_overlay!);
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

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<String> bases = app.spriteBases();
    _base ??= bases.isNotEmpty ? bases.first : null;
    _overlay ??= bases.length > 1 ? bases[1] : (bases.isNotEmpty ? bases.first : null);

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
        SizedBox(width: 360, child: _controls(app, bases)),
      ],
    );
  }

  Widget _controls(AppState app, List<String> bases) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        Text('Frankensprite mixer', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _picker('Body (base)', _base, bases, (String? v) => setState(() => _base = v)),
        _picker('Snip from (overlay)', _overlay, bases, (String? v) => setState(() => _overlay = v)),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Ellipse snip (good for heads)'),
          value: _ellipse,
          onChanged: (bool v) => setState(() => _ellipse = v),
        ),
        const Divider(),
        Text('Snip region (of overlay)', style: Theme.of(context).textTheme.labelLarge),
        _slider('X', _cx, (double v) => setState(() => _cx = v)),
        _slider('Y', _cy, (double v) => setState(() => _cy = v)),
        _slider('Width', _cw, (double v) => setState(() => _cw = v), min: 0.02, max: 1),
        _slider('Height', _ch, (double v) => setState(() => _ch = v), min: 0.02, max: 1),
        const Divider(),
        Text('Placement (on body)', style: Theme.of(context).textTheme.labelLarge),
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

  Widget _picker(String label, String? value, List<String> items,
          ValueChanged<String?> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
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
