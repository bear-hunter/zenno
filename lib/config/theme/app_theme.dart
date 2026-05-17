import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Assembles Zenno's [ThemeData].
///
/// **Public contract** — `lib/main.dart` (and any `MaterialApp`) depends on
/// this exact API:
///
/// ```dart
/// theme: AppTheme.light,
/// darkTheme: AppTheme.dark,
/// ```
///
/// Zenno is dark-first: [dark] is the intended experience, carrying the full
/// near-black surface ramp and warm-gold accent of the design language.
/// [light] is a valid, clean Material 3 light theme from the same seed —
/// present so the app never crashes if a light theme is selected.
abstract final class AppTheme {
  const AppTheme._();

  /// The dark theme — the app default. Built on Material 3.
  ///
  /// Strategy: seed a [ColorScheme] from [AppColors.goldAccent], then
  /// `copyWith` to (a) pin `primary` to the exact gold and (b) override the
  /// surface ramp with the hand-picked near-black steps from [AppColors] —
  /// `fromSeed` alone produces a faintly gold-tinted, too-light dark surface.
  static ThemeData get dark {
    final seeded = ColorScheme.fromSeed(
      seedColor: AppColors.goldAccent,
      brightness: Brightness.dark,
    );

    final colorScheme = seeded.copyWith(
      primary: AppColors.goldAccent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.goldAccent,
      onSecondary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceMuted,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.outline,
      outlineVariant: AppColors.outline,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.surface,
    );
  }

  /// The light theme — a clean, valid Material 3 light variant from the same
  /// gold seed. Not the focus of the app; it just needs to be coherent.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.goldAccent);

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: colorScheme.surface,
    );
  }

  /// Shared assembly for both brightnesses: applies the [colorScheme], the
  /// tablet-tuned text theme, and component themes (nav rail, app bar, etc.).
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
  }) {
    final textTheme = AppTextStyles.textTheme(colorScheme.onSurface);
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      textTheme: textTheme,
      // ~48dp minimum touch targets — tablet + S Pen ergonomics.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,

      // Near-black, flat app bar — no elevation, no tonal tint.
      appBarTheme: AppBarThemeData(
        backgroundColor: scaffoldBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Persistent left navigation rail (Library / Focus / Revision /
      // Goal Cycle / Settings). Transparent so it sits on the near-black
      // scaffold; selected destination gets a gold pill + gold icon.
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.20),
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(
          color: isDark
              ? AppColors.onSurfaceMuted
              : colorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: isDark
              ? AppColors.onSurfaceMuted
              : colorScheme.onSurfaceVariant,
        ),
        useIndicator: true,
      ),

      // Cards default to the low container step; flat, with a subtle radius.
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
      ),

      // Gold FAB — the primary create affordance (e.g. new canvas).
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.lg),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
