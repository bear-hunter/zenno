import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:zenno/canvas/input/stylus_button_mapping.dart';
import 'package:zenno/config/theme/app_theme.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/widgets/app_scaffold.dart';
import 'package:zenno/core/widgets/aurora.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';
import 'package:zenno/features/settings/data/settings_repository.dart';
import 'package:zenno/features/settings/presentation/pages/settings_page.dart';

void main() {
  testWidgets('quiet surfaces follow the active light theme', (tester) async {
    final theme = AppTheme.light;
    const panelKey = Key('panel');

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: AuroraBackground(
            child: Center(
              child: AuroraPanel(key: panelKey, child: Text('Notes')),
            ),
          ),
        ),
      ),
    );

    final background = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(AuroraBackground),
        matching: find.byType(ColoredBox),
      ),
    );
    final panel = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(panelKey),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = panel.decoration as BoxDecoration;

    expect(background.color, theme.scaffoldBackgroundColor);
    expect(decoration.color, theme.colorScheme.surfaceContainerLow);
  });

  testWidgets('app shell changes navigation for available space', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    final router = _testRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    var rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.byType(NavigationBar), findsNothing);

    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpAndSettle();
    rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);

    tester.view.physicalSize = const Size(640, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('settings use responsive editorial rows without panel chrome', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = SettingsRepository(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Canvas & stylus'), findsOneWidget);
    expect(find.byType(AuroraPanel), findsNothing);
    final wideDifference =
        (tester.getCenter(find.text('Theme')).dy -
                tester.getCenter(find.text('Light').first).dy)
            .abs();
    expect(wideDifference, lessThan(30));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpAndSettle();
    final narrowDifference =
        tester.getCenter(find.text('Light').first).dy -
        tester.getCenter(find.text('Theme')).dy;
    expect(narrowDifference, greaterThan(30));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('settings preserve unsupported legacy stylus mappings safely', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1200);
    addTearDown(tester.view.reset);
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = SettingsRepository(db);
    const StylusButtonMapping legacy = StylusButtonMapping(
      hold: StylusButtonAction.eyedropper,
      tap: StylusButtonAction.exportSelection,
      drag: StylusButtonAction.eyedropper,
      penLongPress: StylusButtonAction.exportSelection,
    );
    await repository.setStylusButtonMapping(legacy);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final buttons = tester
        .widgetList<DropdownButton<StylusButtonAction>>(
          find.byType(DropdownButton<StylusButtonAction>),
        )
        .toList();
    expect(buttons, hasLength(4));
    final labels = <List<String>>[
      for (final button in buttons)
        <String>[for (final item in button.items!) (item.child as Text).data!],
    ];
    expect(labels[0], contains('Eyedropper (Unavailable)'));
    expect(labels[0], isNot(contains('Export selection')));
    expect(labels[1], contains('Export selection (Unavailable)'));
    expect(labels[1], isNot(contains('Eyedropper')));
    expect(labels[2], contains('Eyedropper (Unavailable)'));
    expect(labels[3], contains('Export selection (Unavailable)'));
    for (final button in buttons) {
      expect(
        button.items!.singleWhere((item) => item.value == button.value).enabled,
        isFalse,
      );
    }
    expect(
      await repository.readSettings().then(
        (model) => model.stylusButtonMapping,
      ),
      legacy,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppScaffold(navigationShell: shell),
        branches: [
          for (final path in const [
            '/library',
            '/focus',
            '/revision',
            '/goals',
            '/settings',
          ])
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  builder: (context, state) => Scaffold(body: Text(path)),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
