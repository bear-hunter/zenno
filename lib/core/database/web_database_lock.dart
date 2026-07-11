import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:zenno/core/database/database_exceptions.dart';

final Completer<JSAny?> _databaseLifetime = Completer<JSAny?>();
Future<void>? _acquiring;

/// Holds one exclusive browser-wide lock for the lifetime of this tab.
///
/// Drift's direct IndexedDB-backed WASM connection is intentionally
/// single-client. A second tab fails before opening SQLite instead of risking
/// two independent database connections mutating the same file.
Future<void> acquireWebDatabaseLock() {
  return _acquiring ??= _acquireWebDatabaseLock();
}

Future<void> _acquireWebDatabaseLock() async {
  final acquired = Completer<void>();
  final options = web.LockOptions(mode: 'exclusive', ifAvailable: true);
  final request = web.window.navigator.locks.request(
    'zenno-drift-database',
    options,
    ((web.Lock? lock) {
      if (lock == null) {
        acquired.completeError(StateError(databaseAlreadyOpenMessage));
        return null;
      }
      acquired.complete();
      return _databaseLifetime.future.toJS;
    }).toJS,
  );
  unawaited(
    request.toDart.catchError((Object error) {
      if (!acquired.isCompleted) acquired.completeError(error);
      return null;
    }),
  );
  await acquired.future;
}
