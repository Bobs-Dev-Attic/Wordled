import 'package:flutter/material.dart';

import '../models/palette.dart';
import '../models/settings.dart';
import '../services/update_service.dart';
import '../version.dart';
import '../widgets/color_picker_dialog.dart';
import 'log_viewer.dart';

/// Full settings page: appearance, gameplay, and update/maintenance controls.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.lastVersion,
    required this.updateService,
    required this.onChanged,
  });

  final GameSettings settings;
  final String? lastVersion;
  final UpdateService updateService;
  final ValueChanged<GameSettings> onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _settings = widget.settings;
  bool _working = false;

  void _update(GameSettings next) {
    setState(() => _settings = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS',
            style: TextStyle(letterSpacing: 2, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _section('Appearance'),
          _themeTile(),
          _paletteTile(),
          if (_settings.usesCustomPalette) ..._customColorTiles(),
          const Divider(),
          _section('Gameplay'),
          _difficultyTile(),
          _wordLengthTile(),
          _guessCountTile(),
          _hintsTile(),
          const Divider(),
          _section('Updates & Maintenance'),
          _versionTile(),
          _actionTile(
            icon: Icons.system_update_alt,
            title: 'Check for updates',
            subtitle: 'Fetch the latest version from the server',
            onTap: _checkForUpdates,
          ),
          _actionTile(
            icon: Icons.cleaning_services_outlined,
            title: 'Clear cache',
            subtitle: 'Purge cached assets and reload (keeps your stats)',
            onTap: _clearCache,
          ),
          _actionTile(
            icon: Icons.receipt_long_outlined,
            title: 'View diagnostic log',
            subtitle: 'See verbose update & cache activity',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogViewerScreen()),
            ),
          ),
          _actionTile(
            icon: Icons.warning_amber_rounded,
            title: 'Nuclear reset',
            subtitle: 'Obliterate everything and start over',
            destructive: true,
            onTap: _nuclearReset,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---- Sections -------------------------------------------------------------

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  Widget _themeTile() {
    return ListTile(
      title: const Text('Theme'),
      subtitle: const Text('Light, dark, or follow the system'),
      trailing: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
        ],
        selected: {_settings.themeMode},
        onSelectionChanged: (s) =>
            _update(_settings.copyWith(themeMode: s.first)),
      ),
    );
  }

  Widget _paletteTile() {
    final swatches = <Widget>[
      for (final preset in Palette.presets)
        _PaletteChip(
          palette: preset,
          selected: !_settings.usesCustomPalette &&
              _settings.paletteId == preset.id,
          onTap: () => _update(_settings.copyWith(paletteId: preset.id)),
        ),
      _PaletteChip(
        palette: _settings.customPalette,
        label: 'Custom',
        selected: _settings.usesCustomPalette,
        onTap: () => _update(_settings.copyWith(paletteId: Palette.customId)),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Palette', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: swatches),
        ],
      ),
    );
  }

  List<Widget> _customColorTiles() {
    final custom = _settings.customPalette;
    return [
      _colorRow('Correct', custom.correct,
          (c) => _update(_settings.copyWith(
              customPalette: custom.copyWith(correct: c)))),
      _colorRow('Present', custom.present,
          (c) => _update(_settings.copyWith(
              customPalette: custom.copyWith(present: c)))),
      _colorRow('Absent', custom.absent,
          (c) => _update(_settings.copyWith(
              customPalette: custom.copyWith(absent: c)))),
    ];
  }

  Widget _colorRow(String label, Color color, ValueChanged<Color> onPick) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      title: Text('$label color'),
      trailing: GestureDetector(
        onTap: () async {
          final picked = await ColorPickerDialog.show(context,
              title: '$label color', initial: color);
          if (picked != null) onPick(picked);
        },
        child: Container(
          width: 40,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _difficultyTile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Difficulty', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          SegmentedButton<Difficulty>(
            showSelectedIcon: false,
            segments: [
              for (final d in Difficulty.values)
                ButtonSegment(value: d, label: Text(d.label)),
            ],
            selected: {_settings.difficulty},
            onSelectionChanged: (s) =>
                _update(_settings.copyWith(difficulty: s.first)),
          ),
          const SizedBox(height: 4),
          Text(_settings.difficulty.description,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _wordLengthTile() {
    return _stepperTile(
      title: 'Word length',
      value: _settings.wordLength,
      min: kMinWordLength,
      max: kMaxWordLength,
      suffix: 'letters',
      onChanged: (v) => _update(_settings.copyWith(wordLength: v)),
    );
  }

  Widget _guessCountTile() {
    return _stepperTile(
      title: 'Guesses',
      value: _settings.guessCount,
      min: kMinGuesses,
      max: kMaxGuesses,
      suffix: 'tries',
      onChanged: (v) => _update(_settings.copyWith(guessCount: v)),
    );
  }

  Widget _hintsTile() {
    return _stepperTile(
      title: 'Hints per game',
      value: _settings.hintsPerGame,
      min: kMinHints,
      max: kMaxHints,
      suffix: _settings.hintsPerGame == 0 ? 'off' : 'hints',
      onChanged: (v) => _update(_settings.copyWith(hintsPerGame: v)),
    );
  }

  Widget _stepperTile({
    required String title,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                Text('$value $suffix',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 36,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          IconButton.filledTonal(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _versionTile() {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('Version'),
      subtitle: Text(widget.lastVersion != null &&
              widget.lastVersion != kAppVersionFull
          ? 'v$kAppVersionFull (updated from ${widget.lastVersion})'
          : 'v$kAppVersionFull'),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? Colors.red.shade400 : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle),
      enabled: !_working,
      onTap: _working ? null : onTap,
    );
  }

  // ---- Maintenance actions --------------------------------------------------

  Future<void> _checkForUpdates() async {
    setState(() => _working = true);
    final hasUpdate = await widget.updateService.checkForUpdates();
    if (!mounted) return;
    setState(() => _working = false);
    if (hasUpdate) {
      final apply = await _confirm(
        title: 'Update available',
        message: 'A new version is ready. Reload now to apply it?',
        confirmLabel: 'Reload',
      );
      if (apply == true) await widget.updateService.applyUpdate();
    } else {
      _toast('You\'re on the latest version.');
    }
  }

  Future<void> _clearCache() async {
    final ok = await _confirm(
      title: 'Clear cache?',
      message: 'This purges cached assets and reloads the app. Your stats and '
          'settings are kept.',
      confirmLabel: 'Clear & reload',
    );
    if (ok == true) {
      setState(() => _working = true);
      await widget.updateService.clearCacheAndReload();
    }
  }

  Future<void> _nuclearReset() async {
    final ok = await _confirm(
      title: '☢ Nuclear reset',
      message: 'This OBLITERATES everything: cached files, the service worker, '
          'all statistics, daily progress and settings. The app restarts as if '
          'freshly installed. This cannot be undone.',
      confirmLabel: 'Obliterate everything',
      destructive: true,
    );
    if (ok == true) {
      setState(() => _working = true);
      await widget.updateService.nuclearReset();
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red.shade600)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.palette,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final Palette palette;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.white24,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(palette.correct),
                _dot(palette.present),
                _dot(palette.absent),
              ],
            ),
            const SizedBox(height: 4),
            Text(label ?? palette.name, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}
