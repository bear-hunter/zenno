import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/goal_cycle/application/reflection_providers.dart';
import 'package:zenno/features/goal_cycle/data/reflection_repository.dart';
import 'package:zenno/features/goal_cycle/domain/reflection_template_schema.dart';
import 'package:zenno/features/goal_cycle/presentation/widgets/reflection_form.dart';

/// Opens the reflection editor for goal card [cardId] via `Navigator.push`.
///
/// With no [existingEntry] it creates a new reflection — the user first picks
/// a framework, then fills it in. With an [existingEntry] it edits that saved
/// reflection: the snapshotted schema is fixed and only the answers change.
Future<void> openReflectionEditor(
  BuildContext context, {
  required String cardId,
  ReflectionEntryView? existingEntry,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReflectionEditorPage(
        cardId: cardId,
        existingEntry: existingEntry,
      ),
    ),
  );
}

/// Creates or edits a single reflection on a goal card.
///
/// **New reflection** — picks a builtin/custom template from the live
/// templates list, then renders its prompts as a [ReflectionForm]. Saving
/// snapshots the chosen template's name and schema onto the entry.
///
/// **Editing** — the entry's frozen snapshot schema is shown and only the
/// answers are editable; the snapshot itself never changes.
class ReflectionEditorPage extends ConsumerStatefulWidget {
  /// Creates the reflection editor.
  const ReflectionEditorPage({
    required this.cardId,
    this.existingEntry,
    super.key,
  });

  /// Goal card the reflection belongs to.
  final String cardId;

  /// The reflection being edited, or `null` to create a new one.
  final ReflectionEntryView? existingEntry;

  @override
  ConsumerState<ReflectionEditorPage> createState() =>
      _ReflectionEditorPageState();
}

class _ReflectionEditorPageState
    extends ConsumerState<ReflectionEditorPage> {
  /// The template chosen for a new reflection. Always `null` when editing
  /// (the snapshot is used instead).
  ReflectionTemplateView? _selectedTemplate;

  /// The current answers, keyed by prompt key. Seeded from the existing entry.
  late Map<String, String> _answers;

  /// True while a save write is in flight.
  bool _saving = false;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _answers = Map<String, String>.from(
      widget.existingEntry?.answers ?? const {},
    );
  }

  /// The schema currently driving the form: the chosen template's, or the
  /// edited entry's frozen snapshot.
  ReflectionTemplateSchema? get _activeSchema {
    if (_isEditing) return widget.existingEntry!.schema;
    return _selectedTemplate?.schema;
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final repository = ref.read(reflectionRepositoryProvider);
      if (_isEditing) {
        await repository.updateEntry(
          widget.existingEntry!.id,
          answers: _answers,
        );
      } else {
        await repository.addEntry(
          cardId: widget.cardId,
          template: _selectedTemplate!,
          answers: _answers,
        );
      }
      navigator.pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save reflection: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schema = _activeSchema;
    // Save is possible only once a schema is in play (a template is chosen,
    // or we are editing) and at least one answer has been entered.
    final canSave = schema != null && _answers.isNotEmpty && !_saving;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit reflection' : 'New reflection'),
        actions: [
          TextButton.icon(
            onPressed: canSave ? _save : null,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (_isEditing)
                _SnapshotHeader(name: widget.existingEntry!.templateName)
              else
                _TemplatePicker(
                  selected: _selectedTemplate,
                  onChanged: (template) {
                    setState(() => _selectedTemplate = template);
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              if (schema != null)
                ReflectionForm(
                  // Re-key so the form rebuilds its fields when the template
                  // selection changes.
                  key: ValueKey(
                    _isEditing
                        ? 'entry-${widget.existingEntry!.id}'
                        : 'template-${_selectedTemplate?.id}',
                  ),
                  schema: schema,
                  initialAnswers: _answers,
                  onChanged: (answers) => _answers = answers,
                )
              else
                const _ChooseTemplatePrompt(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A read-only header naming the framework of the reflection being edited.
class _SnapshotHeader extends StatelessWidget {
  const _SnapshotHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Framework: $name',
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dropdown that picks the framework for a new reflection.
class _TemplatePicker extends ConsumerWidget {
  const _TemplatePicker({required this.selected, required this.onChanged});

  final ReflectionTemplateView? selected;
  final ValueChanged<ReflectionTemplateView?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(reflectionTemplatesProvider);

    return templatesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(
        'Could not load templates: $error',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      data: (templates) {
        if (templates.isEmpty) {
          return Text(
            'No reflection templates available.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Framework', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: selected?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a reflective framework',
              ),
              items: [
                for (final template in templates)
                  DropdownMenuItem(
                    value: template.id,
                    child: Text(
                      template.isBuiltin
                          ? '${template.name}  ·  builtin'
                          : template.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id == null) {
                  onChanged(null);
                  return;
                }
                onChanged(
                  templates.firstWhere((t) => t.id == id),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// The placeholder shown before a framework has been chosen.
class _ChooseTemplatePrompt extends StatelessWidget {
  const _ChooseTemplatePrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Choose a framework to begin',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
