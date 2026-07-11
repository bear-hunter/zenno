import 'package:drift/drift.dart';

import 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart'
    as platform_connection;

/// Opens the SQLite database backing [ZennoDatabase].
///
/// Native platforms use the app-support directory. Web uses sqlite3 wasm with
/// the browser's IndexedDB-backed virtual filesystem.
QueryExecutor openZennoConnection() => platform_connection.openConnection();
