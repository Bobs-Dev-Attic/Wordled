import 'package:flutter/material.dart';

import 'models/settings.dart';
import 'screens/game_screen.dart';
import 'services/install_service.dart';
import 'services/logger.dart';
import 'services/storage.dart';
import 'services/update_service.dart';
import 'services/word_repository.dart';
import 'theme.dart';
import 'version.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  log.i('app', 'Starting Wordled v$kAppVersionFull');

  final storage = await Storage.create();
  final lastVersion = storage.loadLastVersion();
  final settings = storage.loadSettings();
  final updateService = UpdateService(storage);
  await updateService.trackVersion();

  final installService = InstallService()..init();

  runApp(WordledApp(
    storage: storage,
    words: WordRepository(),
    updateService: updateService,
    installService: installService,
    initialSettings: settings,
    lastVersion: lastVersion,
  ));
}

class WordledApp extends StatefulWidget {
  const WordledApp({
    super.key,
    required this.storage,
    required this.words,
    required this.updateService,
    required this.installService,
    required this.initialSettings,
    required this.lastVersion,
  });

  final Storage storage;
  final WordRepository words;
  final UpdateService updateService;
  final InstallService installService;
  final GameSettings initialSettings;
  final String? lastVersion;

  @override
  State<WordledApp> createState() => _WordledAppState();
}

class _WordledAppState extends State<WordledApp> {
  late GameSettings _settings = widget.initialSettings;

  void _applySettings(GameSettings next) {
    setState(() => _settings = next);
    widget.storage.saveSettings(next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordled',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: _settings.themeMode,
      home: GameScreen(
        settings: _settings,
        storage: widget.storage,
        words: widget.words,
        updateService: widget.updateService,
        installService: widget.installService,
        lastVersion: widget.lastVersion,
        onSettingsChanged: _applySettings,
      ),
    );
  }
}
