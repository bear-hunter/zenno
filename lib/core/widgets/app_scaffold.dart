import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent application shell.
///
/// Wraps the five top-level feature branches in a [Scaffold] with a left
/// [NavigationRail]. Each branch keeps its own navigation state via the
/// [StatefulNavigationShell] created by [StatefulShellRoute.indexedStack].
class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.navigationShell, super.key});

  /// The navigation shell for the five feature branches. Drives the selected
  /// rail destination and the branch-switching behaviour.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              labelType: NavigationRailLabelType.all,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                // Tapping the already-selected destination returns its branch
                // to the initial location instead of being a no-op.
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  label: Text('Library'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.timer_outlined),
                  label: Text('Focus'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.layers_outlined),
                  label: Text('Revision'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.flag_outlined),
                  label: Text('Goals'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}
