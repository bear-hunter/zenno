import 'package:flutter/material.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';

/// A two-card picker for the focus session's timing model.
///
/// Presents Pomodoro and Flowmodoro side by side with a one-line description
/// of each; the selected card is outlined in the theme accent. Reports the
/// chosen [TimerMode] through [onChanged].
class TimerTypePicker extends StatelessWidget {
  /// Creates a timer-type picker.
  const TimerTypePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The currently selected timing model.
  final TimerMode value;

  /// Called with the new model when a card is tapped.
  final ValueChanged<TimerMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: Icons.timer_outlined,
            title: 'Pomodoro',
            description: 'Fixed work and break intervals.',
            selected: value == TimerMode.pomodoro,
            onTap: () => onChanged(TimerMode.pomodoro),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ModeCard(
            icon: Icons.waves_outlined,
            title: 'Flowmodoro',
            description: 'Open-ended focus, proportional breaks.',
            selected: value == TimerMode.flowmodoro,
            onTap: () => onChanged(TimerMode.flowmodoro),
          ),
        ),
      ],
    );
  }
}

/// A single selectable timing-model card.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.12)
          : colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selected ? colors.primary : colors.onSurface,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, size: 20, color: colors.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
