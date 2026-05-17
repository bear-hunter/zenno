import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_colors.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/board_tables.dart';

/// Maps a [MasteryFlag] to its fixed, semantic colour.
///
/// Green / yellow / red are meaning-bearing on the revision board and stay
/// recognisable regardless of theme — see [AppColors].
Color masteryFlagColor(MasteryFlag flag) => switch (flag) {
  MasteryFlag.green => AppColors.flagGreen,
  MasteryFlag.yellow => AppColors.flagYellow,
  MasteryFlag.red => AppColors.flagRed,
};

/// A short human label for a [MasteryFlag].
String masteryFlagLabel(MasteryFlag flag) => switch (flag) {
  MasteryFlag.green => 'Confident',
  MasteryFlag.yellow => 'Shaky',
  MasteryFlag.red => 'Weak',
};

/// A small pill showing a card's mastery rating: a coloured dot and a label.
///
/// Used both on the revision card tile (compact) and in the detail sheet's
/// flag picker (as the selected/unselected choices).
class MasteryFlagChip extends StatelessWidget {
  /// Creates a chip for [flag].
  const MasteryFlagChip({required this.flag, this.dense = false, super.key});

  /// The mastery rating to display.
  final MasteryFlag flag;

  /// When true the chip uses tighter padding for an in-card footer.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = masteryFlagColor(flag);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dense ? 8 : 10,
            height: dense ? 8 : 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: dense ? AppSpacing.xs : AppSpacing.sm),
          Text(
            masteryFlagLabel(flag),
            style:
                (dense
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
