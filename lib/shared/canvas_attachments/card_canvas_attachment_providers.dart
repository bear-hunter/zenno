import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/library/application/library_providers.dart';
import 'package:zenno/shared/canvas_attachments/card_canvas_attachment_repository.dart';

part 'card_canvas_attachment_providers.g.dart';

/// Shared repository for revision/goal card canvas attachments.
@riverpod
CardCanvasAttachmentRepository cardCanvasAttachmentRepository(Ref ref) {
  return CardCanvasAttachmentRepository(
    ref.watch(databaseProvider),
    ref.watch(libraryRepositoryProvider),
  );
}

/// Reactive attachment list for a single Kanban card.
final cardCanvasAttachmentsProvider =
    StreamProvider.family<List<CardCanvasAttachmentView>, String>((
      ref,
      cardId,
    ) {
      return ref
          .watch(cardCanvasAttachmentRepositoryProvider)
          .watchForCard(cardId);
    });
