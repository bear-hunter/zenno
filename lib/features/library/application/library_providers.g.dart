// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [LibraryRepository], wired to the app database.

@ProviderFor(libraryRepository)
final libraryRepositoryProvider = LibraryRepositoryProvider._();

/// Provides the singleton [LibraryRepository], wired to the app database.

final class LibraryRepositoryProvider
    extends
        $FunctionalProvider<
          LibraryRepository,
          LibraryRepository,
          LibraryRepository
        >
    with $Provider<LibraryRepository> {
  /// Provides the singleton [LibraryRepository], wired to the app database.
  LibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryRepositoryProvider',
        isAutoDispose: true,
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

String _$libraryRepositoryHash() => r'42badf3dc5c0067ee1238048c53f0da663fd9d0d';

/// Holds the current [LibrarySort] for the library grid.
///
/// In-memory for now; a later phase persists the choice to
/// `app_settings.library_sort`. Defaults to [LibrarySort.recent].

@ProviderFor(LibrarySortNotifier)
final librarySortProvider = LibrarySortNotifierProvider._();

/// Holds the current [LibrarySort] for the library grid.
///
/// In-memory for now; a later phase persists the choice to
/// `app_settings.library_sort`. Defaults to [LibrarySort.recent].
final class LibrarySortNotifierProvider
    extends $NotifierProvider<LibrarySortNotifier, LibrarySort> {
  /// Holds the current [LibrarySort] for the library grid.
  ///
  /// In-memory for now; a later phase persists the choice to
  /// `app_settings.library_sort`. Defaults to [LibrarySort.recent].
  LibrarySortNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'librarySortProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$librarySortNotifierHash();

  @$internal
  @override
  LibrarySortNotifier create() => LibrarySortNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibrarySort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibrarySort>(value),
    );
  }
}

String _$librarySortNotifierHash() =>
    r'703a0121cdb591ba1763c6b8c8f6fbe8ad338b75';

/// Holds the current [LibrarySort] for the library grid.
///
/// In-memory for now; a later phase persists the choice to
/// `app_settings.library_sort`. Defaults to [LibrarySort.recent].

abstract class _$LibrarySortNotifier extends $Notifier<LibrarySort> {
  LibrarySort build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LibrarySort, LibrarySort>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LibrarySort, LibrarySort>,
              LibrarySort,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
