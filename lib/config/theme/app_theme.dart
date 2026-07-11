import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Assembles Zenno's warm paper-and-ink Material themes.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get dark => darkWith();

  /// Builds the dark theme, optionally retaining saved system colours.
  static ThemeData darkWith({Color? accentColor, Color? backgroundColor}) {
    final accent = accentColor ?? AppColors.goldAccent;
    final background = backgroundColor ?? AppColors.surface;
    final seeded = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    );
    final surfaces = _surfaceRamp(background, Brightness.dark);
    final colorScheme = seeded.copyWith(
      primary: accent,
      onPrimary: _readableOn(accent),
      secondary: accent,
      onSecondary: _readableOn(accent),
      surface: surfaces.$1,
      onSurface: backgroundColor == null
          ? AppColors.onSurface
          : _readableOn(background),
      onSurfaceVariant: backgroundColor == null
          ? AppColors.onSurfaceMuted
          : _mutedOn(background),
      surfaceContainerLowest: surfaces.$1,
      surfaceContainerLow: surfaces.$2,
      surfaceContainer: surfaces.$3,
      surfaceContainerHigh: surfaces.$4,
      surfaceContainerHighest: surfaces.$5,
      outline: backgroundColor == null ? AppColors.outline : surfaces.$5,
      outlineVariant: backgroundColor == null
          ? AppColors.outline.withValues(alpha: 0.72)
          : surfaces.$4,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: background,
    );
  }

  static ThemeData get light => lightWith();

  /// Builds the warm paper light theme, optionally retaining saved colours.
  static ThemeData lightWith({Color? accentColor, Color? backgroundColor}) {
    final accent = accentColor ?? AppColors.goldAccentDim;
    final background = backgroundColor ?? AppColors.paper;
    final seeded = ColorScheme.fromSeed(seedColor: accent);
    final surfaces = backgroundColor == null
        ? const (
            AppColors.paper,
            AppColors.paperRaised,
            AppColors.paperSunk,
            AppColors.paperHigh,
            AppColors.paperHighest,
          )
        : _surfaceRamp(background, Brightness.light);
    final colorScheme = seeded.copyWith(
      primary: accent,
      onPrimary: _readableOn(accent),
      secondary: accent,
      onSecondary: _readableOn(accent),
      surface: surfaces.$1,
      onSurface: backgroundColor == null
          ? AppColors.ink
          : _readableOn(background),
      onSurfaceVariant: backgroundColor == null
          ? AppColors.inkMuted
          : _mutedOn(background),
      surfaceContainerLowest: surfaces.$1,
      surfaceContainerLow: surfaces.$2,
      surfaceContainer: surfaces.$3,
      surfaceContainerHigh: surfaces.$4,
      surfaceContainerHighest: surfaces.$5,
      outline: backgroundColor == null ? AppColors.paperOutline : surfaces.$5,
      outlineVariant: backgroundColor == null
          ? AppColors.paperOutline.withValues(alpha: 0.72)
          : surfaces.$4,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: background,
    );
  }

  static (Color, Color, Color, Color, Color) _surfaceRamp(
    Color base,
    Brightness brightness,
  ) {
    final overlay = brightness == Brightness.dark ? Colors.white : Colors.black;
    Color step(double alpha) =>
        Color.alphaBlend(overlay.withValues(alpha: alpha), base);
    return (base, step(0.035), step(0.065), step(0.105), step(0.15));
  }

  static Color _readableOn(Color color) {
    return color.computeLuminance() > 0.42
        ? const Color(0xFF211A14)
        : const Color(0xFFFFFBF3);
  }

  static Color _mutedOn(Color color) {
    return _readableOn(color).withValues(alpha: 0.68);
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
  }) {
    final textTheme = AppTextStyles.textTheme(colorScheme.onSurface);
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      focusColor: colorScheme.primary.withValues(alpha: 0.16),
      hoverColor: colorScheme.primary.withValues(alpha: 0.07),
      highlightColor: colorScheme.primary.withValues(alpha: 0.10),

      appBarTheme: AppBarThemeData(
        backgroundColor: scaffoldBackground,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        useIndicator: true,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 1,
        shape: controlShape,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(
            alpha: 0.10,
          ),
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          elevation: 0,
          minimumSize: const Size(
            AppSpacing.touchTarget,
            AppSpacing.touchTarget,
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: controlShape,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(
            AppSpacing.touchTarget,
            AppSpacing.touchTarget,
          ),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: controlShape,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(
            AppSpacing.touchTarget,
            AppSpacing.touchTarget,
          ),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          minimumSize: const Size.square(AppSpacing.touchTarget),
          shape: controlShape,
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colorScheme.primaryContainer
                : Colors.transparent;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          shape: WidgetStatePropertyAll(controlShape),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: inputBorder,
          enabledBorder: inputBorder,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        waitDuration: const Duration(milliseconds: 450),
      ),
    );
  }
}
