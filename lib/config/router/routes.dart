/// Centralised route path constants for the app router.
///
/// Keeping paths in one place avoids magic strings at navigation call sites
/// and makes route renames a single-edit change.
class Routes {
  const Routes._();

  /// Canvas library — the app's initial location.
  static const String library = '/library';

  /// Focus (Pomodoro / Flowmodoro) feature.
  static const String focus = '/focus';

  /// Schedule Revision board.
  static const String revision = '/revision';

  /// Goal Cycle board.
  static const String goals = '/goals';

  /// App settings.
  static const String settings = '/settings';

  /// Canvas editor, parameterised by canvas id. Lives outside the shell so the
  /// canvas opens full-bleed.
  static const String canvas = '/canvas/:id';

  /// Builds a concrete canvas editor path for [id].
  static String canvasPath(String id) => '/canvas/$id';
}
