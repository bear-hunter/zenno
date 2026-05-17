import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/core/providers/database_provider.dart';

part 'canvas_providers.g.dart';

/// Provides the singleton [CanvasRepository], wired to the app database.
///
/// One repository instance is shared across canvases — it is stateless apart
/// from the `ZennoDatabase` handle, and a canvas editor scopes every call by
/// `canvasId`. The codegen is safe here: [CanvasRepository] only ever exposes
/// hand-written `CanvasElement` engine types across its API, never a
/// Drift-generated row class, so `riverpod_generator` resolves the signature
/// (a Drift row class in a `@riverpod` return position throws at build time).
@riverpod
CanvasRepository canvasRepository(Ref ref) {
  return CanvasRepository(ref.watch(databaseProvider));
}
