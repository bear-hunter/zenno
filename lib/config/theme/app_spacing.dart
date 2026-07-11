/// Spacing scale for Zenno.
///
/// A small geometric-ish ramp used for padding, gaps, and margins so layout
/// rhythm stays consistent across the app. Prefer these over magic numbers.
abstract final class AppSpacing {
  const AppSpacing._();

  /// 4 — hairline gaps, icon/label separation.
  static const double xs = 4;

  /// 8 — tight padding, chip internals.
  static const double sm = 8;

  /// 12 — default gap between related controls.
  static const double md = 12;

  /// 16 — standard content padding.
  static const double lg = 16;

  /// 24 — section spacing, dialog padding.
  static const double xl = 24;

  /// 32 — large separation between major blocks.
  static const double xxl = 32;

  /// Maximum width for centered, readable text content (forms, reflections,
  /// detail sheets). Keeps line length comfortable on wide tablet landscapes.
  static const double contentMaxWidth = 720;

  /// Maximum width for broad editorial pages such as Settings.
  static const double settingsMaxWidth = 920;

  /// Minimum interactive target for touch and S Pen input.
  static const double touchTarget = 48;

  /// Shell breakpoint below which primary navigation moves to the bottom.
  static const double bottomNavigationBreakpoint = 700;

  /// Shell breakpoint above which the navigation rail shows persistent labels.
  static const double extendedNavigationBreakpoint = 1100;
}

/// Border-radius tokens for shared surfaces.
abstract final class AppRadii {
  const AppRadii._();

  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
}

/// Icon-size tokens. Keep interactive icons inside >=48dp hit targets.
abstract final class AppIconSizes {
  const AppIconSizes._();

  static const double sm = 18;
  static const double md = 24;
  static const double lg = 32;
}
