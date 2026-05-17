import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';
import 'package:zenno/features/settings/data/settings_repository.dart';

/// The Settings screen.
///
/// A sectioned list of preference controls — appearance, Focus defaults and
/// library options. Every control reads from the reactive [appSettingsProvider]
/// stream and writes through the [SettingsRepository]; because the stream is
/// Drift-backed, a save anywhere (here or elsewhere) refreshes the UI
/// automatically.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _SettingsMessage(
          icon: Icons.error_outline,
          title: 'Could not load your settings',
          subtitle: '$error',
        ),
        data: (model) => _SettingsBody(model: model),
      ),
    );
  }
}

/// The scrollable, width-constrained settings content.
class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.model});

  final SettingsModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(settingsRepositoryProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            // --- Appearance --------------------------------------------
            const _SectionHeader('Appearance'),
            _SettingTile(
              title: 'Theme',
              subtitle: 'How Zenno chooses light or dark.',
              trailing: SegmentedButton<ThemeModeSetting>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeModeSetting.system,
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeModeSetting.light,
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeModeSetting.dark,
                    label: Text('Dark'),
                  ),
                ],
                selected: {model.themeMode},
                onSelectionChanged: (selection) =>
                    repo.setThemeMode(selection.first),
              ),
            ),

            const _SectionDivider(),

            // --- Focus defaults ----------------------------------------
            const _SectionHeader('Focus defaults'),
            _StepperTile(
              title: 'Pomodoro work',
              value: model.pomodoroWork.inMinutes,
              min: 5,
              max: 90,
              step: 5,
              unitLabel: 'min',
              onChanged: (minutes) =>
                  repo.setPomodoroWork(Duration(minutes: minutes)),
            ),
            _StepperTile(
              title: 'Pomodoro break',
              value: model.pomodoroBreak.inMinutes,
              min: 1,
              max: 30,
              step: 1,
              unitLabel: 'min',
              onChanged: (minutes) =>
                  repo.setPomodoroBreak(Duration(minutes: minutes)),
            ),
            _SliderTile(
              title: 'Flowmodoro break ratio',
              subtitle: 'Break length as a fraction of the focus stretch.',
              value: model.flowBreakRatio,
              min: 0.1,
              max: 0.5,
              divisions: 8,
              valueLabel: _ratioLabel(model.flowBreakRatio),
              onChanged: repo.setFlowBreakRatio,
            ),
            _StepperTile(
              title: 'Default session length',
              value: model.sessionLength.inMinutes,
              min: 10,
              max: 240,
              step: 10,
              unitLabel: 'min',
              onChanged: (minutes) =>
                  repo.setSessionLength(Duration(minutes: minutes)),
            ),

            const _SectionDivider(),

            // --- Focus -------------------------------------------------
            const _SectionHeader('Focus'),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xs,
              ),
              title: const Text('Keep screen on during sessions'),
              subtitle: const Text(
                'Stops the display sleeping while a Focus timer runs.',
              ),
              value: model.keepScreenOnInFocus,
              onChanged: (value) => repo.setKeepScreenOnInFocus(value: value),
            ),

            const _SectionDivider(),

            // --- Library -----------------------------------------------
            const _SectionHeader('Library'),
            _SettingTile(
              title: 'Default sort',
              subtitle: 'Order canvases appear in on the Library screen.',
              trailing: SegmentedButton<LibrarySort>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: LibrarySort.recent,
                    label: Text('Last edited'),
                  ),
                  ButtonSegment(
                    value: LibrarySort.created,
                    label: Text('Created'),
                  ),
                  ButtonSegment(value: LibrarySort.title, label: Text('Title')),
                ],
                selected: {model.librarySort},
                onSelectionChanged: (selection) =>
                    repo.setLibrarySort(selection.first),
              ),
            ),

            const _SectionDivider(),

            // --- About -------------------------------------------------
            const _SectionHeader('About'),
            const _AboutTile(),
          ],
        ),
      ),
    );
  }

  /// Formats a break ratio as a rounded percentage (e.g. `0.2` → `20%`).
  static String _ratioLabel(double ratio) => '${(ratio * 100).round()}%';
}

/// A small caps-styled header introducing a settings section.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// A thin, full-width divider between settings sections.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(),
    );
  }
}

/// A generic setting row: a title, an optional subtitle, and a trailing
/// control (segmented button, etc.).
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    required this.trailing,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitleText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitleText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(alignment: Alignment.centerLeft, child: trailing),
        ],
      ),
    );
  }
}

/// A setting row with a `−` / value / `+` stepper for an integer quantity.
class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unitLabel,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final int step;
  final String unitLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Clamp display so a value outside the range (e.g. an older default)
    // still renders sensibly.
    final shown = value.clamp(min, max);
    final canDecrease = shown > min;
    final canIncrease = shown < max;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          IconButton.outlined(
            onPressed: canDecrease
                ? () => onChanged((shown - step).clamp(min, max))
                : null,
            icon: const Icon(Icons.remove),
            tooltip: 'Decrease',
          ),
          SizedBox(
            width: 88,
            child: Text(
              '$shown $unitLabel',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton.outlined(
            onPressed: canIncrease
                ? () => onChanged((shown + step).clamp(min, max))
                : null,
            icon: const Icon(Icons.add),
            tooltip: 'Increase',
          ),
        ],
      ),
    );
  }
}

/// A setting row with a continuous slider for a fractional quantity.
class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle;
    final shown = value.clamp(min, max);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              Text(
                valueLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (subtitleText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitleText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          Slider(
            value: shown,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// The "About Zenno" tile — app name and a one-line description.
class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(
        Icons.auto_stories_outlined,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Zenno'),
      subtitle: const Text(
        'An infinite-canvas study app for advanced learners.',
      ),
    );
  }
}

/// A centered icon-and-text panel for the settings page's loading-failure
/// state.
class _SettingsMessage extends StatelessWidget {
  const _SettingsMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
