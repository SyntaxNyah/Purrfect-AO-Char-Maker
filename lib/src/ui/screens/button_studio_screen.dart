import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ao_constants.dart';
import '../app_state.dart';
import '../widgets/checker_image.dart';

class ButtonStudioScreen extends StatefulWidget {
  const ButtonStudioScreen({super.key});

  @override
  State<ButtonStudioScreen> createState() => _ButtonStudioScreenState();
}

class _ButtonStudioScreenState extends State<ButtonStudioScreen> {
  int _size = CharFolder.defaultButtonSize;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Button Studio', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Buttons are auto-generated for every emote (trim → centre square → '
            'scale) when you export. Preview the selected emote\'s button here.',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: app.current == null
                        ? const Center(child: Text('No emote'))
                        : FutureBuilder<Uint8List?>(
                            future: app.previewAutoButton(_size),
                            builder: (BuildContext c, AsyncSnapshot<Uint8List?> s) =>
                                CheckerImage(bytes: s.data),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text('${_size}×$_size px'),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Button size: $_size px (default 128)'),
                    Slider(
                      value: _size.toDouble().clamp(24, 256),
                      min: 24,
                      max: 256,
                      divisions: 232,
                      onChanged: (double v) => setState(() => _size = v.round()),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => app.exportZip(),
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Export character (.zip) with auto buttons'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tip: drop a buttonN_off.png into emotions/ to override any '
                      'auto button. The advanced compositor (background / '
                      'foreground / mask / crop) is available in the engine '
                      '(ButtonMaker.renderComposite).',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
