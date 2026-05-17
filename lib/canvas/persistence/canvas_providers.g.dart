// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [CanvasRepository], wired to the app database.
///
/// One repository instance is shared across canvases — it is stateless apart
/// from the `ZennoDatabase` handle, and a canvas editor scopes every call by
/// `canvasId`. The codegen is safe here: [CanvasRepository] only ever exposes
/// hand-written `CanvasElement` engine types across its API, never a
/// Drift-generated row class, so `riverpod_generator` resolves the signature
/// (a Drift row class in a `@riverpod` return position throws at build time).

@ProviderFor(canvasRepository)
final canvasRepositoryProvider = CanvasRepositoryProvider._();

/// Provides the singleton [CanvasRepository], wired to the app database.
///
/// One repository instance is shared across canvases — it is stateless apart
/// from the `ZennoDatabase` handle, and a canvas editor scopes every call by
/// `canvasId`. The codegen is safe here: [CanvasRepository] only ever exposes
/// hand-written `CanvasElement` engine types across its API, never a
/// Drift-generated row class, so `riverpod_generator` resolves the signature
/// (a Drift row class in a `@riverpod` return position throws at build time).

final class CanvasRepositoryProvider
    extends
        $FunctionalProvider<
          CanvasRepository,
          CanvasRepository,
          CanvasRepository
        >
    with $Provider<CanvasRepository> {
  /// Provides the singleton [CanvasRepository], wired to the app database.
  ///
  /// One repository instance is shared across canvases — it is stateless apart
  /// from the `ZennoDatabase` handle, and a canvas editor scopes every call by
  /// `canvasId`. The codegen is safe here: [CanvasRepository] only ever exposes
  /// hand-written `CanvasElement` engine types across its API, never a
  /// Drift-generated row class, so `riverpod_generator` resolves the signature
  /// (a Drift row class in a `@riverpod` return position throws at build time).
  CanvasRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canvasRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canvasRepositoryHash();

  @$internal
  @override
  $ProviderElement<CanvasRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CanvasRepository create(Ref ref) {
    return canvasRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CanvasRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CanvasRepository>(value),
    );
  }
}

String _$canvasRepositoryHash() => r'0d26ecff107ed7d8040fbd74f5c200c5a0ab8d9b';
