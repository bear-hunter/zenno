import 'package:flutter/material.dart';

/// Builds Zenno's [TextTheme].
///
/// Sizes sit slightly above the Material 3 phone defaults. Zenno runs on a
/// tablet held at arm's length, so body and label text in particular get a
/// modest bump for comfortable reading. Weights and the rough Material 3 type
/// hierarchy are preserved.
abstract final class AppTextStyles {
  const AppTextStyles._();

  /// A complete [TextTheme], with every glyph tinted [color] (the theme's
  /// `onSurface`). Heights are set explicitly so multi-line text breathes.
  static TextTheme textTheme(Color color) {
    return TextTheme(
      // Display — reserved for large hero text; rarely used in-app.
      displayLarge: TextStyle(
        fontSize: 60,
        height: 1.12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: color,
      ),
      displayMedium: TextStyle(
        fontSize: 48,
        height: 1.16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      displaySmall: TextStyle(
        fontSize: 38,
        height: 1.22,
        fontWeight: FontWeight.w400,
        color: color,
      ),

      // Headline — page titles, empty-state headings.
      headlineLarge: TextStyle(
        fontSize: 34,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontSize: 30,
        height: 1.29,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontSize: 26,
        height: 1.33,
        fontWeight: FontWeight.w600,
        color: color,
      ),

      // Title — card titles, section headers, app-bar titles.
      titleLarge: TextStyle(
        fontSize: 24,
        height: 1.27,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        height: 1.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        height: 1.43,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),

      // Body — the workhorse styles for paragraphs and list content.
      bodyLarge: TextStyle(
        fontSize: 18,
        height: 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        height: 1.43,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: color,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        height: 1.33,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: color,
      ),

      // Label — buttons, chips, nav-rail labels, captions.
      labelLarge: TextStyle(
        fontSize: 16,
        height: 1.43,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        height: 1.33,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      ),
    );
  }
}
