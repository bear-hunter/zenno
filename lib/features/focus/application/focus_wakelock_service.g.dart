// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_wakelock_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the platform wakelock boundary.

@ProviderFor(focusWakelockService)
final focusWakelockServiceProvider = FocusWakelockServiceProvider._();

/// Provides the platform wakelock boundary.

final class FocusWakelockServiceProvider
    extends
        $FunctionalProvider<
          FocusWakelockService,
          FocusWakelockService,
          FocusWakelockService
        >
    with $Provider<FocusWakelockService> {
  /// Provides the platform wakelock boundary.
  FocusWakelockServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusWakelockServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusWakelockServiceHash();

  @$internal
  @override
  $ProviderElement<FocusWakelockService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FocusWakelockService create(Ref ref) {
    return focusWakelockService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FocusWakelockService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FocusWakelockService>(value),
    );
  }
}

String _$focusWakelockServiceHash() =>
    r'71fc00fe54e21e6decbc4082181b49c8dbb0c5d8';
