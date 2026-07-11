import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/widgets/aurora.dart';

/// The persistent, responsive application shell.
///
/// Wide tablets use an editorial labelled sidebar, medium layouts use a
/// compact rail, and narrow or short layouts move navigation to the bottom.
class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavigationItem>[
    _NavigationItem(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Library',
    ),
    _NavigationItem(
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer_rounded,
      label: 'Focus',
    ),
    _NavigationItem(
      icon: Icons.layers_outlined,
      selectedIcon: Icons.layers_rounded,
      label: 'Revision',
    ),
    _NavigationItem(
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag_rounded,
      label: 'Goals',
    ),
    _NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  void _select(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useBottomNavigation =
            constraints.maxWidth < AppSpacing.bottomNavigationBreakpoint ||
            constraints.maxHeight < 560;
        final extended =
            constraints.maxWidth >= AppSpacing.extendedNavigationBreakpoint;
        final colors = Theme.of(context).colorScheme;

        return Scaffold(
          body: AuroraBackground(
            child: SafeArea(
              bottom: !useBottomNavigation,
              child: useBottomNavigation
                  ? navigationShell
                  : Row(
                      children: [
                        _QuietNavigationRail(
                          currentIndex: navigationShell.currentIndex,
                          extended: extended,
                          onSelected: _select,
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: colors.outlineVariant,
                        ),
                        Expanded(child: navigationShell),
                      ],
                    ),
            ),
          ),
          bottomNavigationBar: useBottomNavigation
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    border: Border(
                      top: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: NavigationBar(
                      selectedIndex: navigationShell.currentIndex,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      onDestinationSelected: _select,
                      destinations: [
                        for (final item in _items)
                          NavigationDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: item.label,
                          ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _QuietNavigationRail extends StatelessWidget {
  const _QuietNavigationRail({
    required this.currentIndex,
    required this.extended,
    required this.onSelected,
  });

  final int currentIndex;
  final bool extended;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      extended: extended,
      minWidth: 72,
      minExtendedWidth: 216,
      groupAlignment: -0.82,
      labelType: extended ? NavigationRailLabelType.none : null,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        child: _BrandMark(extended: extended),
      ),
      onDestinationSelected: onSelected,
      destinations: [
        for (final item in AppScaffold._items)
          NavigationRailDestination(
            icon: extended
                ? Icon(item.icon)
                : Tooltip(message: item.label, child: Icon(item.icon)),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Icon(
        Icons.auto_stories_outlined,
        color: theme.colorScheme.onPrimaryContainer,
        size: 22,
      ),
    );
    if (!extended) return mark;
    return SizedBox(
      width: 184,
      child: Row(
        children: [
          mark,
          const SizedBox(width: AppSpacing.md),
          Text('Zenno', style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
