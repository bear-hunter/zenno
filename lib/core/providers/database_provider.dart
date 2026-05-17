import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenno/core/database/database.dart';

part 'database_provider.g.dart';

/// The application-wide [ZennoDatabase] instance.
///
/// `keepAlive` so the single SQLite connection lives for the whole app
/// session; it is closed when the owning [ProviderContainer] is disposed.
@Riverpod(keepAlive: true)
ZennoDatabase database(Ref ref) {
  final db = ZennoDatabase();
  ref.onDispose(db.close);
  return db;
}
