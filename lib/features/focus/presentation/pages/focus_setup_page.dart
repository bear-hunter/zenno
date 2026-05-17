import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/database.dart' hide RitualChecklist;
import 'package:zenno/features/focus/application/active_session_controller.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/application/focus_setup_controller.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';
import 'package:zenno/features/focus/presentation/pages/focus_active_page.dart';
import 'package:zenno/features/focus/presentation/widgets/energy_rating_selector.dart';
import 'package:zenno/features/focus/presentation/widgets/ritual_checklist.dart';
import 'package:zenno/features/focus/presentation/widgets/timer_type_picker.dart';
import 'package:zenno/features/library/application/library_providers.dart';
import 'package:zenno/shared/canvas_attachments/canvas_picker_dialog.dart';

/// The Focus Setup screen.
///
/// Walks the user through the pre-study ritual, a study goal, an energy rating,
/// the timing model and its settings, and the target session length. Tapping
/// "Start session" hands the assembled [FocusSetupController] config to
/// [ActiveSessionController] and pushes the [FocusActivePage].
class FocusSetupPage extends ConsumerWidget {
  /// Creates the setup page.
  const FocusSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(focusSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New focus session')),
      // The whole screen depends on the settings singleton for its defaults;
      // gate on it so the controller seeds from real values.
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Could not load settings.\n$error'),
          ),
        ),
        data: (_) => const _SetupBody(),
      ),
    );
  }
}

/// The setup form, shown once the settings singleton has loaded.
class _SetupBody extends ConsumerWidget {
  const _SetupBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(focusSetupControllerProvider);
    final controller = ref.read(focusSetupControllerProvider.notifier);
    final ritualItems = ref.watch(ritualItemsProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              // --- Ritual -----------------------------------------------
              const _SectionTitle('Pre-study ritual'),
              ritualItems.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: LinearProgressIndicator(),
                ),
                error: (error, _) => Text('Could not load ritual: $error'),
                data: (items) => RitualChecklist(
                  items: items,
                  checkedItemIds: setup.checkedItemIds,
                  editable: false,
                  onToggle: controller.toggleRitualItem,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Goal -------------------------------------------------
              const _SectionTitle('What are you studying?'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'e.g. Cardiology — heart failure',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: controller.setGoalText,
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Energy -----------------------------------------------
              const _SectionTitle('How is your energy?'),
              const SizedBox(height: AppSpacing.md),
              EnergyRatingSelector(
                value: setup.preEnergy,
                onChanged: controller.setPreEnergy,
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Timer type -------------------------------------------
              const _SectionTitle('Timing'),
              const SizedBox(height: AppSpacing.md),
              TimerTypePicker(value: setup.mode, onChanged: controller.setMode),
              const SizedBox(height: AppSpacing.lg),
              if (setup.mode == TimerMode.pomodoro)
                _PomodoroSettings(setup: setup, controller: controller)
              else
                _FlowmodoroSettings(setup: setup, controller: controller),
              const SizedBox(height: AppSpacing.xl),

              // --- Session length ---------------------------------------
              const _SectionTitle('Target session length'),
              const SizedBox(height: AppSpacing.sm),
              _DurationStepper(
                label: 'Session',
                value: setup.plannedDuration,
                step: const Duration(minutes: 10),
                onChanged: controller.setPlannedDuration,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // --- Working canvas --------------------------------------
              const _SectionTitle('Working canvas'),
              const SizedBox(height: AppSpacing.sm),
              _FocusCanvasRow(setup: setup, controller: controller),
              const SizedBox(height: AppSpacing.xxl),

              // --- Start ------------------------------------------------
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => _start(context, ref),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the session config + ritual snapshot and starts the session.
  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final setup = ref.read(focusSetupControllerProvider);
    final config = setup.toConfig();

    // Snapshot the ritual exactly as it stands now — label and checked flag.
    final items = ref.read(ritualItemsProvider).value ?? const [];
    final ritualSnapshot = [
      for (final RitualChecklistItem item in items)
        (
          itemId: item.id,
          label: item.label,
          wasChecked: setup.checkedItemIds.contains(item.id),
        ),
    ];

    final navigator = Navigator.of(context);
    await ref
        .read(activeSessionControllerProvider.notifier)
        .startFrom(config, checkedRitualItems: ritualSnapshot);

    if (!navigator.mounted) return;
    // Replace Setup with Active so a back press from Active returns to Home.
    await navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const FocusActivePage()),
    );
  }
}

class _FocusCanvasRow extends ConsumerWidget {
  const _FocusCanvasRow({required this.setup, required this.controller});

