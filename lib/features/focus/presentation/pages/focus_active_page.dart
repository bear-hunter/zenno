import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenno/canvas/canvas_editor_navigation.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/widgets/aurora.dart';
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
class FocusActivePage extends ConsumerStatefulWidget {
  /// Creates the active-session page.
  const FocusActivePage({super.key});

  @override
  ConsumerState<FocusActivePage> createState() => _FocusActivePageState();
}

class _FocusActivePageState extends ConsumerState<FocusActivePage> {
  _ActiveAction? _action;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionControllerProvider);
    final controller = ref.read(activeSessionControllerProvider.notifier);
    final snapshot = session.snapshot;
    final busy = _action != null;

    return PopScope<void>(
      canPop: !session.hasSession || session.reviewPending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmAbandon();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // No automatic back button: leaving is finish or abandon, never a
        // silent pop that would orphan the running session.
        body: Stack(
          children: [
            Positioned.fill(
              child: session.reviewPending
                  ? _ReviewPending(
                      onContinue: () => unawaited(
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const FocusReviewPage(),
                          ),
                        ),
                      ),
                    )
                  : snapshot == null
                  ? const _NoSession()
                  : _ActiveBody(
                      session: session,
                      snapshot: snapshot,
                      controller: controller,
                      action: _action,
                      onPause: () => _runTimerAction(
                        action: _ActiveAction.pause,
                        operation: controller.pause,
                        failureMessage:
                            'Could not pause the session. Please try again.',
                      ),
                      onResume: () => _runTimerAction(
                        action: _ActiveAction.resume,
                        operation: controller.resume,
                        failureMessage:
                            'Could not resume the session. Please try again.',
                      ),
                      onEndStretch: () => _runTimerAction(
                        action: _ActiveAction.endStretch,
                        operation: controller.endStretch,
                        failureMessage:
                            'Could not end the stretch. Please try again.',
                      ),
                      onSkipBreak: () => _runTimerAction(
                        action: _ActiveAction.skipBreak,
                        operation: controller.skipBreak,
                        failureMessage:
                            'Could not skip the break. Please try again.',
                      ),
                      onFinish: _finish,
                    ),
            ),
            if (session.hasSession && !session.reviewPending)
              Positioned(
                top: AppSpacing.xl,
                right: AppSpacing.xl,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : _confirmAbandon,
                  icon: _action == _ActiveAction.abandon
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.stop_circle_outlined),
                  label: Text(
                    _action == _ActiveAction.abandon ? 'Ending…' : 'End early',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _runTimerAction({
    required _ActiveAction action,
    required Future<void> Function() operation,
    required String failureMessage,
  }) async {
    if (_action != null) return;
    setState(() => _action = action);
    try {
      await operation();
    } catch (error) {
      debugPrint('$failureMessage: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    } finally {
      if (mounted) setState(() => _action = null);
    }
  }

  /// Finishes the session normally and moves to the Review screen.
  Future<void> _finish() async {
    if (_action != null) return;
    setState(() => _action = _ActiveAction.finish);
    final navigator = Navigator.of(context);
    try {
      await ref.read(activeSessionControllerProvider.notifier).stop();
    } catch (error) {
      debugPrint('Finish focus session failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not finish the session. Please try again.'),
          ),
        );
      }
      if (mounted) setState(() => _action = null);
      return;
    }
    if (!navigator.mounted) {
      if (mounted) setState(() => _action = null);
      return;
    }
    unawaited(
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const FocusReviewPage()),
      ),
    );
  }

  /// Confirms, then abandons the session and returns to Home.
  Future<void> _confirmAbandon() async {
    if (_action != null) return;
    setState(() => _action = _ActiveAction.abandon);
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
    if (confirmed != true) {
      if (mounted) setState(() => _action = null);
      return;
    }

    try {
      await ref
          .read(activeSessionControllerProvider.notifier)
          .stop(status: FocusSessionStatus.abandoned);
    } catch (error) {
      debugPrint('Abandon focus session failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not end the session. Please try again.'),
          ),
        );
      }
      if (mounted) setState(() => _action = null);
      return;
    }
    if (!navigator.mounted) {
      if (mounted) setState(() => _action = null);
      return;
    }
    // Back to the Focus Home screen.
    navigator.popUntil((route) => route.isFirst);
  }
}

