import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/focus/data/focus_repository.dart';
import 'package:zenno/features/focus/data/ritual_repository.dart';

part 'focus_providers.g.dart';

/// The application-wide [FocusRepository].
///
/// `keepAlive` so it shares the single [ZennoDatabase] connection for the whole
/// session rather than reopening per screen.
@Riverpod(keepAlive: true)
FocusRepository focusRepository(Ref ref) {
  return FocusRepository(ref.watch(databaseProvider));
}

/// The application-wide [RitualRepository].
///
/// `keepAlive` for the same reason as [focusRepository].
@Riverpod(keepAlive: true)
RitualRepository ritualRepository(Ref ref) {
  return RitualRepository(ref.watch(databaseProvider));
}

/// The active items of the default pre-study ritual checklist.
///
/// A thin reactive wrapper over [RitualRepository.watchActiveItems] — adding,
/// editing or retiring an item anywhere updates every screen watching this.
// Plain (non-codegen) provider — riverpod_generator cannot resolve Drift's
// generated `RitualChecklistItem` row class inside a `@riverpod` signature.
final ritualItemsProvider = StreamProvider<List<RitualChecklistItem>>((ref) {
  return ref.watch(ritualRepositoryProvider).watchActiveItems();
});

/// The singleton `app_settings` row, exposed so the Setup screen can pre-fill
/// the Pomodoro / Flowmodoro / session-length defaults.
// Plain (non-codegen) provider — see [ritualItemsProvider].
final focusSettingsProvider = StreamProvider<AppSetting>((ref) {
  return ref.watch(ritualRepositoryProvider).watchSettings();
});

/// The full focus-session history, most recent first, each joined with its
/// distractions and ritual-check snapshot.
@riverpod
Stream<List<FocusSessionDetail>> focusHistory(Ref ref) {
  return ref.watch(focusRepositoryProvider).watchHistoryDetails();
}
