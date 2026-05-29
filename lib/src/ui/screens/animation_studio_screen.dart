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

  List<Uint8List> _previewFrames = <Uint8List>[];
  int _frameIdx = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _rebuild(AppState app) async {
    final List<Uint8List> frames =
        await app.renderAnimationPreview(_recipes, frames: _frames, fps: _fps);
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _previewFrames = frames;
      _frameIdx = 0;
    });
    if (frames.length > 1) {
      _timer = Timer.periodic(
        Duration(milliseconds: (1000 / _fps).round()),
        (_) => setState(
            () => _frameIdx = (_frameIdx + 1) % _previewFrames.length),
      );
    }
  }

  void _applyPreset(AnimPreset preset, AppState app) {
    setState(() {
      _recipes
        ..clear()
        ..addAll(preset.recipes);
      _frames = preset.frames;
      _fps = preset.fps;
    });
    _rebuild(app);
  }

  void _addRecipe(String type, AppState app) {
    setState(() => _recipes.add(AnimRecipe(type,
        p: <String, double>{'intensity': 6, 'cycles': 1}, ease: _ease)));
    _rebuild(app);
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final Uint8List? frame =
        _previewFrames.isEmpty ? null : _previewFrames[_frameIdx % _previewFrames.length];

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
                          child: CheckerImage(bytes: frame),
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
            _rebuild(app);
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
            _rebuild(app);
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
                _rebuild(app);
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
              label: const Text('Save (b) talk (WebP)'),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Save as (a) idle (WebP, falls back to APNG)',
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
              _rebuild(app);
            },
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ]),
        const Divider(height: 24),
        Text('Presets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final AnimPreset preset in ExtensionRegistry.instance.animPresets)
              ActionChip(
                label: Text(preset.name),
                onPressed: () => _applyPreset(preset, app),
              ),
          ],
        ),
        const Divider(height: 24),
        Text('Add an effect', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final String type in AnimEngine.recipeTypes)
              if (type != 'none')
                InputChip(
                  label: Text(type),
                  onPressed: () => _addRecipe(type, app),
                ),
          ],
        ),
        if (_recipes.isNotEmpty) ...<Widget>[
          const Divider(height: 24),
          Text('Effect strength', style: Theme.of(context).textTheme.titleMedium),
          for (int i = 0; i < _recipes.length; i++) _recipeTuner(i, app),
        ],
      ],
    );
  }

  Widget _recipeTuner(int i, AppState app) {
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
              _rebuild(app);
            },
          ),
        ]),
        Slider(
          value: intensity.clamp(0, 40),
          max: 40,
          onChanged: (double v) {
            setState(() => r.p['intensity'] = v);
            _rebuild(app);
          },
        ),
      ],
    );
  }
}
