import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenno/config/theme/app_colors.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/util/relative_time.dart';
import 'package:zenno/core/widgets/aurora.dart';
import 'package:zenno/features/focus/application/active_session_controller.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/application/focus_stats_provider.dart';
import 'package:zenno/features/focus/data/focus_repository.dart';
import 'package:zenno/features/focus/domain/focus_stats.dart';
import 'package:zenno/features/focus/presentation/pages/focus_active_page.dart';
import 'package:zenno/features/focus/presentation/pages/focus_history_page.dart';
import 'package:zenno/features/focus/presentation/pages/focus_review_page.dart';
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
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const AuroraTopBar(
            eyebrow: 'Deep work',
            title: 'Focus',
            subtitle: 'One thing at a time. Everything else can wait.',
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, _) {
                final hasStats = stats.completedSessions > 0;
                final startCard = active.isRestoring
                    ? const _RestoringSessionCard()
                    : active.hasSession
                    ? _ResumeBanner(
                        reviewPending: active.reviewPending,
                        onTap: () => active.reviewPending
                            ? _openReview(context)
                            : _openActive(context),
                      )
                    : _StartCard(onTap: () => _openSetup(context));
                final recent = _RecentSessions(
                  history: history,
                  onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FocusHistoryPage(),
                    ),
                  ),
                );
                final content = Column(
                  children: [
                    startCard,
                    if (hasStats) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _StatsSummary(stats: stats),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    recent,
                  ],
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    96,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: content,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Pushes the Setup screen.
  void _openSetup(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FocusSetupPage()));
  }

  /// Pushes the Active screen for the session already running.
  void _openActive(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FocusActivePage()));
  }

  void _openReview(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FocusReviewPage()));
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.history, required this.onSeeAll});

  final AsyncValue<List<FocusSessionDetail>> history;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent sessions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
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
                    for (final detail in sessions.take(5))
                      _RecentSessionTile(detail: detail),
                  ],
                ),
        ),
      ],
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

    return AuroraPanel(
      padding: EdgeInsets.zero,
      borderColor: colors.primary.withValues(alpha: 0.32),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primary,
                  child: Icon(
                    Icons.play_arrow,
                    color: colors.onPrimary,
                    size: 34,
                  ),
                ),
              ),
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
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Icon(
                  Icons.chevron_right,
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

class _RestoringSessionCard extends StatelessWidget {
  const _RestoringSessionCard();

  @override
  Widget build(BuildContext context) {
    return const AuroraPanel(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.md),
          Text('Restoring your focus session…'),
        ],
      ),
    );
  }
}

/// The banner shown on Home while a session is already running.
class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.onTap, required this.reviewPending});

  final VoidCallback onTap;
  final bool reviewPending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AuroraPanel(
      padding: EdgeInsets.zero,
      borderColor: AppColors.flagGreen.withValues(alpha: 0.45),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Icon(
                  Icons.timelapse,
                  color: AppColors.flagGreen,
                  size: 34,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewPending
                          ? 'Review your session'
                          : 'Session in progress',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      reviewPending
                          ? 'Your focus time is safe. Finish the reflection when ready.'
                          : 'Tap to return to your running timer.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Icon(
                  Icons.chevron_right,
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

    final items = <Widget>[
      _MiniStat(
        icon: Icons.check_circle_outline,
        label: 'Sessions completed',
        value: '${stats.completedSessions}',
      ),
      _MiniStat(
        icon: Icons.timelapse_outlined,
        label: 'Total focus time',
        value: focusText,
      ),
      _MiniStat(
        icon: Icons.bolt_outlined,
        label: 'Distractions / session',
        value: stats.distractionsPerSession.toStringAsFixed(1),
      ),
    ];

    return AuroraPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All time',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      items[index],
                      if (index != items.length - 1)
                        _Separator(color: colors.outlineVariant),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    Expanded(child: items[index]),
                    if (index != items.length - 1)
                      SizedBox(
                        height: 70,
                        child: VerticalDivider(color: colors.outlineVariant),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A single statistic in the Home summary row.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.24),
            ),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      color: color.withValues(alpha: 0.6),
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

    final (statusLabel, statusColor) = switch (session.status) {
      FocusSessionStatus.completed => ('Completed', AppColors.flagGreen),
      FocusSessionStatus.abandoned => ('Abandoned', AppColors.flagRed),
      FocusSessionStatus.inProgress => ('In progress', AppColors.flagYellow),
      FocusSessionStatus.reviewPending => ('Review', AppColors.flagYellow),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '$focusText focused / ${relativeTime(session.startedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              session.cyclesCompleted == 0
                  ? '—'
                  : '${session.cyclesCompleted}×',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              statusLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                letterSpacing: 0.8,
              ),
            ),
          ],
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
    return AuroraPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Text(
          'No sessions yet. Start your first one above.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
