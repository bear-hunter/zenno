// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_canvas_attachment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared repository for revision/goal card canvas attachments.

@ProviderFor(cardCanvasAttachmentRepository)
final cardCanvasAttachmentRepositoryProvider =
    CardCanvasAttachmentRepositoryProvider._();

/// Shared repository for revision/goal card canvas attachments.

final class CardCanvasAttachmentRepositoryProvider
    extends
        $FunctionalProvider<
          CardCanvasAttachmentRepository,
          CardCanvasAttachmentRepository,
          CardCanvasAttachmentRepository
        >
    with $Provider<CardCanvasAttachmentRepository> {
  /// Shared repository for revision/goal card canvas attachments.
  CardCanvasAttachmentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardCanvasAttachmentRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardCanvasAttachmentRepositoryHash();

  @$internal
  @override
  $ProviderElement<CardCanvasAttachmentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CardCanvasAttachmentRepository create(Ref ref) {
    return cardCanvasAttachmentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CardCanvasAttachmentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CardCanvasAttachmentRepository>(
        value,
      ),
    );
  }
}

String _$cardCanvasAttachmentRepositoryHash() =>
    r'6073991986f5448d4a9ead46133ccee8eb13d211';
