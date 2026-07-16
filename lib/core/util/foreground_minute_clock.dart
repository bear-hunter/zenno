import 'dart:async';

import 'package:flutter/widgets.dart';

/// A minute-resolution clock that stops waking the app in the background.
///
/// Ticks are aligned to wall-clock minute boundaries so multiple consumers can
/// be coalesced by the platform instead of each drifting on its own schedule.
class ForegroundMinuteClock extends ChangeNotifier with WidgetsBindingObserver {
  ForegroundMinuteClock({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      _now = (clock ?? DateTime.now)() {
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    if (_isForeground) _scheduleNextTick();
  }

  final DateTime Function() _clock;
  DateTime _now;
  Timer? _timer;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  DateTime get now => _now;

  bool get _isForeground => _lifecycleState == AppLifecycleState.resumed;

  @visibleForTesting
  bool get debugTimerActive => _timer?.isActive ?? false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isForeground;
    _lifecycleState = state;
    if (wasForeground == _isForeground) return;

    if (_isForeground) {
      _now = _clock();
      notifyListeners();
      _scheduleNextTick();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    final current = _clock();
    final elapsedInMinute = Duration(
      seconds: current.second,
      milliseconds: current.millisecond,
      microseconds: current.microsecond,
    );
    _timer = Timer(const Duration(minutes: 1) - elapsedInMinute, _tick);
  }

  void _tick() {
    _now = _clock();
    notifyListeners();
    if (_isForeground) _scheduleNextTick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
