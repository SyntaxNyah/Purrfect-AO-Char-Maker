import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../imaging/color_ops.dart';
import '../../plugins/extension_registry.dart';
import '../../presets/presets.dart';
import '../app_state.dart';
import '../widgets/zoom_canvas.dart';

/// Real-time recolour. Performance notes:
///  * sliders only do a local [setState] + a debounced preview compute — they
///    never trigger a global rebuild;
///  * the (large) preset/gradient chip lists are built once and reused, so a
///    slider drag doesn't rebuild ~100 chips;
///  * the preview image lives in a [ValueNotifier] driven off a debounce timer,
///    decoupled from widget rebuilds.
///
/// Presets and gradients **blend** (stack) on top of each other and the sliders.
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

  /// Stacked presets/gradients (blended in order, after the sliders).
  final List<OpPipeline> _blend = <OpPipeline>[];

  final ValueNotifier<Uint8List?> _preview = ValueNotifier<Uint8List?>(null);
  Timer? _debounce;
  Widget? _chipsCache;

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
    super.dispose();
  }

  List<ColorOp> get _pipeline => <ColorOp>[
        if (hue.abs() > 0.5) ColorOp('hueShift', nums: <String, double>{'degrees': hue}),
        if ((sat - 1).abs() > 0.01) ColorOp('saturation', nums: <String, double>{'amount': sat}),
        if ((bri - 1).abs() > 0.01) ColorOp('brightness', nums: <String, double>{'amount': bri}),
        if ((con - 1).abs() > 0.01) ColorOp('contrast', nums: <String, double>{'amount': con}),
        for (final OpPipeline p in _blend) ...p.ops,
      ];

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 110), _compute);
  }

  Future<void> _compute() async {
    final AppState app = context.read<AppState>();
    final String? rel = app.current == null ? null : app.spriteRelFor(app.current!);
    if (rel == null) {
      _preview.value = null;
      return;
    }
    final Uint8List? bytes = await app.previewWithPipeline(rel, _pipeline);
    if (mounted) _preview.value = bytes;
  }

  void _addPreset(OpPipeline p) {
    setState(() => _blend.add(p));
    _schedule();
  }

  void _removeBlend(int i) {
    setState(() => _blend.removeAt(i));
    _schedule();
  }

  void _reset() {
    setState(() {
      hue = 0;
      sat = 1;
      bri = 1;
      con = 1;
      _blend.clear();
    });
    _schedule();
  }

  Future<void> _apply({required bool allSprites}) async {
    final AppState app = context.read<AppState>();
    if (_pipeline.isEmpty) return;
    app.setLivePipeline(_pipeline);
    await app.applyPipeline(allSprites: allSprites);
    // The look is now baked into the sprite(s); clear the live stack so the
    // preview shows the result instead of re-applying on top.
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.read<AppState>();
    final bool hasSprite =
        app.current != null && app.spriteRelFor(app.current!) != null;
    _chipsCache ??= _buildChips();

    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: hasSprite
                ? ValueListenableBuilder<Uint8List?>(
                    valueListenable: _preview,
                    builder: (_, Uint8List? b, __) => ZoomCanvas(bytes: b),
                  )
                : const Center(
                    child: Text('Select an emote (Emotes tab) to recolour it.')),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 360, child: _controls()),
      ],
    );
  }

  Widget _controls() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        Row(children: <Widget>[
          Text('Adjust', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          TextButton(onPressed: _reset, child: const Text('Reset')),
        ]),
        _slider('Hue', hue, -180, 180, (double v) => hue = v),
        _slider('Saturation', sat, 0, 3, (double v) => sat = v),
        _slider('Brightness', bri, 0, 2, (double v) => bri = v),
        _slider('Contrast', con, 0, 2, (double v) => con = v),
        const SizedBox(height: 8),
        Row(children: <Widget>[
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _apply(allSprites: false),
              icon: const Icon(Icons.brush_rounded),
              label: const Text('Apply'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => _apply(allSprites: true),
              icon: const Icon(Icons.select_all_rounded),
              label: const Text('All sprites'),
            ),
          ),
        ]),
        if (_blend.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Text('Blended (${_blend.length})',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (int i = 0; i < _blend.length; i++)
                InputChip(
                  label: Text(_blend[i].name),
                  onDeleted: () => _removeBlend(i),
                ),
            ],
          ),
        ],
        const Divider(height: 24),
        const Text('Tap presets to blend them together'),
        const SizedBox(height: 8),
        _chipsCache ?? const SizedBox.shrink(),
      ],
    );
  }

  /// Built once (presets don't change during a screen visit), so slider drags
  /// don't rebuild ~100 chips.
  Widget _buildChips() {
    final List<OpPipeline> presets = ExtensionRegistry.instance.colorPresets;
    final List<NamedGradient> grads = ExtensionRegistry.instance.gradients;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Presets (${presets.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final OpPipeline preset in presets)
              ActionChip(label: Text(preset.name), onPressed: () => _addPreset(preset)),
          ],
        ),
        const SizedBox(height: 16),
        Text('Gradient maps (${grads.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final NamedGradient g in grads)
              ActionChip(
                label: Text(g.name),
                onPressed: () => _addPreset(
                  OpPipeline(g.name, <ColorOp>[PresetLibrary.gradientMapOp(g)]),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _slider(String label, double value, double min, double max,
      void Function(double) assign) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label: ${value.toStringAsFixed(2)}'),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: (double v) {
            setState(() => assign(v));
            _schedule();
          },
        ),
      ],
    );
  }
}