enum _ActiveAction { pause, resume, endStretch, skipBreak, finish, abandon }

String _durationLabel(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return hours == 0 ? '${duration.inMinutes}m' : '${hours}h ${minutes}m';
}

class _ReviewPending extends StatelessWidget {
  const _ReviewPending({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onContinue,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Continue session review'),
      ),
    );
  }
}

/// The live timer body.
class _ActiveBody extends StatelessWidget {
  const _ActiveBody({
    required this.session,
    required this.snapshot,
    required this.controller,
    required this.action,
    required this.onPause,
    required this.onResume,
    required this.onEndStretch,
    required this.onSkipBreak,
    required this.onFinish,
  });

  final ActiveSessionState session;
  final TimerSnapshot snapshot;
  final ActiveSessionController controller;
  final _ActiveAction? action;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEndStretch;
  final VoidCallback onSkipBreak;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = session.config?.goalText ?? '';
    final planned = session.config?.plannedDuration;
    final target = planned != null && planned > Duration.zero
        ? '${_durationLabel(planned)} target'
        : '';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            if (goal.isNotEmpty || target.isNotEmpty) ...[
              AuroraPill(
                label: goal.isEmpty
                    ? target
                    : target.isEmpty
                    ? goal
                    : '$goal • $target',
                icon: Icons.flag_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            TimerDisplay(snapshot: snapshot),
            const SizedBox(height: AppSpacing.xxl),
            _PrimaryControls(
              snapshot: snapshot,
              action: action,
              onPause: onPause,
              onResume: onResume,
              onEndStretch: onEndStretch,
              onSkipBreak: onSkipBreak,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (session.config?.linkedCanvasId != null) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: action == null
                    ? () => openCanvasEditor(
                        context,
                        session.config!.linkedCanvasId!,
                      )
                    : null,
                icon: const Icon(Icons.draw_outlined),
                label: const Text('Open canvas'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _SecondaryControls(
              controller: controller,
              action: action,
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
    required this.action,
    required this.onPause,
    required this.onResume,
    required this.onEndStretch,
    required this.onSkipBreak,
  });

  final TimerSnapshot snapshot;
  final _ActiveAction? action;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEndStretch;
  final VoidCallback onSkipBreak;

  @override
  Widget build(BuildContext context) {
    final running = snapshot.isRunning;
    final canToggle =
        snapshot.status == TimerStatus.running ||
        snapshot.status == TimerStatus.paused;
    final isBreak = snapshot.phase == TimerPhase.breakTime;
    final isFlowWork = snapshot.mode == TimerMode.flowmodoro && !isBreak;
    final hasPhaseAction = isBreak || isFlowWork;
    final busy = action != null;

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: busy || !canToggle
                ? null
                : (running ? onPause : onResume),
            icon:
                action == _ActiveAction.pause || action == _ActiveAction.resume
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(running ? Icons.pause : Icons.play_arrow),
            label: Text(running ? 'Pause' : 'Resume'),
          ),
        ),
        if (hasPhaseAction) ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              // Flowmodoro work ends manually; breaks may be skipped.
              onPressed: busy ? null : (isBreak ? onSkipBreak : onEndStretch),
              icon:
                  action == _ActiveAction.endStretch ||
                      action == _ActiveAction.skipBreak
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isBreak ? Icons.skip_next : Icons.coffee_outlined),
              label: Text(isBreak ? 'Skip break' : 'End stretch'),
            ),
          ),
        ],
      ],
    );
  }
}

/// The distraction-capture and finish actions.
class _SecondaryControls extends StatelessWidget {
  const _SecondaryControls({
    required this.controller,
    required this.action,
    required this.onFinish,
  });

  final ActiveSessionController controller;
  final _ActiveAction? action;
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
            onPressed: action == null
                ? () => _captureDistraction(context)
                : null,
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
            onPressed: action == null ? onFinish : null,
            icon: action == _ActiveAction.finish
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.flag_outlined),
            label: Text(
              action == _ActiveAction.finish ? 'Finishing…' : 'Finish',
            ),
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
    try {
      await controller.captureDistraction(
        kind: capture.kind,
        note: capture.note,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Distraction logged')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not log distraction. Please try again.'),
        ),
      );
    }
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
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to Focus'),
          ),
        ],
      ),
    );
  }
}
