import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/features/focus/application/active_session_controller.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';
import 'package:zenno/features/focus/presentation/pages/focus_review_page.dart';
import 'package:zenno/features/focus/presentation/widgets/distraction_sheet.dart';
import 'package:zenno/features/focus/presentation/widgets/timer_display.dart';

/// The Focus Active screen — the live timer for an in-progress session.
///
/// Renders the [ActiveSessionController]'s [TimerSnapshot] via [TimerDisplay]
/// (countdown for Pomodoro, count-up for Flowmodoro), exposes pause / resume,
/// the phase-end action (skip break / end stretch), distraction capture and
/// finish. The controller is `keepAlive`, so the timer keeps running if the
/// user navigates away and back.
class FocusActivePage extends ConsumerWidget {
  /// Creates the active-session page.
  const FocusActivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionControllerProvider);
    final controller = ref.read(activeSessionControllerProvider.notifier);
    final snapshot = session.snapshot;

    return Scaffold(
      appBar: AppBar(
        // No automatic back button — leaving is finish or abandon, never a
        // silent pop that would orphan the running session.
        automaticallyImplyLeading: false,
        title: const Text('Focus session'),
        actions: [
          if (session.hasSession)
            TextButton(
              onPressed: () => _confirmAbandon(context, ref),
              child: const Text('End early'),
            ),
        ],
      ),
      body: SafeArea(
        child: snapshot == null
            ? const _NoSession()
            : _ActiveBody(
                session: session,
                snapshot: snapshot,
                controller: controller,
                onFinish: () => _finish(context, ref),
              ),
      ),
    );
  }

  /// Finishes the session normally and moves to the Review screen.
  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await ref.read(activeSessionControllerProvider.notifier).stop();
    if (!navigator.mounted) return;
    await navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const FocusReviewPage()),
    );
  }

  /// Confirms, then abandons the session and returns to Home.
  Future<void> _confirmAbandon(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End session early?'),
        content: const Text(
          'The session will be saved as abandoned. The focus time you have '
          'already done is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End session'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(activeSessionControllerProvider.notifier)
        .stop(status: FocusSessionStatus.abandoned);
    if (!navigator.mounted) return;
    // Back to the Focus Home screen.
    navigator.popUntil((route) => route.isFirst);
  }
}

/// The live timer body.
class _ActiveBody extends StatelessWidget {
  const _ActiveBody({
    required this.session,
    required this.snapshot,
    required this.controller,
    required this.onFinish,
  });

  final ActiveSessionState session;
  final TimerSnapshot snapshot;
  final ActiveSessionController controller;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = session.config?.goalText ?? '';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.contentMaxWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            if (goal.isNotEmpty) ...[
              Text(
                goal,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            TimerDisplay(snapshot: snapshot),
            const SizedBox(height: AppSpacing.xxl),
            _PrimaryControls(snapshot: snapshot, controller: controller),
            const SizedBox(height: AppSpacing.lg),
            _SecondaryControls(
              controller: controller,
              onFinish: onFinish,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pause / resume plus the phase-specific action button.
class _PrimaryControls extends StatelessWidget {
  const _PrimaryControls({
    required this.snapshot,
    required this.controller,
  });

  final TimerSnapshot snapshot;
  final ActiveSessionController controller;

  @override
  Widget build(BuildContext context) {
    final running = snapshot.isRunning;
    final isBreak = snapshot.phase == TimerPhase.breakTime;
    final isFlowWork =
        snapshot.mode == TimerMode.flowmodoro && !isBreak;

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: running ? controller.pause : controller.resume,
            icon: Icon(running ? Icons.pause : Icons.play_arrow),
            label: Text(running ? 'Pause' : 'Resume'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            // Flowmodoro work: end the open-ended stretch.
            // Break (either mode): skip to the next work phase.
            // Pomodoro work: nothing extra — it auto-advances on the timer.
            onPressed: isBreak
                ? controller.skipBreak
                : (isFlowWork ? controller.endStretch : null),
            icon: Icon(
              isBreak ? Icons.skip_next : Icons.coffee_outlined,
            ),
            label: Text(
              isBreak
                  ? 'Skip break'
                  : (isFlowWork ? 'End stretch' : 'Auto'),
            ),
          ),
        ),
      ],
    );
  }
}

/// The distraction-capture and finish actions.
class _SecondaryControls extends StatelessWidget {
  const _SecondaryControls({
    required this.controller,
    required this.onFinish,
  });

  final ActiveSessionController controller;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => _captureDistraction(context),
            icon: const Icon(Icons.bolt_outlined),
            label: const Text('Distraction'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: onFinish,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Finish'),
          ),
        ),
      ],
    );
  }

  /// Opens the capture sheet and records the result against the session.
  Future<void> _captureDistraction(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final capture = await DistractionSheet.show(context);
    if (capture == null) return;
    await controller.captureDistraction(
      kind: capture.kind,
      note: capture.note,
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Distraction logged')),
    );
  }
}

/// Shown if the page is opened with no session running (e.g. after a finish).
class _NoSession extends StatelessWidget {
  const _NoSession();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_off_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No active session', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to Focus'),
          ),
        ],
      ),
    );
  }
}
