import 'package:flutter/material.dart';
import 'package:zenno/config/theme/app_spacing.dart';

/// A 1–5 energy-level picker rendered as a row of selectable pips.
///
/// Used for both the pre-session and post-session energy rating. The selected
/// value and every pip below it fill with the theme accent; the rest read as
/// hollow outlines. Tapping a pip reports its 1-based value through [onChanged].
class EnergyRatingSelector extends StatelessWidget {
  /// Creates an energy-rating selector.
  const EnergyRatingSelector({
    required this.value,
    required this.onChanged,
    this.lowLabel = 'Drained',
    this.highLabel = 'Energised',
    super.key,
  });

  /// The currently selected rating, 1–5.
  final int value;

  /// Called with the new 1–5 rating when a pip is tapped.
  final ValueChanged<int> onChanged;

  /// Caption shown under the low (1) end of the scale.
  final String lowLabel;

  /// Caption shown under the high (5) end of the scale.
  final String highLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var level = 1; level <= 5; level++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: level == 5 ? 0 : AppSpacing.sm,
                  ),
                  child: _EnergyPip(
                    level: level,
                    filled: level <= value,
                    onTap: () => onChanged(level),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lowLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              highLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A single energy pip — a tappable rounded bar that is filled or hollow.
class _EnergyPip extends StatelessWidget {
  const _EnergyPip({
    required this.level,
    required this.filled,
    required this.onTap,
  });

  final int level;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'Energy level $level of 5',
      selected: filled,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 48,
          decoration: BoxDecoration(
            color: filled
                ? colors.primary.withValues(alpha: 0.18)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled ? colors.primary : colors.outlineVariant,
              width: filled ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$level',
            style: theme.textTheme.titleMedium?.copyWith(
              color: filled ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
