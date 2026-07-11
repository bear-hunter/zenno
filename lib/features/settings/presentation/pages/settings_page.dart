import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/canvas/input/pen_profile.dart';
import 'package:zenno/canvas/input/stylus_button_mapping.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/core/widgets/aurora.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';
import 'package:zenno/features/settings/data/settings_repository.dart';

const List<StylusButtonAction> _supportedSideButtonActions =
    <StylusButtonAction>[
      StylusButtonAction.temporaryEraser,
      StylusButtonAction.temporaryLasso,
      StylusButtonAction.temporaryPan,
      StylusButtonAction.straightLine,
      StylusButtonAction.arrow,
      StylusButtonAction.undo,
      StylusButtonAction.redo,
      StylusButtonAction.togglePreviousTool,
      StylusButtonAction.radialMenu,
      StylusButtonAction.disabled,
    ];

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
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const AuroraTopBar(
            eyebrow: 'Preferences',
            title: 'Settings',
            subtitle: 'Tune appearance, stylus input, and focus defaults.',
          ),
          Expanded(
            child: settings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _SettingsMessage(
                icon: Icons.error_outline,
                title: 'Could not load your settings',
                subtitle: 'Please try again.',
                onRetry: () => ref.invalidate(appSettingsProvider),
              ),
              data: (model) => _SettingsBody(model: model),
            ),
          ),
        ],
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
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.settingsMaxWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            96,
          ),
          children: [
            // --- Appearance --------------------------------------------
            _SettingsPanel(
              title: 'Appearance',
              icon: Icons.contrast,
              description: 'Choose how the workspace feels.',
              children: [
                _SettingTile(
                  title: 'Theme',
                  subtitle: 'Choose Zenno\'s app theme.',
                  trailing: SegmentedButton<ThemeModeSetting>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeModeSetting.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeModeSetting.dark,
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {_themeSelection(model.themeMode)},
                    onSelectionChanged: (selection) =>
                        repo.setThemeMode(selection.first),
                  ),
                ),
              ],
            ),

            // --- Canvas and stylus -----------------------------------
            _SettingsPanel(
              title: 'Canvas & stylus',
              icon: Icons.draw_outlined,
              description: 'Tune S Pen gestures and stroke response.',
              children: [
                _StylusActionTile(
                  title: 'Side button — hold',
                  value: model.stylusButtonMapping.hold,
                  onChanged: (action) => repo.setStylusButtonMapping(
                    StylusButtonMapping(
                      hold: action,
                      tap: model.stylusButtonMapping.tap,
                      drag: model.stylusButtonMapping.drag,
                      penLongPress: model.stylusButtonMapping.penLongPress,
                    ),
                  ),
                ),
                _StylusActionTile(
                  title: 'Side button — tap',
                  value: model.stylusButtonMapping.tap,
                  onChanged: (action) => repo.setStylusButtonMapping(
                    StylusButtonMapping(
                      hold: model.stylusButtonMapping.hold,
                      tap: action,
                      drag: model.stylusButtonMapping.drag,
                      penLongPress: model.stylusButtonMapping.penLongPress,
                    ),
                  ),
                ),
                _StylusActionTile(
                  title: 'Side button — drag',
                  value: model.stylusButtonMapping.drag,
                  onChanged: (action) => repo.setStylusButtonMapping(
                    StylusButtonMapping(
                      hold: model.stylusButtonMapping.hold,
                      tap: model.stylusButtonMapping.tap,
                      drag: action,
                      penLongPress: model.stylusButtonMapping.penLongPress,
                    ),
                  ),
                ),
                _StylusActionTile(
                  title: 'Pen long press',
                  value: model.stylusButtonMapping.penLongPress,
                  actions: const [
                    StylusButtonAction.temporaryLasso,
                    StylusButtonAction.temporaryEraser,
                    StylusButtonAction.temporaryPan,
                    StylusButtonAction.radialMenu,
                    StylusButtonAction.disabled,
                  ],
                  onChanged: (action) => repo.setStylusButtonMapping(
                    StylusButtonMapping(
                      hold: model.stylusButtonMapping.hold,
                      tap: model.stylusButtonMapping.tap,
                      drag: model.stylusButtonMapping.drag,
                      penLongPress: action,
                    ),
                  ),
                ),
                _PenProfileControls(
                  profile: model.penProfile,
                  onChanged: repo.setPenProfile,
                ),
              ],
            ),

            // --- Focus -------------------------------------------------
            _SettingsPanel(
              title: 'Focus',
              icon: Icons.timer_outlined,
              description: 'Set the rhythm and defaults for focus sessions.',
              children: [
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
                _SettingTile(
                  title: 'Keep screen on during sessions',
                  subtitle:
                      'Stops the display sleeping while a Focus timer runs.',
                  trailing: Switch(
                    value: model.keepScreenOnInFocus,
                    onChanged: (value) =>
                        repo.setKeepScreenOnInFocus(value: value),
                  ),
                ),
              ],
            ),

            _SettingsPanel(
              title: 'Library',
              icon: Icons.grid_view_outlined,
              description: 'Control how canvases are ordered by default.',
              children: [
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
                      ButtonSegment(
                        value: LibrarySort.title,
                        label: Text('Title'),
                      ),
                    ],
                    selected: {model.librarySort},
                    onSelectionChanged: (selection) =>
                        repo.setLibrarySort(selection.first),
                  ),
                ),
              ],
            ),

            const _SettingsPanel(
              title: 'About',
              icon: Icons.auto_stories_outlined,
              description: 'A quiet place for visual thinking and learning.',
              children: [_AboutTile()],
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a break ratio as a rounded percentage (e.g. `0.2` → `20%`).
  static String _ratioLabel(double ratio) => '${(ratio * 100).round()}%';

  /// Legacy `system` rows render as dark because settings now expose only the
  /// two explicit app themes.
  static ThemeModeSetting _themeSelection(ThemeModeSetting setting) {
    return switch (setting) {
      ThemeModeSetting.light => ThemeModeSetting.light,
      ThemeModeSetting.system || ThemeModeSetting.dark => ThemeModeSetting.dark,
    };
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.title,
    required this.icon,
    required this.children,
    this.description,
  });

  final String title;
  final IconData icon;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: theme.colorScheme.outlineVariant),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(color: theme.colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _PenProfileControls extends StatelessWidget {
  const _PenProfileControls({required this.profile, required this.onChanged});

  final PenProfile profile;
  final ValueChanged<PenProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingTile(
          title: 'Pressure response',
          subtitle: 'How quickly pressure increases stroke weight.',
          trailing: SegmentedButton<PressureCurveKind>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: PressureCurveKind.light,
                label: Text('Light'),
              ),
              ButtonSegment(
                value: PressureCurveKind.normal,
                label: Text('Normal'),
              ),
              ButtonSegment(value: PressureCurveKind.firm, label: Text('Firm')),
            ],
            selected: {
              profile.pressureCurve == PressureCurveKind.custom
                  ? PressureCurveKind.normal
                  : profile.pressureCurve,
            },
            onSelectionChanged: (value) =>
                onChanged(profile.copyWith(pressureCurve: value.first)),
          ),
        ),
        Divider(color: dividerColor),
        _SliderTile(
          title: 'Stabilizer',
          value: profile.stabilizer,
          min: 0,
          max: 0.8,
          divisions: 8,
          valueLabel: '${(profile.stabilizer * 100).round()}%',
          onChanged: (value) => onChanged(profile.copyWith(stabilizer: value)),
        ),
        Divider(color: dividerColor),
        _SliderTile(
          title: 'Smoothing',
          value: profile.smoothing,
          min: 0,
          max: 0.8,
          divisions: 8,
          valueLabel: '${(profile.smoothing * 100).round()}%',
          onChanged: (value) => onChanged(profile.copyWith(smoothing: value)),
        ),
      ],
    );
  }
}

