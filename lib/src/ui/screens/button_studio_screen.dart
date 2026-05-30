import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ao_constants.dart';
import '../../core/emote.dart';
import '../app_state.dart';
import '../widgets/checker_image.dart';

/// Button & char-icon studio.
///
/// Buttons (and the char_icon) are auto-generated on export. This screen lets you
/// choose **how** they're framed — **Head / face** by default (AO buttons show
/// expressions, not whole bodies) or **Full body** — plus the size, head-crop
/// zoom, and (for the icon) which emote it comes from.
///
/// Performance: the screen mutates the [AppState] settings directly (no global
/// rebuilds) and renders each preview through a **debounced** [ValueNotifier], so
/// dragging a slider never re-bakes on every frame or lags other screens.
class ButtonStudioScreen extends StatefulWidget {
  const ButtonStudioScreen({super.key});

  @override
  State<ButtonStudioScreen> createState() => _ButtonStudioScreenState();
}

class _ButtonStudioScreenState extends State<ButtonStudioScreen> {
  final ValueNotifier<Uint8List?> _btnPreview = ValueNotifier<Uint8List?>(null);
  final ValueNotifier<Uint8List?> _iconPreview = ValueNotifier<Uint8List?>(null);
  Timer? _btnDebounce;
  Timer? _iconDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _computeBtn();
      _computeIcon();
    });
  }

  @override
  void dispose() {
    _btnDebounce?.cancel();
    _iconDebounce?.cancel();
    _btnPreview.dispose();
    _iconPreview.dispose();
    super.dispose();
  }

  void _scheduleBtn() {
    _btnDebounce?.cancel();
    _btnDebounce = Timer(const Duration(milliseconds: 90), _computeBtn);
  }

  void _scheduleIcon() {
    _iconDebounce?.cancel();
    _iconDebounce = Timer(const Duration(milliseconds: 90), _computeIcon);
  }

  Future<void> _computeBtn() async {
    final AppState app = context.read<AppState>();
    final Uint8List? b = await app.previewAutoButton(app.buttonSize);
    if (mounted) _btnPreview.value = b;
  }

  Future<void> _computeIcon() async {
    final AppState app = context.read<AppState>();
    final Uint8List? b = await app.previewCharIcon();
    if (mounted) _iconPreview.value = b;
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.read<AppState>();
    final List<Emote> emotes = app.character?.emotes ?? const <Emote>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Button & Icon Studio',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Buttons and the char_icon are generated on export. Choose how they '
          'frame each sprite — Head / face (default) shows the expression, Full '
          'body squares the whole sprite.',
        ),
        const SizedBox(height: 16),

        _BtnCard(
          app: app,
          preview: _btnPreview,
          onChanged: _scheduleBtn,
        ),
        const SizedBox(height: 16),
        _IconCard(
          app: app,
          emotes: emotes,
          preview: _iconPreview,
          onChanged: _scheduleIcon,
        ),
        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: () => app.exportZip(),
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Export character (.zip) with buttons + char_icon'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tip: a buttonN_off.png or char_icon.png you import (or save here) is '
          'kept as-is on export — only the missing ones are generated.',
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}

/// Shared building blocks ------------------------------------------------------

Widget _framingPicker(CropFraming value, ValueChanged<CropFraming> onChanged) {
  return SegmentedButton<CropFraming>(
    segments: const <ButtonSegment<CropFraming>>[
      ButtonSegment<CropFraming>(
        value: CropFraming.head,
        icon: Icon(Icons.face_rounded),
        label: Text('Head / face'),
      ),
      ButtonSegment<CropFraming>(
        value: CropFraming.full,
        icon: Icon(Icons.accessibility_new_rounded),
        label: Text('Full body'),
      ),
    ],
    selected: <CropFraming>{value},
    onSelectionChanged: (Set<CropFraming> s) => onChanged(s.first),
    showSelectedIcon: false,
  );
}

Widget _previewBox(ValueNotifier<Uint8List?> preview, String caption) {
  return Column(
    children: <Widget>[
      Container(
        width: 168,
        height: 168,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ValueListenableBuilder<Uint8List?>(
          valueListenable: preview,
          builder: (_, Uint8List? b, __) => b == null
              ? const Center(child: Text('No sprite'))
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: CheckerImage(bytes: b),
                ),
        ),
      ),
      const SizedBox(height: 6),
      Text(caption),
    ],
  );
}

