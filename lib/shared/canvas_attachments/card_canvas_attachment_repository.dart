import 'package:drift/drift.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/util/id.dart';
import 'package:zenno/features/library/data/library_repository.dart';

/// A canvas attached to a revision or goal card, with the card-specific label.
class CardCanvasAttachmentView {
  /// Creates an attachment view.
  const CardCanvasAttachmentView({
    required this.id,
    required this.cardId,
    required this.canvasId,
    required this.canvasTitle,
    required this.label,
    required this.position,
    required this.createdAt,
  });

  final String id;
  final String cardId;
  final String canvasId;
  final String canvasTitle;
  final String label;
  final double position;
  final DateTime createdAt;
}

/// Drift-backed attachment API shared by revision and goal cards.
class CardCanvasAttachmentRepository {
  /// Creates a repository over [_db].
  const CardCanvasAttachmentRepository(this._db, this._libraryRepository);

  final ZennoDatabase _db;
  final LibraryRepository _libraryRepository;

  /// Watches canvases attached to [cardId], ordered by attachment position.
  Stream<List<CardCanvasAttachmentView>> watchForCard(String cardId) {
    final query =
        _db.select(_db.cardCanvasAttachments).join([
            innerJoin(
              _db.canvases,
              _db.canvases.id.equalsExp(_db.cardCanvasAttachments.canvasId),
            ),
          ])
          ..where(_db.cardCanvasAttachments.cardId.equals(cardId))
          ..orderBy([OrderingTerm.asc(_db.cardCanvasAttachments.position)]);

    return query.watch().map((rows) {
      return [
        for (final row in rows)
          _toView(
            row.readTable(_db.cardCanvasAttachments),
            row.readTable(_db.canvases),
          ),
      ];
    });
  }

  /// Attaches an existing [canvasId] to [cardId].
  Future<String> attachExisting({
    required String cardId,
    required String canvasId,
    String? label,
  }) async {
    final canvas = await (_db.select(
      _db.canvases,
    )..where((c) => c.id.equals(canvasId))).getSingle();
    return _insertAttachment(
      cardId: cardId,
      canvasId: canvasId,
      label: _cleanLabel(label) ?? canvas.title,
    );
  }

  /// Creates a normal library canvas and attaches it to [cardId].
  Future<String> createAndAttach({
    required String cardId,
    required String title,
    String? label,
  }) async {
    final canvasTitle = title.trim().isEmpty ? 'Untitled' : title.trim();
    final canvasId = await _libraryRepository.createCanvas(title: canvasTitle);
    await _insertAttachment(
      cardId: cardId,
      canvasId: canvasId,
      label: _cleanLabel(label) ?? canvasTitle,
    );
    return canvasId;
  }

  /// Renames only the attachment label, leaving the canvas title untouched.
  Future<void> renameLabel({
    required String attachmentId,
    required String label,
  }) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return (_db.update(_db.cardCanvasAttachments)
          ..where((a) => a.id.equals(attachmentId)))
        .write(CardCanvasAttachmentsCompanion(label: Value(trimmed)));
  }

  /// Detaches a canvas from its card without deleting the canvas.
  Future<void> detach(String attachmentId) {
    return (_db.delete(
      _db.cardCanvasAttachments,
    )..where((a) => a.id.equals(attachmentId))).go();
  }

  Future<String> _insertAttachment({
    required String cardId,
    required String canvasId,
    required String label,
  }) async {
    final id = newId();
    final position = await _nextPosition(cardId);
    await _db
        .into(_db.cardCanvasAttachments)
        .insert(
          CardCanvasAttachmentsCompanion.insert(
            id: id,
            cardId: cardId,
            canvasId: canvasId,
            label: label,
            position: position,
            createdAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return id;
  }

  Future<double> _nextPosition(String cardId) async {
    final latest =
        await (_db.select(_db.cardCanvasAttachments)
              ..where((a) => a.cardId.equals(cardId))
              ..orderBy([(a) => OrderingTerm.desc(a.position)])
              ..limit(1))
            .getSingleOrNull();
    return (latest?.position ?? 0) + 1000;
  }

  CardCanvasAttachmentView _toView(
    CardCanvasAttachment attachment,
    Canvase canvas,
  ) {
    return CardCanvasAttachmentView(
      id: attachment.id,
      cardId: attachment.cardId,
      canvasId: attachment.canvasId,
      canvasTitle: canvas.title,
      label: attachment.label,
      position: attachment.position,
      createdAt: attachment.createdAt,
    );
  }

  String? _cleanLabel(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
