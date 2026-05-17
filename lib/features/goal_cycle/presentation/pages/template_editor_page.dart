import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/util/id.dart';
import 'package:zenno/features/goal_cycle/application/reflection_providers.dart';
import 'package:zenno/features/goal_cycle/domain/reflection_template_schema.dart';

/// Builds a new reflection template or edits/views an existing one.
///
/// - **No [templateId]** — a blank new custom template.
/// - **[templateId] of a custom template** — edits it.
/// - **[templateId] of a builtin** — opens read-only (builtins are view-only;
///   the user duplicates one from the Templates page to customise it).
///
/// The editor manages an ordered list of prompts; on save the list is encoded
/// to a [ReflectionTemplateSchema] and persisted as the template's
/// `schema_json`. Pushed via `Navigator.push`.
class TemplateEditorPage extends ConsumerStatefulWidget {
  /// Creates the editor. With no [templateId] it starts a blank template.
  const TemplateEditorPage({this.templateId, super.key});

  /// Id of the template to load, or `null` to create a new one.
  final String? templateId;

  @override
  ConsumerState<TemplateEditorPage> createState() =>
      _TemplateEditorPageState();
}

class _TemplateEditorPageState extends ConsumerState<TemplateEditorPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// The working prompt list. Each row keeps its own stable [_PromptDraft.id]
  /// so reorders and deletes don't churn the [ReorderableListView] children.
  final List<_PromptDraft> _prompts = [];

  /// True until an existing template has finished loading.
  bool _loading = true;

  /// True when editing a builtin — the whole form is read-only.
  bool _readOnly = false;

  /// True while a save write is in flight.
  bool _saving = false;

  /// Whether this is a brand-new template (no [TemplateEditorPage.templateId]).
  bool get _isNew => widget.templateId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final prompt in _prompts) {
      prompt.dispose();
    }
    super.dispose();
  }

  /// Loads an existing template, or sets up a blank one.
  Future<void> _load() async {
    final id = widget.templateId;
    if (id == null) {
      // New template: start with one empty prompt to anchor the editor.
      setState(() {
        _prompts.add(_PromptDraft.empty());
        _loading = false;
      });
      return;
    }

    final template = await ref
        .read(reflectionRepositoryProvider)
        .templateById(id);
    if (!mounted) return;

    if (template == null) {
      // Deleted out from under us — bounce back.
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _readOnly = template.isBuiltin;
      _nameController.text = template.name;
      _descriptionController.text = template.description ?? '';
      _prompts
        ..clear()
        ..addAll([
          for (final prompt in template.schema.prompts)
            _PromptDraft.fromPrompt(prompt),
        ]);
      if (_prompts.isEmpty && !_readOnly) {
        _prompts.add(_PromptDraft.empty());
      }
      _loading = false;
    });
  }

  void _addPrompt() {
    setState(() => _prompts.add(_PromptDraft.empty()));
  }

  void _removePrompt(_PromptDraft prompt) {
    setState(() {
      _prompts.remove(prompt);
      prompt.dispose();
    });
  }

  void _reorderPrompt(int oldIndex, int newIndex) {
    setState(() {
      // ReorderableListView reports newIndex shifted by one past oldIndex.
      final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final moved = _prompts.removeAt(oldIndex);
      _prompts.insert(target, moved);
    });
  }

  /// Builds the [ReflectionTemplateSchema] from the current prompt drafts.
  ///
  /// Empty-label prompts are dropped. Each prompt keeps a stable key: an
  /// existing one is preserved; a new one gets a slug of its label, made
  /// unique within the schema, falling back to a generated id.
  ReflectionTemplateSchema _buildSchema() {
    final used = <String>{};
    final prompts = <ReflectionPrompt>[];
    for (final draft in _prompts) {
      final label = draft.labelController.text.trim();
      if (label.isEmpty) continue;
      prompts.add(
        ReflectionPrompt(
          key: _uniqueKey(draft, label, used),
          label: label,
          hint: draft.hintController.text.trim(),
          multiline: draft.multiline,
        ),
      );
    }
    return ReflectionTemplateSchema(prompts: prompts);
  }

  /// Resolves a stable, schema-unique key for [draft].
  String _uniqueKey(_PromptDraft draft, String label, Set<String> used) {
    var key = draft.existingKey ?? _slugify(label);
    if (key.isEmpty) key = newId();
    var candidate = key;
    var suffix = 2;
    while (!used.add(candidate)) {
      candidate = '${key}_$suffix';
      suffix++;
    }
    return candidate;
  }

  /// Lower-cases [label] and replaces non-alphanumeric runs with underscores.
  String _slugify(String label) {
    return label
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp('^_+|_+\$'), '');
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('Give the template a name.');
      return;
    }
    final schema = _buildSchema();
    if (schema.isEmpty) {
      _toast('Add at least one prompt.');
      return;
    }

    final navigator = Navigator.of(context);
    final description = _descriptionController.text.trim();
    setState(() => _saving = true);
    try {
      final repository = ref.read(reflectionRepositoryProvider);
      if (_isNew) {
        await repository.createTemplate(
          name: name,
          description: description.isEmpty ? null : description,
          schema: schema,
        );
      } else {
        await repository.updateTemplate(
          widget.templateId!,
          name: name,
          description: description.isEmpty ? null : description,
          schema: schema,
        );
      }
      navigator.pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Could not save: $error');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _readOnly
        ? 'Template'
        : _isNew
        ? 'New template'
        : 'Edit template';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!_readOnly && !_loading)
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.contentMaxWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (_readOnly) ...[
                      const _ReadOnlyBanner(),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // --- Identity --------------------------------------------
                    TextField(
                      controller: _nameController,
                      readOnly: _readOnly,
                      textCapitalization: TextCapitalization.words,
                      style: theme.textTheme.titleMedium,
                      decoration: const InputDecoration(
                        labelText: 'Template name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _descriptionController,
                      readOnly: _readOnly,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    Text('Prompts', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _readOnly
                          ? 'The questions this framework asks, in order.'
                          : 'Add the questions this framework asks. Drag '
                                'the handle to reorder.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // --- Prompt list -----------------------------------------
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: _reorderPrompt,
                      children: [
                        for (var i = 0; i < _prompts.length; i++)
                          _PromptEditorRow(
                            key: ValueKey(_prompts[i].id),
                            index: i,
                            draft: _prompts[i],
                            readOnly: _readOnly,
                            onRemove: _prompts.length > 1
                                ? () => _removePrompt(_prompts[i])
                                : null,
                            onMultilineChanged: (value) => setState(
                              () => _prompts[i].multiline = value,
                            ),
                          ),
                      ],
                    ),

                    if (!_readOnly) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _addPrompt,
                        icon: const Icon(Icons.add),
                        label: const Text('Add prompt'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

/// The mutable per-prompt editing state, with a stable identity.
class _PromptDraft {
  _PromptDraft({
    required this.id,
    required this.existingKey,
    required String label,
    required String hint,
    required this.multiline,
  }) : labelController = TextEditingController(text: label),
       hintController = TextEditingController(text: hint);

  /// A blank prompt for a fresh editor row.
  factory _PromptDraft.empty() => _PromptDraft(
    id: newId(),
    existingKey: null,
    label: '',
    hint: '',
    multiline: true,
  );

  /// A draft seeded from an existing [prompt], preserving its key.
  factory _PromptDraft.fromPrompt(ReflectionPrompt prompt) => _PromptDraft(
    id: newId(),
    existingKey: prompt.key,
    label: prompt.label,
    hint: prompt.hint,
    multiline: prompt.multiline,
  );

  /// Stable widget identity for [ReorderableListView] keys.
  final String id;

  /// The prompt's persisted key if it came from an existing template, else
  /// `null` (a fresh key is slugified on save).
  final String? existingKey;

  final TextEditingController labelController;
  final TextEditingController hintController;

  /// Whether the answer field should be multi-line.
  bool multiline;

  void dispose() {
    labelController.dispose();
    hintController.dispose();
  }
}

/// One editable prompt row inside the editor's reordering list.
class _PromptEditorRow extends StatelessWidget {
  const _PromptEditorRow({
    required this.index,
    required this.draft,
    required this.readOnly,
    required this.onMultilineChanged,
    this.onRemove,
    super.key,
  });

  final int index;
  final _PromptDraft draft;
  final bool readOnly;
  final ValueChanged<bool> onMultilineChanged;

  /// Removes this row, or `null` when it is the last remaining prompt.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (!readOnly)
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_indicator,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (!readOnly) const SizedBox(width: AppSpacing.sm),
                Text(
                  'Prompt ${index + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (!readOnly && onRemove != null)
                  IconButton(
                    tooltip: 'Remove prompt',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: draft.labelController,
              readOnly: readOnly,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Question / label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: draft.hintController,
              readOnly: readOnly,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Hint',
                hintText: 'Optional placeholder text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Multi-line answer'),
              subtitle: const Text('A larger text area for long responses'),
              value: draft.multiline,
              onChanged: readOnly ? null : onMultilineChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// The banner shown above a builtin template explaining it is read-only.
class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'This is a builtin framework and cannot be edited. Use '
              '"Duplicate & edit" to make your own version.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
