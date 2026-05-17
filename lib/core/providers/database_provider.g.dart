// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The application-wide [ZennoDatabase] instance.
///
/// `keepAlive` so the single SQLite connection lives for the whole app
/// session; it is closed when the owning [ProviderContainer] is disposed.

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// The application-wide [ZennoDatabase] instance.
///
/// `keepAlive` so the single SQLite connection lives for the whole app
/// session; it is closed when the owning [ProviderContainer] is disposed.

final class DatabaseProvider
    extends $FunctionalProvider<ZennoDatabase, ZennoDatabase, ZennoDatabase>
    with $Provider<ZennoDatabase> {
  /// The application-wide [ZennoDatabase] instance.
  ///
  /// `keepAlive` so the single SQLite connection lives for the whole app
  /// session; it is closed when the owning [ProviderContainer] is disposed.
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<ZennoDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ZennoDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ZennoDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ZennoDatabase>(value),
    );
  }
}

String _$databaseHash() => r'2d03a4e9f17b33b4cff278468dbf41d059320232';
