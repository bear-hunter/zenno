import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';
import 'package:zenno/core/database/web_database_lock.dart';

QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      await acquireWebDatabaseLock();
      final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
      final fileSystem = await IndexedDbFileSystem.open(dbName: 'zenno');
      sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);

      final database = WasmDatabase(
        sqlite3: sqlite,
        path: '/database',
        fileSystem: fileSystem,
      );
      return DatabaseConnection(database);
    }),
  );
}
