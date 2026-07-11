import 'package:flutter/material.dart';

/// Builds Zenno's calm, editorial type hierarchy.
///
/// The scale stays readable at tablet distance without making utility screens
/// feel like landing pages. Medium weights carry hierarchy; heavy weights are
/// reserved for exceptional emphasis.
abstract final class AppTextStyles {
  const AppTextStyles._();

  static TextTheme textTheme(Color color) {
    TextStyle style({
      required double size,
      required double height,
      required FontWeight weight,
      double letterSpacing = 0,
      String? fontFamily,
    }) => TextStyle(
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      fontFamily: fontFamily,
      color: color,
    );

    return TextTheme(
      displayLarge: style(
        size: 52,
        height: 1.08,
        weight: FontWeight.w400,
        letterSpacing: -0.6,
        fontFamily: 'serif',
      ),
      displayMedium: style(
        size: 44,
        height: 1.12,
        weight: FontWeight.w400,
        letterSpacing: -0.4,
        fontFamily: 'serif',
      ),
      displaySmall: style(
        size: 36,
        height: 1.16,
        weight: FontWeight.w400,
        letterSpacing: -0.25,
        fontFamily: 'serif',
      ),
      headlineLarge: style(
        size: 32,
        height: 1.2,
        weight: FontWeight.w600,
        letterSpacing: -0.25,
        fontFamily: 'serif',
      ),
      headlineMedium: style(
        size: 28,
        height: 1.22,
        weight: FontWeight.w600,
        letterSpacing: -0.2,
        fontFamily: 'serif',
      ),
      headlineSmall: style(
        size: 24,
        height: 1.25,
        weight: FontWeight.w600,
        letterSpacing: -0.1,
        fontFamily: 'serif',
      ),
      titleLarge: style(
        size: 21,
        height: 1.3,
        weight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleMedium: style(size: 17, height: 1.4, weight: FontWeight.w600),
      titleSmall: style(size: 15, height: 1.4, weight: FontWeight.w600),
      bodyLarge: style(
        size: 17,
        height: 1.5,
        weight: FontWeight.w400,
        letterSpacing: 0.05,
      ),
      bodyMedium: style(
        size: 15,
        height: 1.48,
        weight: FontWeight.w400,
        letterSpacing: 0.05,
      ),
      bodySmall: style(
        size: 13,
        height: 1.45,
        weight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      labelLarge: style(
        size: 15,
        height: 1.35,
        weight: FontWeight.w600,
        letterSpacing: 0.05,
      ),
      labelMedium: style(
        size: 13,
        height: 1.35,
        weight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: style(
        size: 12,
        height: 1.35,
        weight: FontWeight.w600,
        letterSpacing: 0.25,
      ),
    );
  }
}
