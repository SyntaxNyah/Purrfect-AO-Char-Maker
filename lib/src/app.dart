import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/app_state.dart';
import 'ui/screens/animation_studio_screen.dart';
import 'ui/screens/bulk_screen.dart';
import 'ui/screens/button_studio_screen.dart';
import 'ui/screens/color_lab_screen.dart';
import 'ui/screens/editor_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/mixer_screen.dart';
import 'ui/screens/plugins_screen.dart';
import 'ui/theme.dart';

class PurrfectApp extends StatelessWidget {
  const PurrfectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purrfect AO Char Maker',
      debugShowCheckedModeBanner: false,
      theme: PurrfectTheme.dark(),
      home: const HomeShell(),
    );
  }
}

/// Persistent navigation rail + status bar around the active screen.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<({IconData icon, String label})> _dests =
      <({IconData icon, String label})>[
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.grid_view_rounded, label: 'Emotes'),
    (icon: Icons.palette_rounded, label: 'Colour Lab'),
    (icon: Icons.movie_filter_rounded, label: 'Animate'),
    (icon: Icons.crop_square_rounded, label: 'Buttons'),
    (icon: Icons.auto_fix_high_rounded, label: 'Mixer'),
    (icon: Icons.dynamic_feed_rounded, label: 'Bulk'),
    (icon: Icons.extension_rounded, label: 'Plugins'),
  ];

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final bool needsProject = _index != 0 && _index != 7 && !app.hasProject;

    final List<Widget> screens = <Widget>[
      const HomeScreen(),
      const EditorScreen(),
      const ColorLabScreen(),
      const AnimationStudioScreen(),
      const ButtonStudioScreen(),
      const MixerScreen(),
      const BulkScreen(),
      const PluginsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (int i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('🐾', style: TextStyle(fontSize: 26)),
            ),
            destinations: <NavigationRailDestination>[
              for (final ({IconData icon, String label}) d in _dests)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: needsProject
                ? _NoProject(onGoHome: () => setState(() => _index = 0))
                : IndexedStack(index: _index, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: _StatusBar(app: app),
    );
  }
}

class _NoProject extends StatelessWidget {
  const _NoProject({required this.onGoHome});
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('No project yet', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          const Text('Import a folder of sprites to unlock this screen.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onGoHome,
            icon: const Icon(Icons.home_rounded),
            label: const Text('Go to Home'),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PurrfectTheme.surface,
      child: SizedBox(
        height: 30,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 12),
            if (app.busy)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                app.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (app.character != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${app.character!.emotes.length} emotes',
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
