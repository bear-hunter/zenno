import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/features/goal_cycle/application/goal_providers.dart';
import 'package:zenno/features/goal_cycle/application/reflection_providers.dart';
import 'package:zenno/features/goal_cycle/data/goal_repository.dart';
import 'package:zenno/features/goal_cycle/data/reflection_repository.dart';
import 'package:zenno/features/goal_cycle/domain/reflection_template_schema.dart';
import 'package:zenno/features/goal_cycle/presentation/pages/reflection_editor_page.dart';
import 'package:zenno/features/goal_cycle/presentation/pages/template_editor_page.dart';
import 'package:zenno/features/goal_cycle/presentation/pages/templates_page.dart';
import 'package:zenno/features/goal_cycle/presentation/widgets/goal_card_detail_sheet.dart';
import 'package:zenno/features/goal_cycle/presentation/widgets/goal_card_tile.dart';
import 'package:zenno/shared/canvas_attachments/card_canvas_attachment_providers.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

void main() {
  testWidgets('goal detail guards dirty exit and duplicate failed saves', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final controller = _RecordingGoalController(db);
    final updateGate = Completer<void>();
    controller.nextUpdate = updateGate;
    await _openGoalSheet(tester, controller);

    await tester.enterText(find.byType(TextField).first, 'Changed goal');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    final save = find.text('Save');
    await tester.ensureVisible(save);
    final savePosition = tester.getCenter(save);
    await tester.tapAt(savePosition);
    await tester.pump();
    await tester.tapAt(savePosition);
    await tester.pump();

    expect(controller.updateCalls, 1);
    expect(controller.statusCalls, 0);
    expect(find.text('Saving…'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Discard changes?'), findsNothing);

    updateGate.completeError(StateError('write failed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Could not save the goal. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'switching reflection templates confirms before clearing answers',
    (tester) async {
      final db = ZennoDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = _RecordingReflectionRepository(
        db,
        templates: const [_firstTemplate, _secondTemplate],
      );
      await _pumpReflectionEditor(tester, repository);

      await _chooseTemplate(tester, 'First framework');
      await tester.enterText(find.byType(TextField), 'Answer from first');
      await _chooseTemplate(tester, 'Second framework');

      expect(find.text('Change framework?'), findsOneWidget);
      await tester.tap(find.text('Keep writing'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Answer from first',
      );

      await _chooseTemplate(tester, 'Second framework');
      await tester.tap(find.text('Change framework'));
      await tester.pumpAndSettle();

      final answerField = tester.widget<TextField>(find.byType(TextField));
      expect(answerField.controller!.text, isEmpty);

      await tester.enterText(find.byType(TextField), 'Answer from second');
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pump();

      expect(repository.addCalls, 1);
      expect(repository.addedAnswers, {'second': 'Answer from second'});
    },
  );

  testWidgets('existing reflection can save empty answers without back race', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingReflectionRepository(db);
    final updateGate = Completer<void>();
    repository.nextEntryUpdate = updateGate;
    await _pumpReflectionEditor(
      tester,
      repository,
      existingEntry: _existingEntry,
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    expect(repository.entryUpdateCalls, 1);
    expect(repository.updatedAnswers, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Discard changes?'), findsNothing);

    updateGate.completeError(StateError('write failed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Could not save reflection. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('template editor guards dirty exit and duplicate failed saves', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingReflectionRepository(
      db,
      templates: const [_firstTemplate],
    );
    final updateGate = Completer<void>();
    repository.nextTemplateUpdate = updateGate;
    await _pumpTemplateEditor(tester, repository);

    await tester.enterText(find.byType(TextField).first, 'Renamed framework');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(TextButton, 'Save');
    final savePosition = tester.getCenter(save);
    await tester.tapAt(savePosition);
    await tester.pump();
    await tester.tapAt(savePosition);
    await tester.pump();

    expect(repository.templateUpdateCalls, 1);
    expect(find.text('Saving…'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Discard changes?'), findsNothing);

    updateGate.completeError(StateError('write failed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Could not save:'), findsOneWidget);
  });

  testWidgets('template load failure offers a working retry', (tester) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingReflectionRepository(
      db,
      templates: const [_firstTemplate],
    )..nextTemplateLoadError = StateError('read failed');
    await _pumpTemplateEditor(tester, repository);

    expect(find.text('Could not load this template.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('First framework'), findsOneWidget);
    expect(repository.templateLoadCalls, 2);
  });

  testWidgets('goal cards prioritize current status and flag overdue dates', (
    tester,
  ) async {
    final card = KanbanCardData(
      id: 'goal-overdue',
      columnId: 'column-1',
      position: 1,
      title: 'Prepare review',
      subtitle: 'Long-term summary',
      payload: GoalCardExtra(
        targetDate: DateTime.now().subtract(const Duration(days: 3)),
        statusNote: 'Draft the first section',
        reflectionCount: 2,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GoalCardTile(card: card)),
      ),
    );

    expect(find.text('Draft the first section'), findsOneWidget);
    expect(find.text('Long-term summary'), findsNothing);
    expect(find.textContaining('overdue'), findsOneWidget);
  });

  testWidgets(
    'template delete dialog states the actual reference restriction',
    (tester) async {
      final db = ZennoDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = _RecordingReflectionRepository(
        db,
        templates: const [_firstTemplate],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reflectionRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: TemplatesPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Template actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'A template can only be deleted when no saved reflections use it.',
        ),
        findsOneWidget,
      );
    },
  );
}

Future<void> _openGoalSheet(
  WidgetTester tester,
  _RecordingGoalController controller,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        goalBoardControllerProvider.overrideWithValue(controller),
        cardReflectionsProvider(
          _goalCard.id,
        ).overrideWith((ref) => Stream.value(const [])),
        cardCanvasAttachmentsProvider(
          _goalCard.id,
        ).overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showGoalCardDetailSheet(context, card: _goalCard),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _pumpReflectionEditor(
  WidgetTester tester,
  _RecordingReflectionRepository repository, {
  ReflectionEntryView? existingEntry,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reflectionRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: ReflectionEditorPage(
          cardId: 'card-1',
          existingEntry: existingEntry,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _chooseTemplate(WidgetTester tester, String name) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _pumpTemplateEditor(
  WidgetTester tester,
  _RecordingReflectionRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reflectionRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
        home: TemplateEditorPage(templateId: 'template-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _firstTemplate = ReflectionTemplateView(
  id: 'template-1',
  name: 'First framework',
  description: 'First description',
  isBuiltin: false,
  schema: ReflectionTemplateSchema(
    prompts: [ReflectionPrompt(key: 'first', label: 'First question')],
  ),
  position: 1,
);

const _secondTemplate = ReflectionTemplateView(
  id: 'template-2',
  name: 'Second framework',
  description: 'Second description',
  isBuiltin: false,
  schema: ReflectionTemplateSchema(
    prompts: [ReflectionPrompt(key: 'second', label: 'Second question')],
  ),
  position: 2,
);

final _existingEntry = ReflectionEntryView(
  id: 'entry-1',
  cardId: 'card-1',
  templateId: _firstTemplate.id,
  templateName: _firstTemplate.name,
  schema: _firstTemplate.schema,
  answers: const {'first': 'Existing answer'},
  createdAt: DateTime.utc(2026, 7, 10),
  updatedAt: DateTime.utc(2026, 7, 10),
);

const _goalCard = KanbanCardData(
  id: 'goal-1',
  columnId: 'column-1',
  position: 1,
  title: 'Original goal',
  subtitle: 'Original summary',
  payload: GoalCardExtra(
    targetDate: null,
    statusNote: 'Original status',
    reflectionCount: 0,
  ),
);

class _RecordingGoalController extends GoalBoardController {
  _RecordingGoalController(ZennoDatabase db) : super(GoalRepository(db));

  int updateCalls = 0;
  int statusCalls = 0;
  Completer<void>? nextUpdate;

  @override
  Future<void> saveCard({
    required String cardId,
    required String title,
    required String? subtitle,
    required String? statusNote,
    required DateTime? targetDate,
  }) {
    updateCalls += 1;
    final gate = nextUpdate;
    nextUpdate = null;
    return gate?.future ?? Future.value();
  }

  @override
  Future<void> setStatusNote({required String cardId, required String? note}) {
    statusCalls += 1;
    return Future.value();
  }
}

class _RecordingReflectionRepository extends ReflectionRepository {
  _RecordingReflectionRepository(super.db, {this.templates = const []});

  final List<ReflectionTemplateView> templates;
  int addCalls = 0;
  int entryUpdateCalls = 0;
  int templateUpdateCalls = 0;
  int templateLoadCalls = 0;
  Map<String, String>? addedAnswers;
  Map<String, String>? updatedAnswers;
  Completer<void>? nextEntryUpdate;
  Completer<void>? nextTemplateUpdate;
  Object? nextTemplateLoadError;

  @override
  Stream<List<ReflectionTemplateView>> watchTemplates() {
    return Stream.value(templates);
  }

  @override
  Future<ReflectionTemplateView?> templateById(String id) async {
    templateLoadCalls += 1;
    final error = nextTemplateLoadError;
    nextTemplateLoadError = null;
    if (error != null) throw error;
    return templates.where((template) => template.id == id).firstOrNull;
  }

  @override
  Future<String> addEntry({
    required String cardId,
    required ReflectionTemplateView template,
    required Map<String, String> answers,
  }) async {
    addCalls += 1;
    addedAnswers = Map.of(answers);
    return 'entry-$addCalls';
  }

  @override
  Future<void> updateEntry(
    String entryId, {
    required Map<String, String> answers,
  }) {
    entryUpdateCalls += 1;
    updatedAnswers = Map.of(answers);
    final gate = nextEntryUpdate;
    nextEntryUpdate = null;
    return gate?.future ?? Future.value();
  }

  @override
  Future<void> updateTemplate(
    String id, {
    required String name,
    String? description,
    required ReflectionTemplateSchema schema,
  }) {
    templateUpdateCalls += 1;
    final gate = nextTemplateUpdate;
    nextTemplateUpdate = null;
    return gate?.future ?? Future.value();
  }
}
