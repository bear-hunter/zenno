import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/widgets/app_dialog.dart';
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
      builder: (_) =>
          ReflectionEditorPage(cardId: cardId, existingEntry: existingEntry),
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

class _ReflectionEditorPageState extends ConsumerState<ReflectionEditorPage> {
  /// The template chosen for a new reflection. Always `null` when editing
  /// (the snapshot is used instead).
  ReflectionTemplateView? _selectedTemplate;

  /// The current answers, keyed by prompt key. Seeded from the existing entry.
  late Map<String, String> _answers;

  /// True while a save write is in flight.
  bool _saving = false;
  bool _discarding = false;
  bool _allowPop = false;
  bool _discardDialogOpen = false;
  int _templatePickerRevision = 0;

  bool get _isEditing => widget.existingEntry != null;
  Map<String, String> get _initialAnswers =>
      widget.existingEntry?.answers ?? const {};
  bool get _dirty =>
      _selectedTemplate != null || !_mapsEqual(_answers, _initialAnswers);

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
    if (_saving || _discarding) return;
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
      _allowPop = true;
      if (navigator.mounted) navigator.pop();
    } on Object catch (error) {
      debugPrint('Reflection save failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save reflection. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schema = _activeSchema;
    // New reflections need at least one answer. Existing reflections may save
    // an empty map so clearing every answer is a valid edit.
    final canSave =
        schema != null &&
        (_isEditing || _answers.isNotEmpty) &&
        !_saving &&
        !_discarding;

    return PopScope<void>(
      canPop: _allowPop || (!_dirty && !_saving && !_discarding),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving && !_discarding) _confirmLeave();
      },
      child: Scaffold(
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
        body: AbsorbPointer(
          absorbing: _saving || _discarding,
          child: Center(
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
                      key: ValueKey(
                        'reflection-framework-'
                        '${_selectedTemplate?.id}-$_templatePickerRevision',
                      ),
                      selected: _selectedTemplate,
                      onChanged: _selectTemplate,
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
                      onChanged: (answers) =>
                          setState(() => _answers = answers),
                    )
                  else
                    const _ChooseTemplatePrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTemplate(ReflectionTemplateView? template) async {
    if (template?.id == _selectedTemplate?.id) return;
    if (_answers.isNotEmpty) {
      final change = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change framework?'),
          content: const Text(
            'Your answers belong to the current framework and will be cleared.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep writing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Change framework'),
            ),
          ],
        ),
      );
      if (change != true || !mounted) {
        if (mounted) setState(() => _templatePickerRevision += 1);
        return;
      }
    }
    setState(() {
      _selectedTemplate = template;
      // Answers belong to prompt keys in one schema. Never carry them into a
      // different template, even when two templates reuse the same key.
      _answers = <String, String>{};
    });
  }

  Future<void> _confirmLeave() async {
    if (_saving || _discarding || _discardDialogOpen) return;
    _discardDialogOpen = true;
    final discard = await confirmDiscardChanges(context);
    _discardDialogOpen = false;
    if (!discard || !mounted) return;
    setState(() {
      _discarding = true;
      _allowPop = true;
    });
    Navigator.of(context).pop();
  }

  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
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
          Icon(Icons.menu_book_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text('Framework: $name', style: theme.textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}

/// A dropdown that picks the framework for a new reflection.
class _TemplatePicker extends ConsumerWidget {
  const _TemplatePicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

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
                onChanged(templates.firstWhere((t) => t.id == id));
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
