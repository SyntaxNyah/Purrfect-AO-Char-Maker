import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../imaging/codecs.dart';
import '../../imaging/overlay_presets.dart';
import 'checker_image.dart';

/// Opens the in-app **overlay builder** — design a custom border/background by
/// choosing a style, colours (via a colour wheel), thickness, corner radius,
/// etc., with a live preview. [initial] pre-fills it (the slot's current spec,
/// so you can *edit* an applied overlay); [onApply] receives the finished spec.
Future<void> showOverlayBuilder(
  BuildContext context, {
  required OverlayKind kind,
  OverlaySpec? initial,
  required ValueChanged<OverlaySpec> onApply,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        _OverlayBuilderDialog(kind: kind, initial: initial, onApply: onApply),
  );
}

class _OverlayBuilderDialog extends StatefulWidget {
  const _OverlayBuilderDialog(
      {required this.kind, required this.initial, required this.onApply});
  final OverlayKind kind;
  final OverlaySpec? initial;
  final ValueChanged<OverlaySpec> onApply;

  @override
  State<_OverlayBuilderDialog> createState() => _OverlayBuilderDialogState();
}

class _OverlayBuilderDialogState extends State<_OverlayBuilderDialog> {
  late OverlaySpec _spec;

  @override
  void initState() {
    super.initState();
    final OverlaySpec? init = widget.initial;
    _spec = (init != null && init.kind == widget.kind)
        ? init.copy()
        : OverlayPresets.defaultSpec(widget.kind);
  }

  Future<void> _pickColor(int current, ValueChanged<int> assign) async {
    Color picked = Color(0xFF000000 | (current & 0xFFFFFF));
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Pick a colour'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: picked,
            enableAlpha: false,
            paletteType: PaletteType.hueWheel,
            hexInputBar: true,
            labelTypes: const <ColorLabelType>[
              ColorLabelType.hex,
              ColorLabelType.rgb,
            ],
            onColorChanged: (Color c) => picked = c,
          ),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done')),
        ],
      ),
    );
    if (mounted) setState(() => assign(picked.value & 0xFFFFFF));
  }

  @override
  Widget build(BuildContext context) {
    final OverlayStyle st = _spec.style;
    final Uint8List preview = Codecs.encodePng(_spec.build(150));
    return AlertDialog(
      title: Text(widget.kind == OverlayKind.border
          ? 'Build a border'
          : 'Build a background'),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CheckerImage(bytes: preview),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _styleDropdown(),
              const SizedBox(height: 8),
              _startFromDropdown(),
              const Divider(),
              if (st.usesColor1)
                _colorRow('Main colour', _spec.color1, (int v) => _spec.color1 = v),
              if (st.usesColor2)
                _colorRow('Second colour', _spec.color2, (int v) => _spec.color2 = v),
              if (st.usesPattern)
                _colorRow('Pattern colour', _spec.patternColor,
                    (int v) => _spec.patternColor = v),
              if (st == OverlayStyle.rainbow || st == OverlayStyle.rainbowFrame)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Colours are automatic for rainbow styles.',
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                ),
              if (st.usesThickness)
                _slider('Thickness', _spec.thickness, .01, .25,
                    (double v) => _spec.thickness = v),
              if (st.usesRadius)
                _slider('Corner radius', _spec.radius, 0, .5,
                    (double v) => _spec.radius = v),
              if (st.usesInset)
                _slider('Inset', _spec.inset, 0, .2, (double v) => _spec.inset = v),
              if (st.usesCell)
                _slider('Pattern size', _spec.cell, .12, .5,
                    (double v) => _spec.cell = v),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onApply(_spec);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _styleDropdown() => InputDecorator(
        decoration: const InputDecoration(labelText: 'Style', isDense: true),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<OverlayStyle>(
            isExpanded: true,
            value: _spec.style,
            items: <DropdownMenuItem<OverlayStyle>>[
              for (final OverlayStyle s in stylesForKind(widget.kind))
                DropdownMenuItem<OverlayStyle>(value: s, child: Text(s.label)),
            ],
            onChanged: (OverlayStyle? s) {
              if (s != null) setState(() => _spec.style = s);
            },
          ),
        ),
      );

  Widget _startFromDropdown() => InputDecorator(
        decoration:
            const InputDecoration(labelText: 'Start from a preset', isDense: true),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<OverlayPreset?>(
            isExpanded: true,
            value: null,
            hint: const Text('—'),
            items: <DropdownMenuItem<OverlayPreset?>>[
              const DropdownMenuItem<OverlayPreset?>(value: null, child: Text('—')),
              for (final OverlayPreset p in OverlayPresets.forKind(widget.kind))
                DropdownMenuItem<OverlayPreset?>(
                    value: p,
                    child: Text('${p.category} · ${p.name}',
                        overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (OverlayPreset? p) {
              if (p != null) setState(() => _spec = p.spec.copy());
            },
          ),
        ),
      );

  Widget _colorRow(String label, int color, ValueChanged<int> assign) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            SizedBox(
                width: 120,
                child: Text(label, style: const TextStyle(fontSize: 13))),
            GestureDetector(
              onTap: () => _pickColor(color, assign),
              child: Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  color: Color(0xFF000000 | (color & 0xFFFFFF)),
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
                onPressed: () => _pickColor(color, assign),
                child: const Text('Wheel')),
          ],
        ),
      );

  Widget _slider(String label, double v, double min, double max,
          ValueChanged<double> assign) =>
      Row(
        children: <Widget>[
          SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Slider(
              value: v.clamp(min, max),
              min: min,
              max: max,
              onChanged: (double nv) => setState(() => assign(nv)),
            ),
          ),
        ],
      );
}
