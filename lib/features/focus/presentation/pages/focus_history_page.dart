import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenno/config/theme/app_colors.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/util/relative_time.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/application/focus_stats_provider.dart';
import 'package:zenno/features/focus/data/focus_repository.dart';
import 'package:zenno/features/focus/domain/focus_stats.dart';

/// The Focus History screen.
///
/// Shows the aggregate [FocusStats] over completed sessions, followed by a
/// reverse-chronological list of every past session. Reached from the Focus
/// Home screen via `Navigator.push`.
class FocusHistoryPage extends ConsumerWidget {
  /// Creates the history page.
  const FocusHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(focusHistoryProvider);
    final stats = ref.watch(focusStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus history')),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text('Could not load history.\n$error'),
            ),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return const _EmptyHistory();
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.contentMaxWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    _StatsPanel(stats: stats),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final detail in sessions) _SessionTile(detail: detail),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The aggregate-statistics panel at the top of the history screen.
class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.stats});

  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (stats.completedSessions == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Complete a session to see your stats.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }

    final delta = stats.avgEnergyDelta;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Across ${stats.completedSessions} completed '
            '${stats.completedSessions == 1 ? "session" : "sessions"}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _StatChip(
                label: 'Total focus',
                value: _formatDuration(stats.totalFocus),
              ),
              _StatChip(
                label: 'Avg pre-energy',
                value: _formatRating(stats.avgPreEnergy),
              ),
              _StatChip(
                label: 'Avg post-energy',
                value: _formatRating(stats.avgPostEnergy),
              ),
              _StatChip(
                label: 'Energy change',
                value: delta == null
                    ? '—'
                    : '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)}',
              ),
              _StatChip(
                label: 'Distractions / session',
                value: stats.distractionsPerSession.toStringAsFixed(1),
              ),
              _StatChip(
                label: 'Internal / external',
                value:
                    '${stats.internalDistractions} / '
                    '${stats.externalDistractions}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRating(double? value) =>
      value == null ? '—' : value.toStringAsFixed(1);
}

/// A single labelled statistic.
class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A single past-session row.
class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.detail});

  final FocusSessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final session = detail.session;

    final title = session.goalText.trim().isEmpty
        ? 'Focus session'
        : session.goalText.trim();
    final kindLabel = session.timerKind == TimerKind.pomodoro
        ? 'Pomodoro'
        : 'Flowmodoro';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                _StatusBadge(status: session.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$kindLabel  ·  ${relativeTime(session.startedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                _MetaItem(
                  icon: Icons.timelapse,
                  text: _formatDuration(
                    Duration(seconds: session.actualFocusSecs),
                  ),
                ),
                _MetaItem(
                  icon: Icons.repeat,
                  text:
                      '${session.cyclesCompleted} '
                      '${session.cyclesCompleted == 1 ? "cycle" : "cycles"}',
                ),
                _MetaItem(
                  icon: Icons.bolt_outlined,
                  text:
                      '${detail.distractions.length} '
                      '${detail.distractions.length == 1 ? "distraction" : "distractions"}',
                ),
                _MetaItem(
                  icon: Icons.battery_charging_full,
                  text: session.postEnergy == null
                      ? 'energy ${session.preEnergy}/5'
                      : 'energy ${session.preEnergy}→${session.postEnergy}',
                ),
              ],
            ),
            if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                session.notes!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single icon + text metadata item on a session card.
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A small coloured status badge for a session.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final FocusSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      FocusSessionStatus.completed => ('Completed', AppColors.flagGreen),
      FocusSessionStatus.abandoned => ('Abandoned', AppColors.flagRed),
      FocusSessionStatus.inProgress => ('In progress', AppColors.flagYellow),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// The zero-state shown when no sessions exist yet.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No sessions yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your finished focus sessions will appear here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a [Duration] as `Nh Nm`, or `Nm` under an hour.
String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}
