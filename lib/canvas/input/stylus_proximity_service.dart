import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// App-wide Android stylus proximity state.
///
/// Flutter currently forwards Android stylus hover movement but not the native
/// hover-exit action. [MainActivity] bridges that missing enter/exit state over
/// this channel so touch rejection cannot remain stuck after the pen leaves.
class StylusProximityService extends ChangeNotifier {
  StylusProximityService._() {
    _channel.setMethodCallHandler(_handleMethodCall);
    unawaited(_readInitialState());
  }

  static final StylusProximityService instance = StylusProximityService._();

  static const MethodChannel _channel = MethodChannel(
    'com.bearhunter.zenno/stylus_proximity',
  );

  bool _isInProximity = false;

  bool get isInProximity => _isInProximity;

  Future<void> _readInitialState() async {
    try {
      final value = await _channel.invokeMethod<bool>('getStylusProximity');
      if (value != null) _setInProximity(value);
    } on MissingPluginException {
      // Non-Android platforms keep using Flutter pointer enter/exit events.
    } on PlatformException catch (error) {
      debugPrint('Could not read stylus proximity: $error');
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'stylusProximityChanged') {
      _setInProximity(call.arguments == true);
    }
  }

  void _setInProximity(bool value) {
    if (_isInProximity == value) return;
    _isInProximity = value;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetInProximity(bool value) => _setInProximity(value);
}
