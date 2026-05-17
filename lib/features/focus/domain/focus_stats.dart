/// Pure Dart — no Flutter, no Drift.
library;

/// Descriptive aggregate statistics over a set of completed focus sessions.
///
/// Plain immutable data computed by [FocusStats.from]. Nothing here is
/// predictive — the History screen renders these as simple read-outs, in
/// keeping with the "descriptive aggregates only, no AI" design.
class FocusStats {
  /// Creates a stats bundle. Prefer [FocusStats.from].
  const FocusStats({
    required this.completedSessions,
    required this.totalFocus,
    required this.avgPreEnergy,
    required this.avgPostEnergy,
    required this.avgEnergyDelta,
    required this.totalDistractions,
    required this.internalDistractions,
    required this.externalDistractions,
    required this.distractionsPerSession,
  });

  /// An all-zero bundle, used before any session exists.
  static const FocusStats empty = FocusStats(
    completedSessions: 0,
    totalFocus: Duration.zero,
    avgPreEnergy: null,
    avgPostEnergy: null,
    avgEnergyDelta: null,
    totalDistractions: 0,
    internalDistractions: 0,
    externalDistractions: 0,
    distractionsPerSession: 0,
  );

  /// Number of sessions that count toward these aggregates.
  final int completedSessions;

  /// Summed focused work time across all counted sessions.
  final Duration totalFocus;

  /// Mean self-rated pre-session energy (1–5), or `null` with no data.
  final double? avgPreEnergy;

  /// Mean self-rated post-session energy (1–5), or `null` with no data.
  ///
  /// Averaged only over sessions that have a recorded post-energy value.
  final double? avgPostEnergy;

  /// Mean of `postEnergy - preEnergy` over sessions that recorded both, or
  /// `null` with no such session. Positive means study tended to leave the
  /// user more energised than they started.
  final double? avgEnergyDelta;

  /// Total distractions captured across all counted sessions.
  final int totalDistractions;

  /// Of [totalDistractions], how many were self-rated as internal.
  final int internalDistractions;

  /// Of [totalDistractions], how many were self-rated as external.
  final int externalDistractions;

  /// Mean distractions per counted session.
  final double distractionsPerSession;

  /// Aggregates a list of per-session inputs.
  ///
  /// Each entry supplies a session's focus seconds, energy ratings (post may
  /// be `null`), and its internal / external distraction counts. Sessions with
  /// no post-energy still count toward focus and distraction totals; they are
  /// simply excluded from the post-energy and delta means.
  factory FocusStats.from(List<FocusStatsInput> inputs) {
    if (inputs.isEmpty) return empty;

    var totalFocusSecs = 0;
    var preSum = 0;
    var postSum = 0;
    var postCount = 0;
    var deltaSum = 0;
    var deltaCount = 0;
    var internal = 0;
    var external = 0;

    for (final input in inputs) {
      totalFocusSecs += input.focusSecs;
      preSum += input.preEnergy;
      internal += input.internalDistractions;
      external += input.externalDistractions;

      final post = input.postEnergy;
      if (post != null) {
        postSum += post;
        postCount += 1;
        deltaSum += post - input.preEnergy;
        deltaCount += 1;
      }
    }

    final count = inputs.length;
    final totalDistractions = internal + external;

    return FocusStats(
      completedSessions: count,
      totalFocus: Duration(seconds: totalFocusSecs),
      avgPreEnergy: preSum / count,
      avgPostEnergy: postCount == 0 ? null : postSum / postCount,
      avgEnergyDelta: deltaCount == 0 ? null : deltaSum / deltaCount,
      totalDistractions: totalDistractions,
      internalDistractions: internal,
      externalDistractions: external,
      distractionsPerSession: totalDistractions / count,
    );
  }
}

/// One session's contribution to [FocusStats.from].
class FocusStatsInput {
  /// Creates a single session input.
  const FocusStatsInput({
    required this.focusSecs,
    required this.preEnergy,
    required this.postEnergy,
    required this.internalDistractions,
    required this.externalDistractions,
  });

  /// `actual_focus_secs` for the session.
  final int focusSecs;

  /// `pre_energy` (1–5) for the session.
  final int preEnergy;

  /// `post_energy` (1–5), or `null` if the session was never reviewed.
  final int? postEnergy;

  /// Count of internal distractions captured in the session.
  final int internalDistractions;

  /// Count of external distractions captured in the session.
  final int externalDistractions;
}
