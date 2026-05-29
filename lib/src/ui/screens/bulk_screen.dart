import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          'Apply the Colour Lab pipeline to every sprite, and/or convert every '
          'sprite to another format. Animation frames are preserved for '
          'PNG/APNG/GIF.',
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Recolour', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
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
              ],
            ),
          ),
        ),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Convert format',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButton<OutputFormat>(
                  value: _format,
                  items: const <DropdownMenuItem<OutputFormat>>[
                    DropdownMenuItem<OutputFormat>(
                        value: OutputFormat.keep, child: Text('Keep (AO-best)')),
                    DropdownMenuItem<OutputFormat>(
                        value: OutputFormat.png, child: Text('PNG / APNG')),
                    DropdownMenuItem<OutputFormat>(
                        value: OutputFormat.apng, child: Text('APNG')),
                    DropdownMenuItem<OutputFormat>(
                        value: OutputFormat.gif, child: Text('GIF')),
                    DropdownMenuItem<OutputFormat>(
                        value: OutputFormat.webp, child: Text('WebP')),
                  ],
                  onChanged: (OutputFormat? f) =>
                      setState(() => _format = f ?? OutputFormat.keep),
                ),
                if (wantsWebp) ...<Widget>[
                  const SizedBox(height: 8),
                  Row(children: <Widget>[
                    Switch(
                      value: _lossless,
                      onChanged: enc.supportsLossless
                          ? (bool v) => setState(() => _lossless = v)
                          : null,
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
                        : 'WebP encoder: not available on this platform — install '
                            'libwebp (see docs/PLUGINS.md) or use the web build.',
                    style: TextStyle(
                      fontSize: 12,
                      color: enc.supportsLossy ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
                Row(children: <Widget>[
                  Checkbox(
                    value: _deleteOriginal,
                    onChanged: (bool? v) =>
                        setState(() => _deleteOriginal = v ?? false),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
