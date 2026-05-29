import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../discovery/bulk_rename.dart';
import '../../imaging/bulk_processor.dart';
import '../../imaging/webp_codec.dart';
import '../app_state.dart';

class BulkScreen extends StatefulWidget {
  const BulkScreen({super.key});

  @override
  State<BulkScreen> createState() => _BulkScreenState();
}

class _BulkScreenState extends State<BulkScreen> {
  OutputFormat _format = OutputFormat.webp; // WebP is the default/best format
  bool _lossless = true; // lossless by default = no quality loss
  int _quality = 95;
  bool _deleteOriginal = false;

  // Bulk rename state.
  final TextEditingController _find = TextEditingController();
  final TextEditingController _replace = TextEditingController();
  final TextEditingController _prefix = TextEditingController();
  final TextEditingController _suffix = TextEditingController();
  final TextEditingController _template = TextEditingController(text: 'Emote {n}');
  bool _sequential = false;
  bool _renameSprites = false;
  RenameCase _case = RenameCase.keep;

  @override
  void dispose() {
    _find.dispose();
    _replace.dispose();
    _prefix.dispose();
    _suffix.dispose();
    _template.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final WebpEncoder enc = WebpEncoder.instance;
    final bool wantsWebp = _format == OutputFormat.webp;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Bulk operations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Recolour, convert, or rename every sprite/emote at once. Animation '
          'frames are preserved for PNG/APNG/GIF (and animated WebP).',
        ),
        const SizedBox(height: 16),

        _card(context, 'Recolour', <Widget>[
          Text('Live pipeline has ${app.livePipeline.length} op(s). '
              'Build it in the Colour Lab, then bake it here.'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: app.livePipeline.isEmpty
                ? null
                : () => app.applyPipeline(allSprites: true),
            icon: const Icon(Icons.format_color_fill_rounded),
            label: const Text('Recolour ALL sprites'),
          ),
        ]),

        _card(context, 'Bulk rename emotes', <Widget>[
          Row(children: <Widget>[
            Expanded(child: _text(_find, 'Find')),
            const SizedBox(width: 8),
            Expanded(child: _text(_replace, 'Replace with')),
          ]),
          const SizedBox(height: 8),
          Row(children: <Widget>[
            Expanded(child: _text(_prefix, 'Prefix')),
            const SizedBox(width: 8),
            Expanded(child: _text(_suffix, 'Suffix')),
          ]),
          const SizedBox(height: 4),
          Row(children: <Widget>[
            Checkbox(
              value: _sequential,
              onChanged: (bool? v) => setState(() => _sequential = v ?? false),
            ),
            const Text('Number'),
            const SizedBox(width: 8),
            if (_sequential)
              Expanded(child: _text(_template, 'Template ({n}, {name})')),
          ]),
          Row(children: <Widget>[
            const Text('Case:'),
            const SizedBox(width: 8),
            DropdownButton<RenameCase>(
              value: _case,
              items: const <DropdownMenuItem<RenameCase>>[
                DropdownMenuItem<RenameCase>(value: RenameCase.keep, child: Text('Keep')),
                DropdownMenuItem<RenameCase>(value: RenameCase.title, child: Text('Title Case')),
                DropdownMenuItem<RenameCase>(value: RenameCase.lower, child: Text('lower')),
                DropdownMenuItem<RenameCase>(value: RenameCase.upper, child: Text('UPPER')),
              ],
              onChanged: (RenameCase? c) => setState(() => _case = c ?? RenameCase.keep),
            ),
          ]),
          Row(children: <Widget>[
            Checkbox(
              value: _renameSprites,
              onChanged: (bool? v) => setState(() => _renameSprites = v ?? false),
            ),
            const Expanded(
              child: Text('Also rename the sprite files (root sprites)'),
            ),
          ]),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => app.bulkRename(RenameSpec(
              find: _find.text,
              replace: _replace.text,
              prefix: _prefix.text,
              suffix: _suffix.text,
              sequential: _sequential,
              sequentialTemplate: _template.text.isEmpty ? 'Emote {n}' : _template.text,
              caseMode: _case,
              renameSprites: _renameSprites,
            )),
            icon: const Icon(Icons.drive_file_rename_outline),
            label: const Text('Apply rename to ALL emotes'),
          ),
          const SizedBox(height: 4),
          const Text(
            'e.g. Find "_" → Replace " ", add a Prefix, or number as "Emote {n}".',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ]),

        _card(context, 'Convert format', <Widget>[
          DropdownButton<OutputFormat>(
            value: _format,
            items: const <DropdownMenuItem<OutputFormat>>[
              DropdownMenuItem<OutputFormat>(
                  value: OutputFormat.webp, child: Text('WebP (best)')),
              DropdownMenuItem<OutputFormat>(
                  value: OutputFormat.keep, child: Text('Keep original')),
              DropdownMenuItem<OutputFormat>(
                  value: OutputFormat.png, child: Text('PNG / APNG')),
              DropdownMenuItem<OutputFormat>(
                  value: OutputFormat.apng, child: Text('APNG')),
              DropdownMenuItem<OutputFormat>(
                  value: OutputFormat.gif, child: Text('GIF')),
            ],
            onChanged: (OutputFormat? f) =>
                setState(() => _format = f ?? OutputFormat.webp),
          ),
          if (wantsWebp) ...<Widget>[
            const SizedBox(height: 8),
            Row(children: <Widget>[
              Switch(
                value: _lossless,
                onChanged: (bool v) => setState(() => _lossless = v),
              ),
              const Text('Lossless'),
            ]),
            if (!_lossless) ...<Widget>[
              Text('Quality: $_quality'),
              Slider(
                value: _quality.toDouble(),
                min: 1,
                max: 100,
                onChanged: (double v) => setState(() => _quality = v.round()),
              ),
            ],
            Text(
              enc.supportsLossy
                  ? 'WebP encoder: available ✓'
                  : 'WebP encoder not found here — release downloads ship with it; '
                      'the web build always has it.',
              style: TextStyle(
                fontSize: 12,
                color: enc.supportsLossy ? Colors.green : Colors.orange,
              ),
            ),
          ],
          Row(children: <Widget>[
            Checkbox(
              value: _deleteOriginal,
              onChanged: (bool? v) => setState(() => _deleteOriginal = v ?? false),
            ),
            const Expanded(
              child: Text('Delete originals after converting '
                  '(avoids AO picking the old file by extension priority)'),
            ),
          ]),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => app.bulkConvert(
              _format,
              webpLossless: _lossless,
              webpQuality: _quality,
              deleteOriginal: _deleteOriginal,
            ),
            icon: const Icon(Icons.transform_rounded),
            label: const Text('Convert ALL sprites'),
          ),
        ]),
      ],
    );
  }

  Widget _card(BuildContext context, String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );

  Widget _text(TextEditingController c, String label) => TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
      );
}
