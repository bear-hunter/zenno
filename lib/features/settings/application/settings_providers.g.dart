// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [SettingsRepository], wired to the app database.

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

/// Provides the singleton [SettingsRepository], wired to the app database.

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  /// Provides the singleton [SettingsRepository], wired to the app database.
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'f8919cf5d3b492008fa9588828dac2c732fe2e55';

/// Streams the app settings, re-emitting whenever any setting is saved.
///
/// Safe as a codegen provider: [SettingsModel] is a hand-written class, so
/// riverpod_generator never sees Drift's generated row type in the signature.

@ProviderFor(appSettings)
final appSettingsProvider = AppSettingsProvider._();

/// Streams the app settings, re-emitting whenever any setting is saved.
///
/// Safe as a codegen provider: [SettingsModel] is a hand-written class, so
/// riverpod_generator never sees Drift's generated row type in the signature.

final class AppSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SettingsModel>,
          SettingsModel,
          Stream<SettingsModel>
        >
    with $FutureModifier<SettingsModel>, $StreamProvider<SettingsModel> {
  /// Streams the app settings, re-emitting whenever any setting is saved.
  ///
  /// Safe as a codegen provider: [SettingsModel] is a hand-written class, so
  /// riverpod_generator never sees Drift's generated row type in the signature.
  AppSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingsHash();

  @$internal
  @override
  $StreamProviderElement<SettingsModel> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SettingsModel> create(Ref ref) {
    return appSettings(ref);
  }
}

String _$appSettingsHash() => r'8382f95c7928883cbaf5db60b0455b4c199cce3f';
