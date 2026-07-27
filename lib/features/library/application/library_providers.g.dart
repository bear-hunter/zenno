// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [LibraryRepository], wired to the app database.
///
/// Kept alive deliberately: this repository owns orphaned-file housekeeping,
/// and an autoDispose rebuild would re-run that scan every time the library
/// screen is re-entered.

@ProviderFor(libraryRepository)
final libraryRepositoryProvider = LibraryRepositoryProvider._();

/// Provides the singleton [LibraryRepository], wired to the app database.
///
/// Kept alive deliberately: this repository owns orphaned-file housekeeping,
/// and an autoDispose rebuild would re-run that scan every time the library
/// screen is re-entered.

final class LibraryRepositoryProvider
    extends
        $FunctionalProvider<
          LibraryRepository,
          LibraryRepository,
          LibraryRepository
        >
    with $Provider<LibraryRepository> {
  /// Provides the singleton [LibraryRepository], wired to the app database.
  ///
  /// Kept alive deliberately: this repository owns orphaned-file housekeeping,
  /// and an autoDispose rebuild would re-run that scan every time the library
  /// screen is re-entered.
  LibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<LibraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LibraryRepository create(Ref ref) {
    return libraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryRepository>(value),
    );
  }
}

String _$libraryRepositoryHash() => r'e93f1a20594d02648fb3da64fd15f596dad574a0';
