import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the on-device SQLite database backing [ZennoDatabase].
///
/// `driftDatabase` resolves a file named `zenno` in the platform's default
/// app-support directory and runs all queries on a background isolate.
QueryExecutor openZennoConnection() => driftDatabase(name: 'zenno');