Widget _sizeSlider({
  required String label,
  required int value,
  required int min,
  required int max,
  required ValueChanged<int> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('$label: $value px'),
      Slider(
        value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: max - min,
        label: '$value',
        onChanged: (double v) => onChanged(v.round()),
      ),
    ],
  );
}

Widget _zoomSlider(double value, ValueChanged<double> onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('Face zoom: ${value.toStringAsFixed(2)}×  '
          '${value > 1 ? '(tighter)' : value < 1 ? '(looser)' : ''}'),
      Slider(
        value: value.clamp(0.5, 2.0),
        min: 0.5,
        max: 2.0,
        onChanged: onChanged,
      ),
    ],
  );
}

/// Nudge the crop (−50%..+50% of the crop square) to re-centre the framing.
Widget _offsetSlider(String label, double value, ValueChanged<double> onChanged) {
  final int pct = (value * 100).round();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('$label: ${pct >= 0 ? '+' : ''}$pct%'),
      Slider(
        value: value.clamp(-0.5, 0.5),
        min: -0.5,
        max: 0.5,
        onChanged: onChanged,
      ),
    ],
  );
}

/// Import / preview / clear one overlay slot (a border laid on top, or a
/// background behind the sprite). KFO-style frames go in the "Border (on top)"
/// slot. Self-contained so a pick only rebuilds this row.
class _OverlayControls extends StatefulWidget {
  const _OverlayControls({
    required this.label,
    required this.slot,
    required this.onChanged,
  });
  final String label;
  final OverlaySlot slot;
  final VoidCallback onChanged;

  @override
  State<_OverlayControls> createState() => _OverlayControlsState();
}

class _OverlayControlsState extends State<_OverlayControls> {
  Future<void> _pick() async {
    final FilePickerResult? res =
        await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
    if (res == null || res.files.isEmpty) return;
    final PlatformFile f = res.files.first;
    if (f.bytes == null) return;
    if (!mounted) return;
    context.read<AppState>().setOverlay(
          widget.slot,
          f.bytes!,
          ext: (f.extension ?? 'png').toLowerCase(),
        );
    setState(() {});
    widget.onChanged();
  }

  void _clear() {
    context.read<AppState>().setOverlay(widget.slot, null);
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final bool set = widget.slot.isSet;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          SizedBox(width: 110, child: Text(widget.label, style: const TextStyle(fontSize: 12))),
          if (set) ...<Widget>[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(4),
              ),
              child: widget.slot.bytes == null
                  ? null
                  : Image.memory(widget.slot.bytes!, fit: BoxFit.contain),
            ),
          ],
          TextButton(
            onPressed: _pick,
            child: Text(set ? 'Replace' : 'Import…'),
          ),
          if (set)
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 16),
              onPressed: _clear,
            ),
        ],
      ),
    );
  }
}

/// Buttons card ---------------------------------------------------------------

class _BtnCard extends StatefulWidget {
  const _BtnCard({required this.app, required this.preview, required this.onChanged});
  final AppState app;
  final ValueNotifier<Uint8List?> preview;
  final VoidCallback onChanged;

  @override
  State<_BtnCard> createState() => _BtnCardState();
}

