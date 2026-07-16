import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/util/foreground_minute_clock.dart';

void main() {
  testWidgets('minute clock sleeps in background and refreshes on resume', (
    tester,
  ) async {
    var now = DateTime(2026, 7, 17, 9, 10, 30);
    final clock = ForegroundMinuteClock(clock: () => now);
    try {
      expect(clock.debugTimerActive, isTrue);
      clock.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(clock.debugTimerActive, isFalse);

      now = DateTime(2026, 7, 17, 9, 15);
      clock.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(clock.now, now);
      expect(clock.debugTimerActive, isTrue);
    } finally {
      clock.dispose();
    }
  });
}
