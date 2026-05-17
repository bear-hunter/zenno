import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/goal_cycle/data/reflection_repository.dart';

part 'reflection_providers.g.dart';

/// The [ReflectionRepository], bound to the app-wide [ZennoDatabase].
@riverpod
ReflectionRepository reflectionRepository(Ref ref) {
  return ReflectionRepository(ref.watch(databaseProvider));
}

/// Every reflection template (builtin + custom) as a reactive stream.
///
/// `@riverpod`-safe: [ReflectionTemplateView] is a hand-written model class,
/// not a Drift row type, so it may legally appear in a codegen signature. A
/// create/update/delete/duplicate through [ReflectionRepository] re-emits here
/// and rebuilds the Templates page.
@riverpod
Stream<List<ReflectionTemplateView>> reflectionTemplates(Ref ref) {
  return ref.watch(reflectionRepositoryProvider).watchTemplates();
}

/// The reflection entries on a single goal card, as a reactive stream.
///
/// A `family` provider keyed by `cardId`: the goal-card detail sheet watches
/// `cardReflectionsProvider(card.id)`. Adding, editing or deleting a
/// reflection re-emits here. `@riverpod`-safe — [ReflectionEntryView] is a
/// hand-written model class.
@riverpod
Stream<List<ReflectionEntryView>> cardReflections(Ref ref, String cardId) {
  return ref.watch(reflectionRepositoryProvider).watchEntriesForCard(cardId);
}
