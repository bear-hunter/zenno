import 'package:flutter/material.dart';
import 'package:zenno/config/theme/app_colors.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';

/// The large central timer read-out on the Active screen.
///
/// Renders a [TimerSnapshot]: a ring whose fill tracks phase progress, a big
/// `mm:ss` (or `h:mm:ss`) figure, a phase label and the cycle count. For a
/// fixed-length phase the figure **counts down** and the ring fills; for an
/// open-ended Flowmodoro work stretch the figure **counts up** and the ring
/// shows an indeterminate accent rim.
class TimerDisplay extends StatelessWidget {
  /// Creates a timer display for [snapshot].
  const TimerDisplay({required this.snapshot, super.key});

  /// The timer state to render.
  final TimerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isBreak = snapshot.phase == TimerPhase.breakTime;
    final isOpenEnded = snapshot.target == null;

    // Open-ended (Flowmodoro work) counts up; everything else counts down.
    final figure = isOpenEnded
        ? _format(snapshot.elapsed)
        : _format(snapshot.remaining);

    final accent = isBreak ? AppColors.flagGreen : colors.primary;
    final progress = _progress(snapshot);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PhaseChip(
          label: _phaseLabel(snapshot),
          color: accent,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  // Indeterminate-looking constant rim for an open-ended
                  // stretch; a real progress arc for a fixed phase.
                  value: isOpenEnded ? 1.0 : progress,
                  strokeWidth: 10,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOpenEnded
                        ? accent.withValues(alpha: 0.35)
                        : accent,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    figure,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isOpenEnded
                        ? 'elapsed'
                        : (isBreak ? 'break remaining' : 'work remaining'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          _cycleLine(snapshot),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Phase progress in `0..1`, or `0` for an open-ended stretch.
  double _progress(TimerSnapshot snapshot) {
    final target = snapshot.target;
    if (target == null || target.inMicroseconds == 0) return 0;
    final ratio =
        snapshot.elapsed.inMicroseconds / target.inMicroseconds;
    return ratio.clamp(0.0, 1.0);
  }

  /// The headline phase label, e.g. `Focus`, `Break`, `Paused`.
  String _phaseLabel(TimerSnapshot snapshot) {
    if (snapshot.isPaused) return 'Paused';
    if (snapshot.status == TimerStatus.finished) return 'Finished';
    if (snapshot.status == TimerStatus.abandoned) return 'Ended';
    return snapshot.phase == TimerPhase.breakTime ? 'Break' : 'Focus';
  }

  /// The cycle / focus summary line under the ring.
  String _cycleLine(TimerSnapshot snapshot) {
    final cycles = snapshot.cyclesCompleted;
    final focus = _format(snapshot.accumulatedFocus);
    final cycleWord = cycles == 1 ? 'cycle' : 'cycles';
    return '$cycles $cycleWord  ·  $focus focused';
  }
}

/// A small rounded label above the timer ring naming the current phase.
class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Formats [d] as `m:ss`, or `h:mm:ss` once it reaches an hour.
String _format(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  final hours = total.inHours;
  final minutes = total.inMinutes.remainder(60);
  final seconds = total.inSeconds.remainder(60);
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    final mm = minutes.toString().padLeft(2, '0');
    return '$hours:$mm:$ss';
  }
  return '$minutes:$ss';
}
