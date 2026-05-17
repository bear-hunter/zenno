// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_setup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the Focus Setup screen's draft state and assembles a
/// [FocusSessionConfig] from it.
///
/// Seeds itself from the `app_settings` singleton; each mutator swaps in a
/// fresh [FocusSetupState] so watching widgets rebuild. It performs no DB
/// writes — `ActiveSessionController.startFrom` persists the opening session
/// row once the user taps "Start".

@ProviderFor(FocusSetupController)
final focusSetupControllerProvider = FocusSetupControllerProvider._();

/// Owns the Focus Setup screen's draft state and assembles a
/// [FocusSessionConfig] from it.
///
/// Seeds itself from the `app_settings` singleton; each mutator swaps in a
/// fresh [FocusSetupState] so watching widgets rebuild. It performs no DB
/// writes — `ActiveSessionController.startFrom` persists the opening session
/// row once the user taps "Start".
final class FocusSetupControllerProvider
    extends $NotifierProvider<FocusSetupController, FocusSetupState> {
  /// Owns the Focus Setup screen's draft state and assembles a
  /// [FocusSessionConfig] from it.
  ///
  /// Seeds itself from the `app_settings` singleton; each mutator swaps in a
  /// fresh [FocusSetupState] so watching widgets rebuild. It performs no DB
  /// writes — `ActiveSessionController.startFrom` persists the opening session
  /// row once the user taps "Start".
  FocusSetupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusSetupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusSetupControllerHash();

  @$internal
  @override
  FocusSetupController create() => FocusSetupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FocusSetupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FocusSetupState>(value),
    );
  }
}

String _$focusSetupControllerHash() =>
    r'f0481cfa48e3690787d2609bf98a359969531441';

/// Owns the Focus Setup screen's draft state and assembles a
/// [FocusSessionConfig] from it.
///
/// Seeds itself from the `app_settings` singleton; each mutator swaps in a
/// fresh [FocusSetupState] so watching widgets rebuild. It performs no DB
/// writes — `ActiveSessionController.startFrom` persists the opening session
/// row once the user taps "Start".

abstract class _$FocusSetupController extends $Notifier<FocusSetupState> {
  FocusSetupState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FocusSetupState, FocusSetupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FocusSetupState, FocusSetupState>,
              FocusSetupState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
