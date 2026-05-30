import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../plugins/extension_registry.dart';
import '../../plugins/pack.dart';
import '../app_state.dart';

class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  String? _message;

  Future<void> _importPack() async {
    final FilePickerResult? res = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: <String>['json', 'purrpack'],
    );
    if (res == null || res.files.isEmpty || res.files.first.bytes == null) return;
    try {
      final String json = utf8.decode(res.files.first.bytes!);
      final PinselPack pack = ExtensionRegistry.instance.installPackJson(json);
      setState(() => _message =
          'Installed "${pack.name}" (${pack.itemCount} items) by ${pack.author}.');
    } catch (e) {
      setState(() => _message = 'Could not read pack: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Touch AppState so the screen rebuilds with the rest of the app.
    context.watch<AppState>();
    final ExtensionRegistry reg = ExtensionRegistry.instance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Plugins & packs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Packs are plain JSON that add presets, palettes, gradients, animations '
          'and emote-name sets — no install, no recompiling, and they work on the '
          'web build too. See docs/PLUGINS.md to author your own.',
        ),
        const SizedBox(height: 12),
        Row(children: <Widget>[
          FilledButton.icon(
            onPressed: _importPack,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Import pack (.json)'),
          ),
          const SizedBox(width: 12),
          Text('${reg.installedItemCount} item(s) from ${reg.packs.length} pack(s)'),
        ]),
        if (_message != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(_message!, style: const TextStyle(color: Colors.green)),
        ],
        const Divider(height: 24),
        if (reg.packs.isEmpty)
          const Text('No packs installed yet.')
        else
          ...reg.packs.map((PinselPack p) => Card(
                child: ListTile(
                  title: Text('${p.name}  v${p.version}'),
                  subtitle: Text('${p.description}\nby ${p.author} · '
                      '${p.itemCount} items'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      reg.removePack(p.name);
                      setState(() => _message = 'Removed "${p.name}".');
                    },
                  ),
                ),
              )),
        const Divider(height: 24),
        Text('Built-in content', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('${reg.colorPresets.length} colour presets · '
            '${reg.palettes.length} palettes · ${reg.gradients.length} gradients · '
            '${reg.animPresets.length} animations · '
            '${reg.emoteNameSets.length} name sets'),
      ],
    );
  }
}