class _StylusActionTile extends StatelessWidget {
  const _StylusActionTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.actions = _supportedSideButtonActions,
  });

  final String title;
  final StylusButtonAction value;
  final ValueChanged<StylusButtonAction> onChanged;
  final List<StylusButtonAction> actions;

  @override
  Widget build(BuildContext context) {
    final List<StylusButtonAction> visibleActions = actions.contains(value)
        ? actions
        : <StylusButtonAction>[...actions, value];
    return _SettingTile(
      title: title,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SizedBox(
          width: double.infinity,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StylusButtonAction>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(AppRadii.md),
              items: [
                for (final action in visibleActions)
                  DropdownMenuItem<StylusButtonAction>(
                    value: action,
                    enabled: actions.contains(action),
                    child: Text(
                      actions.contains(action)
                          ? _label(action)
                          : '${_label(action)} (Unavailable)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (action) {
                if (action != null) {
                  onChanged(action);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  static String _label(StylusButtonAction action) {
    return switch (action) {
      StylusButtonAction.temporaryEraser => 'Temporary eraser',
      StylusButtonAction.temporaryLasso => 'Temporary lasso',
      StylusButtonAction.temporaryPan => 'Temporary pan',
      StylusButtonAction.straightLine => 'Straight line',
      StylusButtonAction.arrow => 'Arrow',
      StylusButtonAction.eyedropper => 'Eyedropper',
      StylusButtonAction.undo => 'Undo',
      StylusButtonAction.redo => 'Redo',
      StylusButtonAction.togglePreviousTool => 'Toggle tool',
      StylusButtonAction.radialMenu => 'Radial menu',
      StylusButtonAction.exportSelection => 'Export selection',
      StylusButtonAction.disabled => 'Disabled',
    };
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              if (subtitleText != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitleText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label,
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerLeft, child: trailing),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: label),
              const SizedBox(width: AppSpacing.xl),
              Flexible(
                flex: 2,
                child: Align(alignment: Alignment.centerRight, child: trailing),
              ),
            ],
          );
        },
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
    // Clamp display so a value outside the range (e.g. an older default)
    // still renders sensibly.
    final shown = value.clamp(min, max);
    final canDecrease = shown > min;
    final canIncrease = shown < max;

    return _SettingTile(
      title: title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            onPressed: canDecrease
                ? () => onChanged((shown - step).clamp(min, max))
                : null,
            icon: const Icon(Icons.remove),
            tooltip: 'Decrease $title',
          ),
          SizedBox(
            width: 88,
            child: Text(
              '$shown $unitLabel',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton.outlined(
            onPressed: canIncrease
                ? () => onChanged((shown + step).clamp(min, max))
                : null,
            icon: const Icon(Icons.add),
            tooltip: 'Increase $title',
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              Text(
                valueLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (subtitleText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitleText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          Semantics(
            label: title,
            value: valueLabel,
            child: Slider(
              value: shown,
              min: min,
              max: max,
              divisions: divisions,
              label: valueLabel,
              onChanged: onChanged,
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zenno', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'An infinite-canvas study app for advanced learners.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

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
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
