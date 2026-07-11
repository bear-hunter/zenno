import 'package:flutter/material.dart';

/// Zenno's quiet paper-and-ink palette.
///
/// Product chrome uses one restrained terracotta accent. The additional
/// colours below are semantic/data colours retained for study status and
/// canvas content; they are not decorative background accents.
abstract final class AppColors {
  const AppColors._();

  // --- Brand accent -------------------------------------------------------

  /// Warm terracotta used for primary actions in the dark theme.
  static const Color goldAccent = Color(0xFFD8946C);

  /// Deeper terracotta used for pressed states and the light-theme primary.
  static const Color goldAccentDim = Color(0xFF8F4D32);

  /// Soft terracotta container colour.
  static const Color goldAccentSoft = Color(0xFFF0D8C8);

  /// Compatibility alias for older feature code that used an amber accent.
  static const Color amberAccent = goldAccent;

  // --- Warm light palette -------------------------------------------------

  static const Color paper = Color(0xFFF7F3EA);
  static const Color paperRaised = Color(0xFFFFFCF5);
  static const Color paperSunk = Color(0xFFEFE8DB);
  static const Color paperHigh = Color(0xFFE8E0D2);
  static const Color paperHighest = Color(0xFFDED4C3);
  static const Color paperOutline = Color(0xFFD6CCBB);
  static const Color ink = Color(0xFF292620);
  static const Color inkMuted = Color(0xFF6E675C);

  // --- Deep neutral dark palette -----------------------------------------

  static const Color surface = Color(0xFF111210);
  static const Color surfaceContainerLow = Color(0xFF181A17);
  static const Color surfaceContainer = Color(0xFF20231F);
  static const Color surfaceContainerHigh = Color(0xFF292C27);
  static const Color surfaceContainerHighest = Color(0xFF343832);
  static const Color outline = Color(0xFF42463E);

  /// Legacy Aurora names. [AuroraPanel] maps these to theme-aware surfaces.
  static const Color auroraGlass = Color(0xFF181A17);
  static const Color auroraGlassStrong = Color(0xFF20231F);
  static const Color auroraHairline = Color(0xFF42463E);

  // --- Text / foreground --------------------------------------------------

  static const Color onSurface = Color(0xFFF1EEE6);
  static const Color onSurfaceMuted = Color(0xFFB1ADA3);
  static const Color onSurfaceFaint = Color(0xFF817E76);
  static const Color onAccent = Color(0xFF2C160D);

  // --- Semantic and canvas colours ---------------------------------------

  static const Color tealAccent = Color(0xFF6F9385);
  static const Color violetAccent = Color(0xFF8B7FA4);
  static const Color roseAccent = Color(0xFFC87A8D);
  static const Color blueAccent = Color(0xFF6E8EAD);

  static const Color flagGreen = Color(0xFF718D68);
  static const Color flagYellow = Color(0xFFC49B49);
  static const Color flagRed = Color(0xFFB85F50);
}
