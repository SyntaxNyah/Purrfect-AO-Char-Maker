import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../imaging/color_ops.dart';
import '../../plugins/extension_registry.dart';
import '../../presets/presets.dart';
import '../app_state.dart';
import '../widgets/zoom_canvas.dart';

class ColorLabScreen extends StatefulWidget {
  const ColorLabScreen({super.key});

  @override
  State<ColorLabScreen> createState() => _ColorLabScreenState();
}

class _ColorLabScreenState extends State<ColorLabScreen> {
  double hue = 0;
  double sat = 1;
  double bri = 1;
  double con = 1;
  final List<ColorOp> _extra = <ColorOp>[];
  String _presetLabel = 'Custom';

  List<ColorOp> get _pipeline => <ColorOp>[
        if (hue.abs() > 0.5) ColorOp('hueShift', nums: <String, double>{'degrees': hue}),
        if ((sat - 1).abs() > 0.01) ColorOp('saturation', nums: <String, double>{'amount': sat}),
        if ((bri - 1).abs() > 0.01) ColorOp('brightness', nums: <String, double>{'amount': bri}),
        if ((con - 1).abs() > 0.01) ColorOp('contrast', nums: <String, double>{'amount': con}),
        ..._extra,
      ];

  void _sync(AppState app) => app.setLivePipeline(_pipeline);

  void _applyPreset(OpPipeline preset, AppState app) {
    setState(() {
      hue = 0;
      sat = 1;
      bri = 1;
      con = 1;
      _extra
        ..clear()
        ..addAll(preset.ops);
      _presetLabel = preset.name;
    });
    _sync(app);
  }

  void _reset(AppState app) {
    setState(() {
      hue = 0;
      sat = 1;
      bri = 1;
      con = 1;
      _extra.clear();
      _presetLabel = 'Custom';
    });
    _sync(app);
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final String? rel = app.current == null ? null : app.spriteRelFor(app.current!);

    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: rel == null
                ? const Center(child: Text('Select an emote (Emotes tab) to recolour it.'))
                : FutureBuilder<Uint8List?>(
                    future: app.previewWithPipeline(rel, _pipeline),
                    builder: (BuildContext c, AsyncSnapshot<Uint8List?> s) =>
                        ZoomCanvas(bytes: s.data),
                  ),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 360, child: _controls(app)),
      ],
    );
  }

  Widget _controls(AppState app) {
    final List<OpPipeline> presets = ExtensionRegistry.instance.colorPresets;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        Row(children: <Widget>[
          Text('Adjust ($_presetLabel)',
              style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          TextButton(onPressed: () => _reset(app), child: const Text('Reset')),
        ]),
        _slider('Hue', hue, -180, 180, (double v) => setState(() => hue = v), app),
        _slider('Saturation', sat, 0, 3, (double v) => setState(() => sat = v), app),
        _slider('Brightness', bri, 0, 2, (double v) => setState(() => bri = v), app),
        _slider('Contrast', con, 0, 2, (double v) => setState(() => con = v), app),
        const SizedBox(height: 8),
        Row(children: <Widget>[
          Expanded(
            child: FilledButton.icon(
              onPressed: () => app.applyPipeline(allSprites: false),
              icon: const Icon(Icons.brush_rounded),
              label: const Text('Apply'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => app.applyPipeline(allSprites: true),
              icon: const Icon(Icons.select_all_rounded),
              label: const Text('All sprites'),
            ),
          ),
        ]),
        const Divider(height: 24),
        Text('Presets (${presets.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final OpPipeline preset in presets)
              ActionChip(
                label: Text(preset.name),
                onPressed: () => _applyPreset(preset, app),
              ),
          ],
        ),
        const Divider(height: 24),
        Text('Gradient maps', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final NamedGradient g in ExtensionRegistry.instance.gradients)
              ActionChip(
                label: Text(g.name),
                onPressed: () => _applyPreset(
                  OpPipeline(g.name, <ColorOp>[PresetLibrary.gradientMapOp(g)]),
                  app,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged, AppState app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label: ${value.toStringAsFixed(2)}'),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: (double v) {
            onChanged(v);
            _sync(app);
          },
        ),
      ],
    );
  }
}
