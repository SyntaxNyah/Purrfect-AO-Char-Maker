import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ao_constants.dart';
import '../../core/emote.dart';
import '../../imaging/color_ops.dart';
import '../app_state.dart';
import '../widgets/zoom_canvas.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    return Row(
      children: <Widget>[
        SizedBox(width: 280, child: _EmoteList(app: app)),
        const VerticalDivider(width: 1),
        Expanded(child: _EmoteDetail(app: app)),
      ],
    );
  }
}

class _EmoteList extends StatelessWidget {
  const _EmoteList({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final List<Emote> emotes = app.character?.emotes ?? <Emote>[];
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              const Text('Emotes'),
              const Spacer(),
              IconButton(
                tooltip: 'Undo',
                onPressed: app.history.canUndo ? app.undo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              IconButton(
                tooltip: 'Redo',
                onPressed: app.history.canRedo ? app.redo : null,
                icon: const Icon(Icons.redo_rounded),
              ),
              IconButton(
                tooltip: 'Add emote',
                onPressed: app.addEmote,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: emotes.length,
            onReorder: (int from, int to) =>
                app.moveEmote(from, to > from ? to - 1 : to),
            itemBuilder: (BuildContext context, int i) {
              final Emote e = emotes[i];
              return ListTile(
                key: ValueKey<int>(i),
                selected: i == app.selectedEmote,
                dense: true,
                leading: CircleAvatar(radius: 12, child: Text('${i + 1}')),
                title: Text(e.comment, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(e.sprite, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => app.deleteEmote(i),
                ),
                onTap: () => app.selectEmote(i),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmoteDetail extends StatelessWidget {
  const _EmoteDetail({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final Emote? e = app.current;
    if (e == null) {
      return const Center(child: Text('Select an emote to edit it.'));
    }
    final String? rel = app.spriteRelFor(e);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: rel == null
                ? const Center(child: Text('No sprite file found for this emote.'))
                : FutureBuilder<Uint8List?>(
                    future: app.previewWithPipeline(rel, const <ColorOp>[], maxEdge: 1024),
                    builder: (BuildContext context, AsyncSnapshot<Uint8List?> snap) =>
                        ZoomCanvas(bytes: snap.data),
                  ),
          ),
          const SizedBox(height: 8),
          _Fields(key: ValueKey<int>(app.selectedEmote), app: app, emote: e),
        ],
      ),
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({super.key, required this.app, required this.emote});
  final AppState app;
  final Emote emote;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        _text('Name', emote.comment, (String v) => emote.comment = v, app, width: 200),
        _text('Sprite', emote.sprite, (String v) => emote.sprite = v, app, width: 220),
        _text('Preanim', emote.preanim, (String v) => emote.preanim = v, app, width: 160),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<EmoteModifier>(
            decoration: const InputDecoration(labelText: 'Modifier'),
            value: emote.modifier,
            items: <DropdownMenuItem<EmoteModifier>>[
              for (final EmoteModifier m in EmoteModifier.values)
                DropdownMenuItem<EmoteModifier>(value: m, child: Text(m.label)),
            ],
            onChanged: (EmoteModifier? m) {
              if (m != null) emote.modifier = m;
              app.commitEdit();
            },
          ),
        ),
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<DeskModifier>(
            decoration: const InputDecoration(labelText: 'Desk'),
            value: emote.deskMod ?? DeskModifier.show,
            items: <DropdownMenuItem<DeskModifier>>[
              for (final DeskModifier d in DeskModifier.values)
                DropdownMenuItem<DeskModifier>(value: d, child: Text(d.label)),
            ],
            onChanged: (DeskModifier? d) {
              emote.deskMod = d;
              app.commitEdit();
            },
          ),
        ),
        _text('Sound (SoundN)', emote.soundName ?? '',
            (String v) => emote.soundName = v.isEmpty ? null : v, app, width: 200),
        _text('Delay ticks', '${emote.soundDelayTicks ?? 0}',
            (String v) => emote.soundDelayTicks = int.tryParse(v), app, width: 110),
        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Checkbox(
            value: emote.soundLoop ?? false,
            onChanged: (bool? v) {
              emote.soundLoop = v;
              app.commitEdit();
            },
          ),
          const Text('Loop sound'),
        ]),
      ],
    );
  }

  Widget _text(String label, String value, ValueChanged<String> onChanged,
          AppState app, {double width = 180}) =>
      SizedBox(
        width: width,
        child: TextFormField(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          onChanged: (String v) {
            onChanged(v);
            app.touch();
          },
          onEditingComplete: app.commitEdit,
          onFieldSubmitted: (_) => app.commitEdit(),
        ),
      );
}