  final FocusSetupState setup;
  final FocusSetupController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canvasId = setup.linkedCanvasId;
    final canvases = ref.watch(canvasListProvider).value ?? const <Canvase>[];
    final selected = canvasId == null
        ? null
        : canvases.where((canvas) => canvas.id == canvasId).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.draw_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              selected?.title ??
                  (canvasId == null ? 'No canvas linked' : 'Linked canvas'),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (canvasId != null)
            IconButton(
              tooltip: 'Clear canvas',
              onPressed: controller.clearLinkedCanvas,
              icon: const Icon(Icons.close),
            ),
          TextButton.icon(
            onPressed: () => _chooseCanvas(context, ref),
            icon: Icon(canvasId == null ? Icons.add : Icons.swap_horiz),
            label: Text(canvasId == null ? 'Add' : 'Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseCanvas(BuildContext context, WidgetRef ref) async {
    final defaultTitle = setup.goalText.trim().isEmpty
        ? 'Focus canvas'
        : setup.goalText.trim();
    final result = await showCanvasPickerDialog(
      context,
      defaultTitle: defaultTitle,
    );
    if (result == null) return;
    switch (result) {
      case ExistingCanvasPicked(:final canvasId):
        controller.setLinkedCanvas(canvasId);
      case NewCanvasPicked(:final title):
        final id = await ref
            .read(libraryRepositoryProvider)
            .createCanvas(title: title);
        controller.setLinkedCanvas(id);
    }
  }
}

/// The editable Pomodoro work / break interval controls.
class _PomodoroSettings extends StatelessWidget {
  const _PomodoroSettings({required this.setup, required this.controller});

  final FocusSetupState setup;
  final FocusSetupController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DurationStepper(
          label: 'Work',
          value: setup.pomodoroWork,
          step: const Duration(minutes: 5),
          onChanged: controller.setPomodoroWork,
        ),
        const SizedBox(height: AppSpacing.sm),
        _DurationStepper(
          label: 'Break',
          value: setup.pomodoroBreak,
          step: const Duration(minutes: 1),
          onChanged: controller.setPomodoroBreak,
        ),
      ],
    );
  }
}

/// The editable Flowmodoro break-ratio control.
class _FlowmodoroSettings extends StatelessWidget {
  const _FlowmodoroSettings({required this.setup, required this.controller});

  final FocusSetupState setup;
  final FocusSetupController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (setup.flowBreakRatio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Break ratio', style: theme.textTheme.bodyLarge),
            ),
            Text(
              '$percent% of focus time',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(
          value: setup.flowBreakRatio,
          min: 0.05,
          max: 0.5,
          divisions: 9,
          label: '$percent%',
          onChanged: controller.setFlowBreakRatio,
        ),
        Text(
          'A 50-minute stretch earns a '
          '${(50 * setup.flowBreakRatio).round()}-minute break '
          '(clamped to 2–30 min).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A labelled minus / value / plus duration stepper.
class _DurationStepper extends StatelessWidget {
  const _DurationStepper({
    required this.label,
    required this.value,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final Duration value;
  final Duration step;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          IconButton.outlined(
            tooltip: 'Decrease',
            onPressed: () => onChanged(value - step),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 88,
            child: Text(
              '${value.inMinutes} min',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton.outlined(
            tooltip: 'Increase',
            onPressed: () => onChanged(value + step),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// A small section heading used throughout the setup form.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}
