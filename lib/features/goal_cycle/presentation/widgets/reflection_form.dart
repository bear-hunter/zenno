import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/goal_cycle/domain/reflection_template_schema.dart';

/// Renders a [ReflectionTemplateSchema] as one labelled text field per prompt
/// and reports edits back through [onChanged].
///
/// The form is feature-agnostic: it works for any template (builtin or
/// custom). Prompts flagged [ReflectionPrompt.multiline] become multi-line
/// fields; others stay single-line. It owns one [TextEditingController] per
/// prompt, seeded from [initialAnswers] (used when *editing* an existing
/// reflection), and notifies [onChanged] with the full `{promptKey: text}` map
/// on every keystroke so a parent can keep a draft / enable a Save button.
class ReflectionForm extends StatefulWidget {
  /// Creates a reflection form for [schema].
  const ReflectionForm({
    required this.schema,
    required this.onChanged,
    this.initialAnswers = const {},
    super.key,
  });

  /// The ordered prompt list to render.
  final ReflectionTemplateSchema schema;

  /// Pre-filled answers keyed by [ReflectionPrompt.key] — empty for a new
  /// reflection, populated when editing one.
  final Map<String, String> initialAnswers;

  /// Called with the complete current answer map on every edit.
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<ReflectionForm> createState() => _ReflectionFormState();
}

class _ReflectionFormState extends State<ReflectionForm> {
  /// One controller per prompt key, in the schema's order.
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _buildControllers();
  }

  @override
  void didUpdateWidget(ReflectionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The schema can change if a parent swaps templates — rebuild controllers.
    if (oldWidget.schema != widget.schema) {
      _disposeControllers();
      _buildControllers();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _buildControllers() {
    for (final prompt in widget.schema.prompts) {
      final controller = TextEditingController(
        text: widget.initialAnswers[prompt.key] ?? '',
      );
      controller.addListener(_emitChange);
      _controllers[prompt.key] = controller;
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  /// Reports the current answers — only non-empty fields are included.
  void _emitChange() {
    widget.onChanged({
      for (final entry in _controllers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.schema.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'This template has no prompts.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final prompt in widget.schema.prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _PromptField(
              prompt: prompt,
              controller: _controllers[prompt.key]!,
            ),
          ),
      ],
    );
  }
}

/// One labelled answer field for a single [ReflectionPrompt].
class _PromptField extends StatelessWidget {
  const _PromptField({required this.prompt, required this.controller});

  final ReflectionPrompt prompt;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt.label, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: prompt.multiline
              ? TextInputType.multiline
              : TextInputType.text,
          minLines: prompt.multiline ? 3 : 1,
          maxLines: prompt.multiline ? 8 : 1,
          decoration: InputDecoration(
            hintText: prompt.hint.isEmpty ? null : prompt.hint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
