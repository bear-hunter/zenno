import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenno/config/theme/app_colors.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/util/relative_time.dart';
import 'package:zenno/features/focus/application/active_session_controller.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/application/focus_stats_provider.dart';
import 'package:zenno/features/focus/data/focus_repository.dart';
import 'package:zenno/features/focus/domain/focus_stats.dart';
import 'package:zenno/features/focus/presentation/pages/focus_active_page.dart';
import 'package:zenno/features/focus/presentation/pages/focus_history_page.dart';
import 'package:zenno/features/focus/presentation/pages/focus_setup_page.dart';

/// The Focus feature's home screen.
///
/// The hub of the Focus flow: a prominent "Start session" call to action (or a
/// "Resume session" banner when one is already running), a snapshot of the
/// aggregate stats, and the most recent sessions. From here the user pushes
/// Setup → Active → Review, or History.
///
/// The class name and the route path are unchanged from the Phase-0
/// placeholder — the router references this widget directly.
class FocusHomePage extends ConsumerWidget {
  /// Creates the Focus home screen.
  const FocusHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(focusHistoryProvider);
    final stats = ref.watch(focusStatsProvider);
    final active = ref.watch(activeSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FocusHistoryPage(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                if (active.hasSession)
                  _ResumeBanner(
                    onTap: () => _openActive(context),
                  )
                else
                  _StartCard(onTap: () => _openSetup(context)),
                const SizedBox(height: AppSpacing.xl),

                _StatsSummary(stats: stats),
                const SizedBox(height: AppSpacing.xl),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent sessions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const FocusHistoryPage(),
                        ),
                      ),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                history.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Text('Could not load history: $error'),
                  data: (sessions) => sessions.isEmpty
                      ? const _NoSessionsYet()
                      : Column(
                          children: [
                            // Show only the five most recent here; the
                            // History screen lists the rest.
                            for (final detail in sessions.take(5))
                              _RecentSessionTile(detail: detail),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pushes the Setup screen.
  void _openSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FocusSetupPage()),
    );
  }

  /// Pushes the Active screen for the session already running.
  void _openActive(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FocusActivePage()),
    );
  }
}

/// The prominent "Start session" call to action.
class _StartCard extends StatelessWidget {
  const _StartCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primary,
                child: Icon(
                  Icons.play_arrow,
                  color: colors.onPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start a focus session',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Run your pre-study ritual, pick a timer, and begin.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// The banner shown on Home while a session is already running.
class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: AppColors.flagGreen.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.flagGreen.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.timelapse,
                color: AppColors.flagGreen,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session in progress',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap to return to your running timer.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact one-row summary of the aggregate focus stats.
class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.stats});

  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (stats.completedSessions == 0) {
      return const SizedBox.shrink();
    }

    final hours = stats.totalFocus.inHours;
    final minutes = stats.totalFocus.inMinutes.remainder(60);
    final focusText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _MiniStat(
            label: 'Sessions',
            value: '${stats.completedSessions}',
          ),
          _Separator(color: colors.outlineVariant),
          _MiniStat(label: 'Total focus', value: focusText),
          _Separator(color: colors.outlineVariant),
          _MiniStat(
            label: 'Distractions / session',
            value: stats.distractionsPerSession.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }
}

/// A single statistic in the Home summary row.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A thin vertical rule between Home summary stats.
class _Separator extends StatelessWidget {
  const _Separator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: color,
    );
  }
}

/// A condensed recent-session row for the Home screen.
class _RecentSessionTile extends StatelessWidget {
  const _RecentSessionTile({required this.detail});

  final FocusSessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final session = detail.session;

    final title = session.goalText.trim().isEmpty
        ? 'Focus session'
        : session.goalText.trim();

    final focus = Duration(seconds: session.actualFocusSecs);
    final focusText = focus.inHours > 0
        ? '${focus.inHours}h ${focus.inMinutes.remainder(60)}m'
        : '${focus.inMinutes}m';

    final statusColor = switch (session.status) {
      FocusSessionStatus.completed => AppColors.flagGreen,
      FocusSessionStatus.abandoned => AppColors.flagRed,
      FocusSessionStatus.inProgress => AppColors.flagYellow,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.18),
          child: Icon(
            session.timerKind == TimerKind.pomodoro
                ? Icons.timer_outlined
                : Icons.waves_outlined,
            color: statusColor,
          ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '$focusText focused  ·  ${relativeTime(session.startedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '${session.cyclesCompleted}×',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// The zero-state shown under "Recent sessions" before any session exists.
class _NoSessionsYet extends StatelessWidget {
  const _NoSessionsYet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No sessions yet — start your first one above.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
