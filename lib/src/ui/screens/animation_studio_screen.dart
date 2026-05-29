import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Easing; // our Easing (Flutter 3.29+ also has one)
import 'package:provider/provider.dart';

import '../../animation/anim_engine.dart';
import '../../animation/easing.dart';
import '../../plugins/extension_registry.dart';
import '../../presets/presets.dart';
import '../app_state.dart';
import '../widgets/checker_image.dart';

/// One-click animation. Performance: rendering is debounced and the looping
/// playback only updates a [ValueNotifier] (so it doesn't rebuild the whole
/// screen each frame); the long preset/effect chip lists are built once.
class AnimationStudioScreen extends StatefulWidget {
  const AnimationStudioScreen({super.key});

  @override
  State<AnimationStudioScreen> createState() => _AnimationStudioScreenState();
}

class _AnimationStudioScreenState extends State<AnimationStudioScreen> {
  final List<AnimRecipe> _recipes = <AnimRecipe>[];
  int _frames = 16;
  int _fps = 12;
  String _ease = 'linear';

  List<Uint8List> _frameImgs = <Uint8List>[];
  final ValueNotifier<int> _frameIdx = ValueNotifier<int>(0);
  Timer? _player;
  Timer? _debounce;
  Widget? _presetChips;
  Widget? _effectChips;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _render();
    });
  }

  @override
  void dispose() {
    _player?.cancel();
    _debounce?.cancel();
    _frameIdx.dispose();
    super.dispose();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 160), _render);
  }

  Future<void> _render() async {
    final AppState app = context.read<AppState>();
    final int n = _recipes.isEmpty ? 1 : _frames;
    final List<Uint8List> imgs =
        await app.renderAnimationPreview(_recipes, frames: n, fps: _fps);
    if (!mounted) return;
    _player?.cancel();
    // setState (once per debounced render) refreshes the displayed frame; the
    // per-frame playback below only pokes the ValueNotifier, never setState.
    setState(() => _frameImgs = imgs);
    _frameIdx.value = 0;
    if (imgs.length > 1) {
      _player = Timer.periodic(
        Duration(milliseconds: (1000 / _fps).round()),
        (_) {
          if (_frameImgs.isEmpty) return;
          _frameIdx.value = (_frameIdx.value + 1) % _frameImgs.length;
        },
      );
    }
  }

  void _applyPreset(AnimPreset preset) {
    setState(() {
      _recipes
        ..clear()
        ..addAll(preset.recipes);
      _frames = preset.frames;
      _fps = preset.fps;
    });
    _schedule();
  }

  void _addRecipe(String type) {
    setState(() => _recipes.add(AnimRecipe(type,
        p: <String, double>{'intensity': 6, 'cycles': 1}, ease: _ease)));
    _schedule();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.read<AppState>();
    _presetChips ??= _buildPresetChips();
    _effectChips ??= _buildEffectChips();

    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: app.current == null
                      ? const Center(child: Text('Select an emote to animate it.'))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ValueListenableBuilder<int>(
                            valueListenable: _frameIdx,
                            builder: (_, int idx, __) {
                              final Uint8List? b = _frameImgs.isEmpty
                                  ? null
                                  : _frameImgs[idx % _frameImgs.length];
                              return CheckerImage(bytes: b);
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(_recipes.isEmpty
                    ? 'No effects yet — pick a preset or add effects →'
                    : 'Stack: ${_recipes.map((AnimRecipe r) => r.type).join(" + ")}'),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 380, child: _controls(app)),
      ],
    );
  }

  Widget _controls(AppState app) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        Text('Frames: $_frames'),
        Slider(
          value: _frames.toDouble(),
          min: 2,
          max: 48,
          divisions: 46,
          onChanged: (double v) {
            setState(() => _frames = v.round());
            _schedule();
          },
        ),
        Text('Speed: $_fps fps'),
        Slider(
          value: _fps.toDouble(),
          min: 4,
          max: 30,
          divisions: 26,
          onChanged: (double v) {
            setState(() => _fps = v.round());
            _schedule();
          },
        ),
        Row(children: <Widget>[
          const Text('Easing:'),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _ease,
              items: <DropdownMenuItem<String>>[
                for (final String e in Easing.names)
                  DropdownMenuItem<String>(value: e, child: Text(e)),
              ],
              onChanged: (String? e) {
                if (e == null) return;
                setState(() {
                  _ease = e;
                  for (final AnimRecipe r in _recipes) {
                    r.ease = e;
                  }
                });
                _schedule();
              },
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: <Widget>[
          Expanded(
            child: FilledButton.icon(
              onPressed: _recipes.isEmpty
                  ? null
                  : () => app.saveAnimation(_recipes,
                      frames: _frames, fps: _fps, prefix: '(b)'),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save as (b) talk (WebP)'),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Save as (a) idle (WebP)',
            onPressed: _recipes.isEmpty
                ? null
                : () => app.saveAnimation(_recipes,
                    frames: _frames, fps: _fps, prefix: '(a)'),
            icon: const Icon(Icons.bedtime_outlined),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: () {
              setState(() => _recipes.clear());
              _schedule();
            },
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ]),
        if (_recipes.isNotEmpty) ...<Widget>[
          const Divider(height: 24),
          Text('Effect strength', style: Theme.of(context).textTheme.titleMedium),
          for (int i = 0; i < _recipes.length; i++) _recipeTuner(i),
        ],
        const Divider(height: 24),
        Text('Presets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _presetChips ?? const SizedBox.shrink(),
        const Divider(height: 24),
        Text('Add an effect', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _effectChips ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _recipeTuner(int i) {
    final AnimRecipe r = _recipes[i];
    final double intensity = r.n('intensity', 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: <Widget>[
          Expanded(child: Text('${r.type}  (${intensity.toStringAsFixed(1)})')),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              setState(() => _recipes.removeAt(i));
              _schedule();
            },
          ),
        ]),
        Slider(
          value: intensity.clamp(0, 40),
          max: 40,
          onChanged: (double v) {
            setState(() => r.p['intensity'] = v);
            _schedule();
          },
        ),
      ],
    );
  }

  Widget _buildPresetChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final AnimPreset preset in ExtensionRegistry.instance.animPresets)
          ActionChip(label: Text(preset.name), onPressed: () => _applyPreset(preset)),
      ],
    );
  }

  Widget _buildEffectChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final String type in AnimEngine.recipeTypes)
          if (type != 'none')
            InputChip(label: Text(type), onPressed: () => _addRecipe(type)),
      ],
    );
  }
}
