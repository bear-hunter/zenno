import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenno/canvas/canvas_editor_navigation.dart';
import 'package:zenno/config/theme/app_colors.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/database.dart' hide RitualChecklist;
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/widgets/app_dialog.dart';
import 'package:zenno/features/focus/application/active_session_controller.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/data/ritual_repository.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';
import 'package:zenno/features/focus/presentation/widgets/energy_rating_selector.dart';
import 'package:zenno/features/focus/presentation/widgets/ritual_checklist.dart';

/// The Focus Review screen, shown once a session has finished.
///
/// Collects the post-session energy rating, lets the user review the captured
/// distractions, tidy the ritual checklist for next time, and add an optional
/// note. "Save & finish" persists the review via [ActiveSessionController] and
/// returns to the Focus Home screen.
class FocusReviewPage extends ConsumerStatefulWidget {
  /// Creates the review page.
  const FocusReviewPage({super.key});

  @override
  ConsumerState<FocusReviewPage> createState() => _FocusReviewPageState();
}

class _FocusReviewPageState extends ConsumerState<FocusReviewPage> {
  final TextEditingController _noteController = TextEditingController();
  int _postEnergy = 3;
  bool _saving = false;
  bool _discarding = false;
  bool _allowPop = false;
  bool _discardDialogOpen = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionControllerProvider);
    final ritualItems = ref.watch(ritualItemsProvider);
    final ritualController = ref.read(ritualRepositoryProvider);
    final snapshot = session.snapshot;
    final sessionId = session.sessionId;

    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving && !_discarding) _confirmDiscardReview();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Session review'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentMaxWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  if (snapshot != null) _Summary(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle('How is your energy now?'),
                  const SizedBox(height: AppSpacing.md),
                  EnergyRatingSelector(
                    value: _postEnergy,
                    onChanged: (value) => setState(() => _postEnergy = value),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle('Distractions'),
                  const SizedBox(height: AppSpacing.sm),
                  if (sessionId != null)
                    _DistractionReview(sessionId: sessionId),
                  const SizedBox(height: AppSpacing.xl),
                  if (session.config?.linkedCanvasId != null) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => openCanvasEditor(
                        context,
                        session.config!.linkedCanvasId!,
                      ),
                      icon: const Icon(Icons.draw_outlined),
                      label: const Text('Open canvas'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  const _SectionTitle('Tidy your ritual for next time'),
                  const SizedBox(height: AppSpacing.sm),
                  ritualItems.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) {
                      debugPrint('Load ritual failed: $error');
                      return Text(
                        'Could not load ritual. Please try again.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    },
                    data: (items) => RitualChecklist(
                      items: items,
                      checkedItemIds: const <String>{},
                      onToggle: null,
                      onEdit: (id, label) => _guard(
                        ritualController.editItem(id, label),
                        failureMessage:
                            'Could not rename ritual item. Please try again.',
                      ),
                      onRetire: (id) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Retire ritual item?'),
                            content: const Text(
                              'This removes it from future rituals. Past sessions keep their snapshot.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Retire'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        await _guard(
                          ritualController.retireItem(id),
                          failureMessage:
                              'Could not retire ritual item. Please try again.',
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addRitualItem(ritualController),
                      icon: const Icon(Icons.add),
                      label: const Text('Add ritual item'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle('Session note'),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'How did it go? Anything to remember?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: _saving || _discarding
                        ? null
                        : () => _save(context),
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Saving…' : 'Save & finish'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows an add-item dialog and appends a new ritual item.
  Future<void> _addRitualItem(RitualRepository ritualController) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add ritual item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Label'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = label?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await _guard(
        ritualController.addItem(trimmed),
        failureMessage: 'Could not add ritual item. Please try again.',
      );
    }
  }

  /// Persists the review and returns to the Focus Home screen.
  Future<void> _save(BuildContext context) async {
    if (_saving || _discarding) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(activeSessionControllerProvider.notifier)
          .submitReview(postEnergy: _postEnergy, notes: _noteController.text);
      _allowPop = true;
      if (!navigator.mounted) return;
      navigator.popUntil((route) => route.isFirst);
    } catch (error) {
      debugPrint('Save focus review failed: $error');
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not save review. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDiscardReview() async {
    if (_saving || _discarding || _discardDialogOpen) return;
    _discardDialogOpen = true;
    final discard = await confirmDiscardChanges(context);
    _discardDialogOpen = false;
    if (!discard || !mounted) return;
    setState(() => _discarding = true);
    try {
      await ref.read(activeSessionControllerProvider.notifier).discard();
    } catch (error) {
      debugPrint('Discard focus review failed: $error');
      if (mounted) {
        setState(() => _discarding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not discard the review. Please try again.'),
          ),
        );
      }
      return;
    }
    _allowPop = true;
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _guard(
    Future<void> future, {
    required String failureMessage,
  }) async {
    try {
      await future;
    } catch (error) {
      debugPrint('$failureMessage: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}

/// A compact summary of the just-finished session.
class _Summary extends StatelessWidget {
  const _Summary({required this.snapshot});

  final TimerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final focus = snapshot.accumulatedFocus;
    final hours = focus.inHours;
    final minutes = focus.inMinutes.remainder(60);
    final focusText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.flagGreen, size: 32),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session complete', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$focusText focused  ·  '
                  '${snapshot.cyclesCompleted} '
                  '${snapshot.cyclesCompleted == 1 ? "cycle" : "cycles"}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A live list of the distractions captured during the session.
class _DistractionReview extends ConsumerWidget {
  const _DistractionReview({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.watch(focusRepositoryProvider);

    return StreamBuilder<List<Distraction>>(
      stream: repo.watchDistractions(sessionId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Load distractions failed: ${snapshot.error}');
          return Text(
            'Could not load distractions. Please try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        final distractions = snapshot.data ?? const <Distraction>[];
        if (distractions.isEmpty) {
          return Text(
            'No distractions captured — nice focus.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Column(
          children: [
            for (final distraction in distractions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  distraction.kind == DistractionKind.internal
                      ? Icons.psychology_outlined
                      : Icons.notifications_active_outlined,
                ),
                title: Text(
                  distraction.note.isEmpty
                      ? (distraction.kind == DistractionKind.internal
                            ? 'Internal distraction'
                            : 'External distraction')
                      : distraction.note,
                ),
                subtitle: Text(
                  '${_mmss(distraction.elapsedSecs)} into the session',
                ),
              ),
          ],
        );
      },
    );
  }

  /// Formats a second count as `m:ss`.
  String _mmss(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// A small section heading reused across the review form.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}
