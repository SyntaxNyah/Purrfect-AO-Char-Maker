import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ao_constants.dart';
import '../../core/emote.dart';
import '../app_state.dart';
import '../widgets/zoom_canvas.dart';

/// Emotes screen.
///
/// Performance: typing in a field updates the emote **model + its own
/// controller only** — it does NOT call `notifyListeners` per keystroke, so the
/// big sprite preview (a 1024px decode/encode) no longer re-bakes on every
/// character you type. The edit is committed (undo snapshot + list refresh) when
/// the field loses focus or you submit it. The preview is a cached, stateful
/// widget keyed on the sprite path + [AppState.spriteRevision], so it only
/// reloads when the actual sprite changes.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        SizedBox(width: 280, child: _EmoteList()),
        VerticalDivider(width: 1),
        Expanded(child: _DetailPane()),
      ],
    );
  }
}

class _EmoteList extends StatelessWidget {
  const _EmoteList();

  @override
  Widget build(BuildContext context) {
    // The list is cheap, so a Consumer (rebuild on commit/selection) is fine.
    return Consumer<AppState>(
      builder: (BuildContext context, AppState app, _) {
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
                    onPressed: app.canUndo ? app.undo : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    onPressed: app.canRedo ? app.redo : null,
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
                    title: Text(e.comment,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(e.sprite,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
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
      },
    );
  }
}

class _DetailPane extends StatelessWidget {
  const _DetailPane();

  @override
  Widget build(BuildContext context) {
    // Rebuild only when the selection or the sprite pixels/paths change — NOT on
    // every keystroke (typing doesn't notify) and NOT on dropdown commits.
    return Selector<AppState, (int, int)>(
      selector: (_, AppState a) => (a.selectedEmote, a.spriteRevision),
      builder: (BuildContext context, (int, int) _, __) {
        final AppState app = context.read<AppState>();
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
                child: _SpritePreview(rel: rel, revision: app.spriteRevision),
              ),
              const SizedBox(height: 8),
              _Fields(key: ValueKey<int>(app.selectedEmote), app: app, emote: e),
            ],
          ),
        );
      },
    );
  }
}

/// Caches the decoded/encoded sprite preview; only reloads when [rel] or
/// [revision] changes. Decoupled from text editing entirely.
class _SpritePreview extends StatefulWidget {
  const _SpritePreview({required this.rel, required this.revision});
  final String? rel;
  final int revision;

  @override
  State<_SpritePreview> createState() => _SpritePreviewState();
}

class _SpritePreviewState extends State<_SpritePreview> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SpritePreview old) {
    super.didUpdateWidget(old);
    if (old.rel != widget.rel || old.revision != widget.revision) _load();
  }

  Future<void> _load() async {
    final String? rel = widget.rel;
    if (rel == null) {
      if (mounted) setState(() => _bytes = null);
      return;
    }
    _loading = true;
    final Uint8List? b = await context.read<AppState>().previewSprite(rel);
    _loading = false;
    if (mounted) setState(() => _bytes = b);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rel == null) {
      return const Center(child: Text('No sprite file found for this emote.'));
    }
    if (_bytes == null && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ZoomCanvas(bytes: _bytes);
  }
}

/// The editable fields. Owns its [TextEditingController]s so typing never goes
/// through [AppState.notifyListeners]; the change is written to the [emote]
/// model live (so nothing is lost) and *committed* (undo snapshot + list
/// refresh) when the field group loses focus or a field is submitted.
class _Fields extends StatefulWidget {
  const _Fields({super.key, required this.app, required this.emote});
  final AppState app;
  final Emote emote;

  @override
  State<_Fields> createState() => _FieldsState();
}

class _FieldsState extends State<_Fields> {
  late final TextEditingController _name =
      TextEditingController(text: widget.emote.comment);
  late final TextEditingController _sprite =
      TextEditingController(text: widget.emote.sprite);
  late final TextEditingController _preanim =
      TextEditingController(text: widget.emote.preanim);
  late final TextEditingController _sound =
      TextEditingController(text: widget.emote.soundName ?? '');
  late final TextEditingController _delay = TextEditingController(
      text: '${widget.emote.soundDelayTicks ?? 0}');

  bool _dirty = false;

  @override
  void dispose() {
    _name.dispose();
    _sprite.dispose();
    _preanim.dispose();
    _sound.dispose();
    _delay.dispose();
    super.dispose();
  }

  void _commit() {
    if (!_dirty) return;
    _dirty = false;
    widget.app.commitEdit();
  }

  @override
  Widget build(BuildContext context) {
    final Emote e = widget.emote;
    // Commit when focus leaves the whole field group (e.g. click the preview or
    // another emote), not when moving between fields inside it.
    return Focus(
      onFocusChange: (bool hasFocus) {
        if (!hasFocus) _commit();
      },
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: <Widget>[
          _text('Name', _name, (String v) => e.comment = v, width: 200),
          _text('Sprite', _sprite, (String v) => e.sprite = v, width: 220),
          _text('Preanim', _preanim, (String v) => e.preanim = v, width: 160),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<EmoteModifier>(
              decoration: const InputDecoration(labelText: 'Modifier'),
              value: e.modifier,
              items: <DropdownMenuItem<EmoteModifier>>[
                for (final EmoteModifier m in EmoteModifier.values)
                  DropdownMenuItem<EmoteModifier>(value: m, child: Text(m.label)),
              ],
              onChanged: (EmoteModifier? m) {
                if (m == null) return;
                setState(() => e.modifier = m);
                widget.app.commitEdit();
              },
            ),
          ),
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<DeskModifier>(
              decoration: const InputDecoration(labelText: 'Desk'),
              value: e.deskMod ?? DeskModifier.show,
              items: <DropdownMenuItem<DeskModifier>>[
                for (final DeskModifier d in DeskModifier.values)
                  DropdownMenuItem<DeskModifier>(value: d, child: Text(d.label)),
              ],
              onChanged: (DeskModifier? d) {
                setState(() => e.deskMod = d);
                widget.app.commitEdit();
              },
            ),
          ),
          _text('Sound (SoundN)', _sound,
              (String v) => e.soundName = v.isEmpty ? null : v, width: 200),
          _text('Delay ticks', _delay,
              (String v) => e.soundDelayTicks = int.tryParse(v), width: 110),
          Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Checkbox(
              value: e.soundLoop ?? false,
              onChanged: (bool? v) {
                setState(() => e.soundLoop = v);
                widget.app.commitEdit();
              },
            ),
            const Text('Loop sound'),
          ]),
        ],
      ),
    );
  }

  Widget _text(String label, TextEditingController controller,
          ValueChanged<String> apply, {double width = 180}) =>
      SizedBox(
        width: width,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          onChanged: (String v) {
            apply(v); // write to the model live; no notify → no rebuild/re-bake
            _dirty = true;
          },
          onSubmitted: (_) => _commit(),
        ),
      );
}
