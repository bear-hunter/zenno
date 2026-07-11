import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_colors.dart';
import 'package:zenno/config/theme/app_spacing.dart';

/// Theme-aware compatibility shell for Zenno's former Aurora background.
///
/// The name remains public so feature screens do not need to know that the
/// visual language is now a quiet, flat paper-and-ink surface.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

/// A restrained, theme-aware content surface.
class AuroraPanel extends StatelessWidget {
  const AuroraPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.radius = AppRadii.lg,
    this.color,
    this.borderColor,
    this.clip = true,
    this.showShadow = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool clip;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = switch (color) {
      null => colors.surfaceContainerLow,
      AppColors.auroraGlass => colors.surfaceContainerLow,
      AppColors.auroraGlassStrong => colors.surfaceContainer,
      final value => value,
    };
    final outline = switch (borderColor) {
      null => colors.outlineVariant,
      AppColors.auroraHairline => colors.outlineVariant,
      final value => value,
    };
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: outline),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    final wrapped = clip
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: decorated,
          )
        : decorated;
    if (margin == null) return wrapped;
    return Padding(padding: margin!, child: wrapped);
  }
}

/// Compact shared page header used across top-level feature screens.
class AuroraTopBar extends StatelessWidget {
  const AuroraTopBar({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(title, style: theme.textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720 && actions.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: actions,
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: actions,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A consistent 48dp icon action with optional selected treatment.
class AuroraIconButton extends StatelessWidget {
  const AuroraIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.size = AppSpacing.touchTarget,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dimension = size < AppSpacing.touchTarget
        ? AppSpacing.touchTarget
        : size;
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: dimension,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: selected
                ? colors.primaryContainer
                : Colors.transparent,
            foregroundColor: selected
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
            disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              side: BorderSide(color: colors.outlineVariant),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact metadata chip; interactive instances retain a 48dp touch target.
class AuroraPill extends StatelessWidget {
  const AuroraPill({
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.onSurfaceVariant;
    final visibleHeight = onTap == null ? 32.0 : AppSpacing.touchTarget;
    final content = Container(
      height: visibleHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: accent),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: content,
      ),
    );
  }
}
