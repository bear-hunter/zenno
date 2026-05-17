import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'focus_wakelock_service.g.dart';

/// Platform wakelock boundary for Focus sessions.
class FocusWakelockService {
  /// Creates a wakelock service.
  const FocusWakelockService();

  /// Enables or disables the platform wakelock.
  Future<void> setEnabled(bool enabled) => WakelockPlus.toggle(enable: enabled);
}

/// Provides the platform wakelock boundary.
@Riverpod(keepAlive: true)
FocusWakelockService focusWakelockService(Ref ref) {
  return const FocusWakelockService();
}
