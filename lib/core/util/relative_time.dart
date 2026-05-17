/// Formats [time] as a compact, human-readable string relative to [now]
/// (defaults to [DateTime.now]).
///
/// Output examples: `just now`, `5m ago`, `3h ago`, `13d ago`, `2w ago`,
/// `4mo ago`, `1y ago`.
///
/// Pure Dart — no `intl`, no I/O. Both timestamps are compared in absolute
/// terms via [DateTime.difference], so mixing UTC and local instants is safe.
/// Future timestamps (clock skew, or a value that simply hasn't happened yet)
/// are handled gracefully: anything within a minute ahead reads `just now`,
/// and anything further ahead is phrased with an `in ...` prefix
/// (e.g. `in 2h`).
String relativeTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final delta = reference.difference(time);

  // Future timestamp: phrase it forward instead of as "... ago".
  if (delta.isNegative) {
    final ahead = delta.abs();
    if (ahead.inSeconds < 60) return 'just now';
    return 'in ${_magnitude(ahead)}';
  }

  if (delta.inSeconds < 60) return 'just now';
  return '${_magnitude(delta)} ago';
}

/// Renders the size of a non-negative [d] as a compact unit string
/// (e.g. `5m`, `3h`, `2w`, `4mo`, `1y`) — without any directional wording.
///
/// Months are approximated as 30 days and years as 365 days; this is a
/// display-only heuristic and intentionally coarse.
String _magnitude(Duration d) {
  final minutes = d.inMinutes;
  if (minutes < 60) return '${minutes}m';

  final hours = d.inHours;
  if (hours < 24) return '${hours}h';

  final days = d.inDays;
  if (days < 7) return '${days}d';

  final weeks = days ~/ 7;
  if (days < 30) return '${weeks}w';

  final months = days ~/ 30;
  if (days < 365) return '${months}mo';

  final years = days ~/ 365;
  return '${years}y';
}