class _BtnCardState extends State<_BtnCard> {
  @override
  Widget build(BuildContext context) {
    final AppState app = widget.app;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Emote buttons',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Switch(
                  value: app.generateButtons,
                  onChanged: (bool v) => setState(() => app.generateButtons = v),
                ),
                const Text('Generate'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _previewBox(widget.preview, '${app.buttonSize}×${app.buttonSize} px'),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Framing'),
                      const SizedBox(height: 6),
                      _framingPicker(app.buttonFraming, (CropFraming f) {
                        setState(() => app.buttonFraming = f);
                        widget.onChanged();
                      }),
                      const SizedBox(height: 12),
                      _sizeSlider(
                        label: 'Button size (default 128)',
                        value: app.buttonSize,
                        min: CharFolder.minButtonSize,
                        max: CharFolder.maxButtonSize,
                        onChanged: (int v) {
                          setState(() => app.buttonSize = v);
                          widget.onChanged();
                        },
                      ),
                      if (app.buttonFraming == CropFraming.head)
                        _zoomSlider(app.buttonZoom, (double v) {
                          setState(() => app.buttonZoom = v);
                          widget.onChanged();
                        }),
                      _offsetSlider('Move X', app.buttonOffsetX, (double v) {
                        setState(() => app.buttonOffsetX = v);
                        widget.onChanged();
                      }),
                      _offsetSlider('Move Y', app.buttonOffsetY, (double v) {
                        setState(() => app.buttonOffsetY = v);
                        widget.onChanged();
                      }),
                      const SizedBox(height: 8),
                      const Text('Overlays (KFO-style borders)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      _OverlayControls(
                        label: 'Border (on top)',
                        slot: app.buttonFg,
                        onChanged: widget.onChanged,
                      ),
                      _OverlayControls(
                        label: 'Background',
                        slot: app.buttonBg,
                        onChanged: widget.onChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Char-icon card -------------------------------------------------------------

class _IconCard extends StatefulWidget {
  const _IconCard({
    required this.app,
    required this.emotes,
    required this.preview,
    required this.onChanged,
  });
  final AppState app;
  final List<Emote> emotes;
  final ValueNotifier<Uint8List?> preview;
  final VoidCallback onChanged;

  @override
  State<_IconCard> createState() => _IconCardState();
}

class _IconCardState extends State<_IconCard> {
  @override
  Widget build(BuildContext context) {
    final AppState app = widget.app;
    final int maxIndex = widget.emotes.isEmpty ? 0 : widget.emotes.length - 1;
    final int srcIndex = app.iconSourceEmote.clamp(0, maxIndex);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Character icon (char_icon.png)',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Switch(
                  value: app.generateCharIcon,
                  onChanged: (bool v) => setState(() => app.generateCharIcon = v),
                ),
                const Text('Generate'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _previewBox(widget.preview, '${app.iconSize}×${app.iconSize} px'),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Framing'),
                      const SizedBox(height: 6),
                      _framingPicker(app.iconFraming, (CropFraming f) {
                        setState(() => app.iconFraming = f);
                        widget.onChanged();
                      }),
                      const SizedBox(height: 12),
                      _sizeSlider(
                        label: 'Icon size (default 40 · AO range 40–128)',
                        value: app.iconSize,
                        min: CharFolder.minIconSize,
                        max: CharFolder.maxIconSize,
                        onChanged: (int v) {
                          setState(() => app.iconSize = v);
                          widget.onChanged();
                        },
                      ),
                      if (app.iconFraming == CropFraming.head)
                        _zoomSlider(app.iconZoom, (double v) {
                          setState(() => app.iconZoom = v);
                          widget.onChanged();
                        }),
                      _offsetSlider('Move X', app.iconOffsetX, (double v) {
                        setState(() => app.iconOffsetX = v);
                        widget.onChanged();
                      }),
                      _offsetSlider('Move Y', app.iconOffsetY, (double v) {
                        setState(() => app.iconOffsetY = v);
                        widget.onChanged();
                      }),
                      const SizedBox(height: 8),
                      const Text('Overlays (KFO-style borders)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      _OverlayControls(
                        label: 'Border (on top)',
                        slot: app.iconFg,
                        onChanged: widget.onChanged,
                      ),
                      _OverlayControls(
                        label: 'Background',
                        slot: app.iconBg,
                        onChanged: widget.onChanged,
                      ),
                      const SizedBox(height: 12),
                      if (widget.emotes.isNotEmpty) ...<Widget>[
                        const Text('Made from emote'),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: srcIndex,
                          decoration: const InputDecoration(isDense: true),
                          items: <DropdownMenuItem<int>>[
                            for (int i = 0; i < widget.emotes.length; i++)
                              DropdownMenuItem<int>(
                                value: i,
                                child: Text(
                                  '${i + 1}. ${widget.emotes[i].comment}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (int? v) {
                            if (v == null) return;
                            setState(() => app.iconSourceEmote = v);
                            widget.onChanged();
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await app.saveCharIcon();
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save char_icon.png now'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
