import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../imaging/sprite_edit.dart';
import '../app_state.dart';
import '../widgets/zoom_canvas.dart';

/// Crop / auto-trim / background-removal for the selected sprite (or all).
/// Live, debounced preview decoupled from widget rebuilds.
class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  double _l = 0, _t = 0, _r = 0, _b = 0;
  bool _autoTrim = false;
  bool _removeBg = false;
  double _tol = 40;

  final ValueNotifier<Uint8List?> _preview = ValueNotifier<Uint8List?>(null);
  Timer? _debounce;

  SpriteEditSpec get _spec => SpriteEditSpec(
        cropLeft: _l,
        cropTop: _t,
        cropRight: _r,
        cropBottom: _b,
        autoTrim: _autoTrim,
        removeBgCorners: _removeBg,
        bgTolerance: _tol,
      );

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

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _compute);
  }

  Future<void> _compute() async {
    final AppState app = context.read<AppState>();
    final String? rel = app.current == null ? null : app.spriteRelFor(app.current!);
    if (rel == null) {
      _preview.value = null;
      return;
    }
    final Uint8List? bytes = await app.previewEdit(rel, _spec);
    if (mounted) _preview.value = bytes;
  }

  void _reset() {
    setState(() {
      _l = _t = _r = _b = 0;
      _autoTrim = false;
      _removeBg = false;
    });
    _schedule();
  }

  Future<void> _apply({required bool allSprites}) async {
    final AppState app = context.read<AppState>();
    await app.applyEdit(_spec, allSprites: allSprites);
    _reset(); // baked in; show the result
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.read<AppState>();
    final bool hasSprite =
        app.current != null && app.spriteRelFor(app.current!) != null;

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
                    child: Text('Select an emote (Emotes tab) to edit its sprite.')),
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
          Text('Edit sprite', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          TextButton(onPressed: _reset, child: const Text('Reset')),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-trim transparent margins'),
          value: _autoTrim,
          onChanged: (bool v) {
            setState(() => _autoTrim = v);
            _schedule();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remove background'),
          subtitle: const Text('flood-fill from the corners'),
          value: _removeBg,
          onChanged: (bool v) {
            setState(() => _removeBg = v);
            _schedule();
          },
        ),
        if (_removeBg)
          _slider('BG tolerance', _tol, 0, 120, (double v) => _tol = v, label: _tol.round().toString()),
        const Divider(height: 24),
        Text('Crop', style: Theme.of(context).textTheme.labelLarge),
        _slider('Left', _l, 0, 0.45, (double v) => _l = v),
        _slider('Top', _t, 0, 0.45, (double v) => _t = v),
        _slider('Right', _r, 0, 0.45, (double v) => _r = v),
        _slider('Bottom', _b, 0, 0.45, (double v) => _b = v),
        const SizedBox(height: 12),
        Row(children: <Widget>[
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _apply(allSprites: false),
              icon: const Icon(Icons.crop_rounded),
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
        const SizedBox(height: 6),
        const Text(
          'Crop/auto-trim apply the same box to every frame and to (a)/(b)/(c) '
          'of an emote, so animations and idle/talk stay aligned.',
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _slider(String name, double v, double min, double max,
      void Function(double) assign, {String? label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$name: ${label ?? '${(v * 100).round()}%'}'),
        Slider(
          value: v.clamp(min, max),
          min: min,
          max: max,
          onChanged: (double nv) {
            setState(() => assign(nv));
            _schedule();
          },
        ),
      ],
    );
  }
}
