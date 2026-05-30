import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ao_constants.dart';
import '../../core/character.dart';
import '../app_state.dart';

/// Dedicated **char.ini builder** — edits the whole `[Options]` block (name,
/// showname, blips, chat, side, category, scaling, …) that the auto-builder only
/// sets defaults for. Everything here is written verbatim into the exported
/// `char.ini`; unknown keys you imported are preserved untouched.
///
/// Performance: like the Emotes editor, fields write to the model live and
/// commit (undo snapshot) on blur/submit — no per-keystroke rebuilds.
class IniBuilderScreen extends StatelessWidget {
  const IniBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (BuildContext context, AppState app, _) {
        final Character? c = app.character;
        if (c == null) {
          return const Center(child: Text('Import sprites first.'));
        }
        return _OptionsForm(
          // Fresh controllers whenever the character object is replaced
          // (import / regenerate / undo).
          key: ValueKey<int>(identityHashCode(c)),
          app: app,
          options: c.options,
        );
      },
    );
  }
}

class _OptionsForm extends StatefulWidget {
  const _OptionsForm({super.key, required this.app, required this.options});
  final AppState app;
  final CharacterOptions options;

  @override
  State<_OptionsForm> createState() => _OptionsFormState();
}

class _OptionsFormState extends State<_OptionsForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.options.name);
  late final TextEditingController _showname =
      TextEditingController(text: widget.options.showname ?? '');
  late final TextEditingController _blips =
      TextEditingController(text: widget.options.blips ?? '');
  late final TextEditingController _chat =
      TextEditingController(text: widget.options.chat ?? '');
  late final TextEditingController _category =
      TextEditingController(text: widget.options.category ?? '');
  late final TextEditingController _effects =
      TextEditingController(text: widget.options.effects ?? '');
  late final TextEditingController _realization =
      TextEditingController(text: widget.options.realization ?? '');

  bool _dirty = false;

  @override
  void dispose() {
    _name.dispose();
    _showname.dispose();
    _blips.dispose();
    _chat.dispose();
    _category.dispose();
    _effects.dispose();
    _realization.dispose();
    super.dispose();
  }

  String? _nullable(String v) => v.trim().isEmpty ? null : v.trim();

  void _commit() {
    if (!_dirty) return;
    _dirty = false;
    widget.app.commitEdit();
  }

  void _commitNow() {
    _dirty = true;
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    final CharacterOptions o = widget.options;
    return Focus(
      onFocusChange: (bool has) {
        if (!has) _commit();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Character / char.ini',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => widget.app.exportIni(),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Export char.ini'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'These become the [Options] block of your char.ini. The auto-builder '
            'fills sensible defaults; fine-tune them here. Anything not shown '
            '(custom keys you imported) is preserved as-is.',
          ),
          const SizedBox(height: 16),

          _section(context, 'Identity'),
          _field('Name', _name, (String v) => o.name = v.trim(),
              hint: 'The folder name and in-game character name.'),
          _field('Showname', _showname, (String v) => o.showname = _nullable(v),
              hint: 'The name shown in the chatbox. Blank = use Name.'),
          _triState(
            'Require a custom showname (needs_showname)',
            o.needsShowname,
            (bool? v) {
              o.needsShowname = v;
              _commitNow();
            },
          ),
          _field('Category', _category, (String v) => o.category = _nullable(v),
              hint: 'Groups the character in the picker (optional).'),

          const SizedBox(height: 12),
          _section(context, 'Courtroom'),
          _sideDropdown(o),

          const SizedBox(height: 12),
          _section(context, 'Sound & text'),
          _field('Blips', _blips, (String v) => o.blips = _nullable(v),
              hint: 'The typing-sound set (e.g. male, female, typewriter). '
                  'Modern AO replaces the old "gender" key with this.'),
          _field('Chat', _chat, (String v) => o.chat = _nullable(v),
              hint: 'Chatbox / font style name (e.g. default, custom).'),

          const SizedBox(height: 12),
          _section(context, 'Rendering'),
          _scalingDropdown(o),
          _triState('Stretch sprites to fill (stretch)', o.stretch, (bool? v) {
            o.stretch = v;
            _commitNow();
          }),

          const SizedBox(height: 12),
          _section(context, 'Advanced (optional)'),
          _field('Effects', _effects, (String v) => o.effects = _nullable(v),
              hint: 'Name of a custom effects pack (rarely needed).'),
          _field('Realization', _realization,
              (String v) => o.realization = _nullable(v),
              hint: 'Realization flash/sound override (rarely needed).'),

          if (o.extra.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${o.extra.length} extra [Options] key(s) from your imported '
                'char.ini are preserved on export: '
                '${o.extra.map((e) => e.key).join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---- widgets ----

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _field(String label, TextEditingController controller,
      ValueChanged<String> apply,
      {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          helperMaxLines: 2,
        ),
        onChanged: (String v) {
          apply(v);
          _dirty = true;
        },
        onSubmitted: (_) => _commit(),
      ),
    );
  }

  Widget _sideDropdown(CharacterOptions o) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<CourtSide>(
        value: o.sideEnum,
        decoration: const InputDecoration(
          labelText: 'Side (courtroom position)',
          helperText: 'Where the character stands by default.',
        ),
        items: <DropdownMenuItem<CourtSide>>[
          for (final CourtSide s in CourtSide.values)
            DropdownMenuItem<CourtSide>(
                value: s, child: Text('${s.label}  (${s.id})')),
        ],
        onChanged: (CourtSide? s) {
          if (s != null) o.sideEnum = s;
          _commitNow();
        },
      ),
    );
  }

  Widget _scalingDropdown(CharacterOptions o) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String?>(
        value: o.scalingEnum?.id,
        decoration: const InputDecoration(
          labelText: 'Scaling',
          helperText: 'How sprites are resized. Default leaves it unset.',
        ),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(value: null, child: Text('Default (unset)')),
          for (final ScalingMode m in ScalingMode.values)
            DropdownMenuItem<String?>(value: m.id, child: Text(m.label)),
        ],
        onChanged: (String? id) {
          o.scaling = id;
          _commitNow();
        },
      ),
    );
  }

  /// A nullable yes/no/unset selector for fields like needs_showname / stretch.
  Widget _triState(String label, bool? value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 0, label: Text('Unset')),
              ButtonSegment<int>(value: 1, label: Text('Yes')),
              ButtonSegment<int>(value: 2, label: Text('No')),
            ],
            selected: <int>{value == null ? 0 : (value ? 1 : 2)},
            onSelectionChanged: (Set<int> s) {
              final int v = s.first;
              onChanged(v == 0 ? null : v == 1);
            },
          ),
        ],
      ),
    );
  }
}
