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

const List<({IconData icon, String label})> _dests =
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

/// Persistent navigation rail + status bar around the active screen.
///
/// Performance: only the *active* screen is built (not all eight via an
/// IndexedStack), and the shell/rail do NOT subscribe to [AppState], so a
/// slider drag no longer rebuilds the whole UI — only the screen that needs it.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Widget _screenFor(int i) {
    switch (i) {
      case 1:
        return const EditorScreen();
      case 2:
        return const ColorLabScreen();
      case 3:
        return const AnimationStudioScreen();
      case 4:
        return const ButtonStudioScreen();
      case 5:
        return const MixerScreen();
      case 6:
        return const BulkScreen();
      case 7:
        return const PluginsScreen();
      case 0:
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          _NavRail(
            index: _index,
            onSelect: (int i) => setState(() => _index = i),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            // Only rebuilds when project presence flips (rare), not on every
            // AppState change.
            child: Selector<AppState, bool>(
              selector: (_, AppState a) => a.hasProject,
              builder: (BuildContext context, bool hasProject, _) {
                final bool needsProject =
                    _index != 0 && _index != 7 && !hasProject;
                if (needsProject) {
                  return _NoProject(onGoHome: () => setState(() => _index = 0));
                }
                return KeyedSubtree(
                  key: ValueKey<int>(_index),
                  child: _screenFor(_index),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _StatusBar(),
    );
  }
}

/// Scrollable navigation rail (NavigationRail itself doesn't scroll, so a short
/// window would overflow with this many destinations).
class _NavRail extends StatelessWidget {
  const _NavRail({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: NavigationRail(
                selectedIndex: index,
                onDestinationSelected: onSelect,
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('🐾', style: TextStyle(fontSize: 24)),
                ),
                destinations: <NavigationRailDestination>[
                  for (final ({IconData icon, String label}) d in _dests)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PurrfectTheme.surface,
      child: SizedBox(
        height: 30,
        child: Consumer<AppState>(
          builder: (BuildContext context, AppState app, _) => Row(
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
      ),
    );
  }
}
