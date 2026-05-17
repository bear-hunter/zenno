import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/goal_cycle/application/reflection_providers.dart';
import 'package:zenno/features/goal_cycle/data/reflection_repository.dart';
import 'package:zenno/features/goal_cycle/presentation/pages/template_editor_page.dart';
import 'package:zenno/features/goal_cycle/presentation/widgets/template_tile.dart';

/// The reflection-template library.
///
/// Lists every framework grouped into **Builtin** (Kolb, Gibbs, ERA, Driscoll
/// — view-only) and **Custom** sections. Tapping a builtin opens it read-only;
/// tapping a custom opens the editor. "Duplicate & edit" forks any template
/// into an editable copy; the FAB creates a blank custom template.
///
/// Pushed from the Goal Cycle board's app bar via `Navigator.push`.
class TemplatesPage extends ConsumerWidget {
  /// Creates the templates page.
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(reflectionTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reflection templates')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTemplate(context),
        icon: const Icon(Icons.add),
        label: const Text('New template'),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _TemplatesError(error: error),
        data: (templates) => _TemplatesList(templates: templates),
      ),
    );
  }

  /// Opens the editor on a brand-new blank custom template.
  void _createTemplate(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TemplateEditorPage()));
  }
}

/// The two-section list of builtin and custom templates.
class _TemplatesList extends ConsumerWidget {
  const _TemplatesList({required this.templates});

  final List<ReflectionTemplateView> templates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builtins = [
      for (final t in templates)
        if (t.isBuiltin) t,
    ];
    final customs = [
      for (final t in templates)
        if (!t.isBuiltin) t,
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const _SectionHeader(
          title: 'Builtin frameworks',
          subtitle: 'Established reflective cycles — view-only.',
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final template in builtins)
          TemplateTile(
            template: template,
            onOpen: () => _open(context, template),
            onDuplicate: () => _duplicate(context, ref, template),
          ),

        const SizedBox(height: AppSpacing.xl),

        const _SectionHeader(
          title: 'Custom templates',
          subtitle: 'Frameworks you have built or duplicated.',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (customs.isEmpty)
          const _CustomEmpty()
        else
          for (final template in customs)
            TemplateTile(
              template: template,
              onOpen: () => _open(context, template),
              onDuplicate: () => _duplicate(context, ref, template),
              onDelete: () => _delete(context, ref, template),
            ),
      ],
    );
  }

  /// Opens a template in the editor — builtins land there read-only.
  void _open(BuildContext context, ReflectionTemplateView template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateEditorPage(templateId: template.id),
      ),
    );
  }

  /// Forks [template] into an editable copy and opens that copy in the editor.
  Future<void> _duplicate(
    BuildContext context,
    WidgetRef ref,
    ReflectionTemplateView template,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final newId = await ref
          .read(reflectionRepositoryProvider)
          .duplicateTemplate(template.id);
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => TemplateEditorPage(templateId: newId),
        ),
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not duplicate: $error')),
      );
    }
  }

  /// Deletes a custom [template] after confirmation.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ReflectionTemplateView template,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text(
          'Delete "${template.name}"? Saved reflections made from it keep '
          'their own copy and are unaffected. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    try {
      await ref.read(reflectionRepositoryProvider).deleteTemplate(template.id);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete: $error')),
      );
    }
  }
}

/// A titled section heading with a one-line description.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The empty-state shown when no custom templates exist yet.
class _CustomEmpty extends StatelessWidget {
  const _CustomEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        'No custom templates yet. Create one with the button below, or '
        'duplicate a builtin framework to start from.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Shown when the templates stream fails.
class _TemplatesError extends StatelessWidget {
  const _TemplatesError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load templates',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
