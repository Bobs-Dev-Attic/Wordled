import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game.dart';
import '../models/palette.dart';
import '../models/settings.dart';
import '../models/stats.dart';
import '../services/install_service.dart';
import '../services/logger.dart';
import '../services/storage.dart';
import '../services/update_service.dart';
import '../services/word_repository.dart';
import '../theme.dart';
import '../util/format.dart';
import '../version.dart';
import '../widgets/board.dart';
import '../widgets/confetti.dart';
import '../widgets/install_help_dialog.dart';
import '../widgets/keyboard.dart';
import '../widgets/stats_dialog.dart';
import 'how_to_play.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.settings,
    required this.storage,
    required this.words,
    required this.updateService,
    required this.installService,
    required this.lastVersion,
    required this.onSettingsChanged,
  });

  final GameSettings settings;
  final Storage storage;
  final WordRepository words;
  final UpdateService updateService;
  final InstallService installService;
  final String? lastVersion;
  final ValueChanged<GameSettings> onSettingsChanged;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  WordleGame? _game;
  Stats _stats = Stats();
  bool _loading = true;

  String _input = '';
  int? _revealRow;
  bool _busy = false;

  // Hint state.
  int _hintsUsed = 0;
  String? _flashKey;
  int _hintSerial = 0;

  // Win confetti.
  int _confettiSerial = 0;
  int _confettiCount = 0;

  final FocusNode _focusNode = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  GameSettings get _settings => widget.settings;
  GameMode _mode = GameMode.daily;

  /// Whether the active palette wants reduced motion (Battery Saver).
  bool get _reduceMotion {
    if (_settings.usesCustomPalette || _settings.paletteId == 'classic') {
      return false;
    }
    return Palette.presetById(_settings.paletteId).reduceMotion;
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.settings;
    final now = widget.settings;
    if (old.wordLength != now.wordLength || old.guessCount != now.guessCount) {
      log.i('game',
          'Config changed ${old.configKey} -> ${now.configKey}; reloading');
      _loadConfig();
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    await widget.words.ensureLoaded(_settings.wordLength);
    _stats = widget.storage.loadStats(_settings.configKey);
    _startGame(_mode, restore: true);
    if (mounted) setState(() => _loading = false);
  }

  void _startGame(GameMode mode, {bool restore = false}) {
    _mode = mode;
    final length = _settings.wordLength;
    final guesses = _settings.guessCount;
    WordleGame game;
    if (mode == GameMode.daily) {
      final today = DateTime.now();
      final answer = widget.words.dailyAnswer(length, today);
      game = (restore
              ? widget.storage.loadDailyGame(
                  today, answer, guesses, _settings.configKey)
              : null) ??
          WordleGame(
            answer: answer,
            mode: GameMode.daily,
            maxGuesses: guesses,
            puzzleNumber: dailyPuzzleNumber(today),
          );
    } else {
      game = WordleGame(
        answer: widget.words.randomAnswer(length),
        mode: GameMode.practice,
        maxGuesses: guesses,
      );
    }
    log.d('game',
        'Started ${mode.name} game: length=$length guesses=$guesses');
    setState(() {
      _game = game;
      _input = '';
      _revealRow = null;
      _busy = false;
      _hintsUsed = 0;
      _flashKey = null;
    });
  }

  // ---- Hints ----------------------------------------------------------------

  int get _hintsRemaining => _settings.hintsPerGame - _hintsUsed;

  void _useHint() {
    final game = _game;
    if (game == null || _busy) return;
    if (game.isOver) {
      _toast('Start a new word to use hints');
      return;
    }
    if (_hintsRemaining <= 0) {
      _toast('No hints left this game');
      return;
    }
    final hint = computeHint(game);
    if (hint == null) {
      _toast('No hint available right now');
      return;
    }
    setState(() {
      _hintsUsed++;
      _hintSerial++;
      switch (hint) {
        case KeyHint(:final letter):
          _flashKey = letter;
      }
    });
    log.d('game', 'Hint used ($_hintsUsed/${_settings.hintsPerGame}): $hint');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(milliseconds: 1400),
        width: 260,
      ));
  }

  GameColors _colors(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GameColors.from(_settings.resolvedPalette(brightness), brightness);
  }

  // ---- Input ----------------------------------------------------------------

  void _onKey(String letter) {
    final game = _game;
    if (game == null || _busy || game.isOver) return;
    if (_input.length >= game.wordLength) return;
    setState(() => _input += letter.toLowerCase());
  }

  void _onBackspace() {
    final game = _game;
    if (game == null || _busy || game.isOver || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _onEnter() async {
    final game = _game;
    if (game == null || _busy || game.isOver) return;
    if (_input.length < game.wordLength) {
      _reject('Not enough letters');
      return;
    }
    if (_settings.difficulty != Difficulty.easy &&
        !widget.words.isValidGuess(game.wordLength, _input)) {
      _reject('Not in word list');
      return;
    }
    if (_settings.difficulty == Difficulty.hard) {
      final violation =
          hardModeViolation(game.guesses, game.answer, _input);
      if (violation != null) {
        _reject(violation);
        return;
      }
    }

    final row = game.guesses.length;
    setState(() {
      game.submitGuess(_input);
      _input = '';
      _revealRow = row;
      _busy = true;
    });

    if (game.mode == GameMode.daily) {
      await widget.storage.saveDailyGame(game, _settings.configKey);
    }

    final cols = game.wordLength;
    final waitMs = _reduceMotion
        ? 80
        : Board.flipDelay(cols - 1).inMilliseconds + 260 + 150;
    await Future<void>.delayed(Duration(milliseconds: waitMs));
    if (!mounted) return;
    setState(() => _busy = false);

    if (game.isOver) await _handleGameOver(game);
  }

  void _reject(String message) {
    _shake.forward(from: 0);
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(milliseconds: 1200),
        width: 240,
      ));
  }

  Future<void> _handleGameOver(WordleGame game) async {
    if (game.mode == GameMode.daily) {
      setState(() => _stats.recordDaily(game));
      await widget.storage.saveStats(_settings.configKey, _stats);
    }
    if (!mounted) return;
    if (game.status == GameStatus.won) {
      // More confetti for fewer tries: scale from a modest burst at the last
      // allowed guess up to a big one for a first-try win.
      final span = (game.maxGuesses - 1).clamp(1, 1 << 30);
      final frac = ((game.maxGuesses - game.guesses.length) / span)
          .clamp(0.0, 1.0);
      setState(() {
        _confettiCount = (50 + frac * 200).round();
        _confettiSerial++;
      });
      // Let the burst land before the stats dialog covers the screen.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
    }
    await _showStats(finished: true);
  }

  // ---- Menu / dialogs -------------------------------------------------------

  Future<void> _share(WordleGame game) async {
    final text = game.shareText();
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Copied results to clipboard',
            textAlign: TextAlign.center),
        width: 260,
      ));
  }

  Future<void> _showStats({bool finished = false}) async {
    final game = _game;
    if (game == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => StatsDialog(
        stats: _stats,
        maxGuesses: game.maxGuesses,
        finishedGame: finished ? game : null,
        onShare: finished
            ? () {
                _share(game);
                Navigator.of(context).pop();
              }
            : null,
        onNewWord: finished
            ? () {
                Navigator.of(context).pop();
                _startGame(GameMode.practice);
              }
            : null,
      ),
    );
  }

  void _openHelp() => showHowToPlay(
        context,
        _colors(context),
        wordLength: _settings.wordLength,
        maxGuesses: _settings.guessCount,
      );

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(
        settings: _settings,
        lastVersion: widget.lastVersion,
        updateService: widget.updateService,
        words: widget.words,
        onChanged: widget.onSettingsChanged,
      ),
    ));
  }

  /// Starts a fresh game. In daily mode the puzzle is fixed, so "New game"
  /// begins a random practice round.
  void _newGame() => _startGame(GameMode.practice);

  Future<void> _installApp() async {
    final svc = widget.installService;
    if (svc.isStandalone) {
      _toast('Wordled is already installed.');
      return;
    }
    // Prefer the native install prompt (Android / desktop Chrome & Edge).
    if (svc.hasPrompt) {
      final shown = await svc.promptInstall();
      if (shown || !mounted) return;
    }
    if (!mounted) return;
    // Otherwise (iOS, or prompt not yet available) show manual instructions.
    await showInstallHelp(context, isIOS: svc.isIOS);
  }

  Future<void> _checkForUpdate() async {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Checking for updates…'),
        duration: Duration(milliseconds: 1500),
      ));
    final hasUpdate = await widget.updateService.checkForUpdates();
    if (!mounted) return;
    if (!hasUpdate) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('You\'re on the latest version.'),
        ));
      return;
    }
    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update available'),
        content: const Text('A new version is ready. Reload now to apply it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reload'),
          ),
        ],
      ),
    );
    if (apply == true) await widget.updateService.applyUpdate();
  }

  // ---- Hardware keyboard ----------------------------------------------------

  KeyEventResult _handleHardwareKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _onEnter();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _onBackspace();
      return KeyEventResult.handled;
    }
    final label = event.character?.toLowerCase();
    if (label != null && label.length == 1 && RegExp(r'[a-z]').hasMatch(label)) {
      _onKey(label);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    final game = _game;
    final isPractice = _mode == GameMode.practice;

    final hintsOn = _settings.hintsPerGame > 0;
    final canHint =
        hintsOn && game != null && !game.isOver && _hintsRemaining > 0;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleHardwareKey,
      child: Scaffold(
        backgroundColor: colors.background,
        drawer: _buildDrawer(),
        appBar: AppBar(
          backgroundColor: colors.background,
          foregroundColor: colors.tileText,
          title: const Text('WORDLED'),
          actions: [
            if (hintsOn)
              Badge.count(
                count: _hintsRemaining,
                isLabelVisible: canHint,
                child: IconButton(
                  icon: const Icon(Icons.lightbulb_outline),
                  tooltip: 'Hint ($_hintsRemaining left)',
                  // Keep the button enabled so the icon always renders at full
                  // color; _useHint reports why a hint can't be used.
                  color: colors.tileText,
                  onPressed: _useHint,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.leaderboard_outlined),
              tooltip: 'Statistics',
              onPressed: () => _showStats(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(22),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                isPractice
                    ? 'New word · ${_settings.wordLength} letters'
                    : 'Daily #${game?.puzzleNumber != null ? commas(game!.puzzleNumber!) : ''} · '
                        '${_settings.wordLength} letters',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF818384), letterSpacing: 1),
              ),
            ),
          ),
        ),
        body: Container(
          // Subtle diagonal gradient behind the whole play area for some life.
          decoration: BoxDecoration(gradient: colors.backgroundGradient),
          child: Stack(
            children: [
              SafeArea(
                child: _loading || game == null
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Board(
                                game: game,
                                currentInput: _input,
                                colors: colors,
                                shake: _shake,
                                revealRow: _revealRow,
                                reduceMotion: _reduceMotion,
                              ),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Keyboard(
                              keyStatuses: game.keyStatuses,
                              colors: colors,
                              onKey: _onKey,
                              onEnter: _onEnter,
                              onBackspace: _onBackspace,
                              flashLetter: _flashKey,
                              flashSerial: _hintSerial,
                            ),
                          ),
                        ],
                      ),
              ),
              if (!_reduceMotion)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ConfettiOverlay(
                      serial: _confettiSerial,
                      count: _confettiCount,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/icon/wordled_icon.png',
                        width: 96, height: 96),
                  ),
                  const SizedBox(height: 12),
                  const Text('WORDLED',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3)),
                  Text('Offline · v$kAppVersion',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('New Word'),
              onTap: () {
                Navigator.pop(context);
                _newGame();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('How to play'),
              onTap: () {
                Navigator.pop(context);
                _openHelp();
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard_outlined),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pop(context);
                _showStats();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _openSettings();
              },
            ),
            const Spacer(),
            const Divider(),
            // Show "Install App" until the PWA is installed; once it's running
            // standalone, offer "Check for Update" instead.
            if (widget.installService.isStandalone)
              ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: const Text('Check for Update'),
                onTap: () {
                  Navigator.pop(context);
                  _checkForUpdate();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.install_mobile_outlined),
                title: const Text('Install App'),
                onTap: () {
                  Navigator.pop(context);
                  _installApp();
                },
              ),
          ],
        ),
      ),
    );
  }
}
