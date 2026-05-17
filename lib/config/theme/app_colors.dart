import 'package:flutter/material.dart';

/// Static color tokens for Zenno's dark-first, gold-accented design language.
///
/// These are the raw palette values. The actual [ThemeData] / [ColorScheme] is
/// assembled in `app_theme.dart`, which seeds from [goldAccent] and then forces
/// the near-black surface ramp defined here.
abstract final class AppColors {
  const AppColors._();

  // --- Brand accent -------------------------------------------------------

  /// Warm gold — the single brand accent. Used for [ColorScheme.primary],
  /// selected nav-rail indicators, FABs, and other emphasis affordances.
  static const Color goldAccent = Color(0xFFE8B84B);

  /// A slightly deeper gold for pressed/hover states and subtle gradients.
  static const Color goldAccentDim = Color(0xFFC99A33);

  // --- Dark surface ramp --------------------------------------------------
  // Near-black, low-chroma steps. Each step is a touch lighter than the last
  // so elevated surfaces read without needing shadows on a dark background.

  /// The base canvas: the darkest surface, used for [Scaffold] backgrounds.
  static const Color surface = Color(0xFF121212);

  /// One step up — cards, sheets, the nav rail at rest.
  static const Color surfaceContainerLow = Color(0xFF181818);

  /// Default elevated container — dialogs, menus, list tiles.
  static const Color surfaceContainer = Color(0xFF1E1E1E);

  /// Higher elevation — hovered cards, selected rows, popovers.
  static const Color surfaceContainerHigh = Color(0xFF262626);

  /// Highest elevation — drag feedback, top-most overlays.
  static const Color surfaceContainerHighest = Color(0xFF2E2E2E);

  /// Hairline dividers and outlines on dark surfaces.
  static const Color outline = Color(0xFF3A3A3A);

  // --- Text / foreground --------------------------------------------------

  /// Primary text and icons on dark surfaces — soft white, not pure white,
  /// to reduce glare on an OLED tablet panel.
  static const Color onSurface = Color(0xFFEDEDED);

  /// Secondary / muted text — captions, hints, relative timestamps.
  static const Color onSurfaceMuted = Color(0xFF9A9A9A);

  /// Foreground for elements painted on top of [goldAccent] (e.g. FAB icon).
  static const Color onAccent = Color(0xFF1A1304);

  // --- Semantic mastery flags --------------------------------------------
  // Fixed, meaning-bearing colors for the Schedule Revision board. These are
  // intentionally NOT derived from the seed — green/yellow/red must stay
  // recognisable regardless of theme.

  /// Mastery: confident / well-revised.
  static const Color flagGreen = Color(0xFF4CAF6D);

  /// Mastery: shaky / needs another pass.
  static const Color flagYellow = Color(0xFFE0B23C);

  /// Mastery: weak / priority for revision.
  static const Color flagRed = Color(0xFFE05B4B);
}
