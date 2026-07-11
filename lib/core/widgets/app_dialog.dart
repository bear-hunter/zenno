import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_spacing.dart';

/// Responsive dialog shell with the app's standard max width and padding.
class AppDialog extends StatelessWidget {
  const AppDialog({required this.child, this.maxWidth = 520, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: child,
        ),
      ),
    );
  }
}

Future<bool> confirmDiscardChanges(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discard changes?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'You have unsaved changes. If you leave now, they will be lost.',
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Keep editing'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
}
