import 'package:uuid/uuid.dart';

/// Generates a new unique identifier for a domain entity.
///
/// Uses UUID **v7**: the leading bits are a Unix-millisecond timestamp, so IDs
/// are roughly time-sortable. That property is relied on across Zenno — it
/// gives stable, naturally-ordered primary keys for drag-reorder and keeps a
/// future export/sync path simple.
String newId() => const Uuid().v7();
