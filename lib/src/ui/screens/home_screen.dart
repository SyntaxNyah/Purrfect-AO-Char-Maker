import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ao_constants.dart';
import '../../core/validator.dart';
import '../../discovery/character_builder.dart';
import '../../platform/folder_picker.dart';
import '../../plugins/extension_registry.dart';
import '../app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _importFiles(BuildContext context) async {
    final AppState app = context.read<AppState>();
    final FilePickerResult? res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: kImportableImageExtensions,
    );
    if (res == null) return;
    final List<PickedFile> files = <PickedFile>[
      for (final PlatformFile f in res.files)
        if (f.bytes != null) PickedFile(f.name, f.bytes!),
    ];
    await app.importFiles(files);
  }

  Future<void> _importFolder(BuildContext context) async {
    final AppState app = context.read<AppState>();
    final List<PickedFolderFile>? files = await pickFolderFiles();
    if (files == null || files.isEmpty) return;
    await app.importFiles(<PickedFile>[
      for (final PickedFolderFile f in files) PickedFile(f.name, f.bytes),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final ExtensionRegistry reg = ExtensionRegistry.instance;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('🐾 Pinsel AO Char Maker',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Drop in a folder of sprites → get a finished, AO/webAO-ready character '
          '(auto ini, folders, and buttons). Recolour, animate and customise '
          'everything. Runs on Windows, Linux, macOS, Android, iOS and the web.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FilledButton.icon(
              onPressed: () => _importFiles(context),
              icon: const Icon(Icons.image_outlined),
              label: const Text('Import sprite files'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _importFolder(context),
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Import folder'),
            ),
            if (app.hasProject) ...<Widget>[
              OutlinedButton.icon(
                onPressed: () => app.exportZip(),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Export .zip'),
              ),
              OutlinedButton.icon(
                onPressed: () => app.exportIni(),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Export char.ini'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        _AutoBuildCard(app: app),
        const SizedBox(height: 12),
        if (app.hasProject) _ValidatorCard(app: app),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${reg.colorPresets.length} colour presets · '
                    '${reg.palettes.length} palettes · '
                    '${reg.gradients.length} gradients · '
                    '${reg.animPresets.length} animations · '
                    '${reg.packs.length} plugin pack(s) installed',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AutoBuildCard extends StatelessWidget {
  const _AutoBuildCard({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final BuildConfig c = app.buildConfig;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Auto-build options',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    initialValue: c.name,
                    decoration: const InputDecoration(labelText: 'Character name (folder)'),
                    onChanged: (String v) =>
                        app.updateBuildConfig(_copy(c, name: v)),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<CourtSide>(
                  value: c.side,
                  items: <DropdownMenuItem<CourtSide>>[
                    for (final CourtSide s in CourtSide.values)
                      DropdownMenuItem<CourtSide>(value: s, child: Text(s.label)),
                  ],
                  onChanged: (CourtSide? s) =>
                      app.updateBuildConfig(_copy(c, side: s)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: <Widget>[
                _toggle(context, 'Bare file = preanim', c.treatBareAsPreanim,
                    (bool v) => app.updateBuildConfig(_copy(c, bare: v))),
                _toggle(context, 'Guess sound effects', c.guessSounds,
                    (bool v) => app.updateBuildConfig(_copy(c, sounds: v))),
              ],
            ),
            if (app.hasProject) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => app.regenerate(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Regenerate from sprites'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggle(BuildContext context, String label, bool value,
          ValueChanged<bool> onChanged) =>
      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Switch(value: value, onChanged: onChanged),
        Text(label),
      ]);

  BuildConfig _copy(BuildConfig c,
          {String? name, CourtSide? side, bool? bare, bool? sounds}) =>
      BuildConfig(
        name: name ?? c.name,
        showname: c.showname,
        side: side ?? c.side,
        blips: c.blips,
        chat: c.chat,
        scaling: c.scaling,
        defaultDeskMod: c.defaultDeskMod,
        treatBareAsPreanim: bare ?? c.treatBareAsPreanim,
        guessSounds: sounds ?? c.guessSounds,
      );
}

class _ValidatorCard extends StatelessWidget {
  const _ValidatorCard({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final List<LintIssue> issues = app.issues;
    final int errors = CharacterValidator.count(issues, LintSeverity.error);
    final int warnings =
        issues.where((LintIssue i) => i.severity == LintSeverity.warning).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              Icon(errors > 0
                  ? Icons.error_outline
                  : warnings > 0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline),
              const SizedBox(width: 8),
              Text('Validation: $errors error(s), $warnings warning(s)',
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 8),
            ...issues.take(6).map((LintIssue i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• ${i.toString()}',
                      style: Theme.of(context).textTheme.bodySmall),
                )),
            if (issues.length > 6) Text('…and ${issues.length - 6} more'),
            if (issues.isEmpty) const Text('No problems found. 🎉'),
          ],
        ),
      ),
    );
  }
}
