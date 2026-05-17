import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:zenno/canvas/canvas_editor_page.dart';
import 'package:zenno/config/router/routes.dart';
import 'package:zenno/core/widgets/app_scaffold.dart';
import 'package:zenno/features/focus/presentation/pages/focus_home_page.dart';
import 'package:zenno/features/goal_cycle/presentation/pages/goal_board_page.dart';
import 'package:zenno/features/library/presentation/pages/library_page.dart';
import 'package:zenno/features/revision/presentation/pages/revision_board_page.dart';
import 'package:zenno/features/settings/presentation/pages/settings_page.dart';

/// Navigator key for the root navigator. The full-bleed canvas route is pushed
/// onto this navigator so it sits above the shell rather than inside a branch.
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// The application router.
///
/// A [StatefulShellRoute.indexedStack] hosts the five feature branches behind
/// the persistent [AppScaffold] navigation rail; each branch retains its own
/// navigation state. The canvas editor is a separate top-level route so it
/// opens outside the shell as a true full-bleed landscape surface.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.library,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.library,
              builder: (context, state) => const LibraryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.focus,
              builder: (context, state) => const FocusHomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.revision,
              builder: (context, state) => const RevisionBoardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.goals,
              builder: (context, state) => const GoalBoardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.canvas,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          CanvasEditorPage(canvasId: state.pathParameters['id']!),
    ),
  ],
);
