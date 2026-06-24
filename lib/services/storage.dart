import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import '../models/settings.dart';
import '../models/stats.dart';
import 'logger.dart';

/// Persists settings, statistics, and daily progress to the device using
/// [SharedPreferences]. Everything lives on-device, so the game works offline.
///
/// Stats and daily progress are scoped per board configuration (e.g. "5x6") so
/// switching word length or guess count keeps independent records.
///
/// Security note: only non-sensitive game state is stored (no credentials or
/// personal data), and nothing is transmitted off-device. On the web this maps
/// to localStorage, which is wiped by the "nuclear reset" maintenance action.
class Storage {
  Storage(this._prefs);

  final SharedPreferences _prefs;

  static const settingsKey = 'wordled.settings';
  static const _statsKey = 'wordled.stats';
  static const _dailyPrefix = 'wordled.daily.';
  static const _versionKey = 'wordled.lastVersion';

  static Future<Storage> create() async =>
      Storage(await SharedPreferences.getInstance());

  // ---- Settings -------------------------------------------------------------

  GameSettings loadSettings() {
    final raw = _prefs.getString(settingsKey);
    if (raw == null) return GameSettings();
    try {
      return GameSettings.decode(raw);
    } catch (e) {
      log.w('storage', 'Failed to decode settings, using defaults: $e');
      return GameSettings();
    }
  }

  Future<void> saveSettings(GameSettings settings) {
    log.d('storage', 'Saving settings: ${settings.configKey}, '
        'palette=${settings.paletteId}, difficulty=${settings.difficulty.name}');
    return _prefs.setString(settingsKey, settings.encode());
  }

  // ---- Version tracking -----------------------------------------------------

  String? loadLastVersion() => _prefs.getString(_versionKey);

  Future<void> saveLastVersion(String version) =>
      _prefs.setString(_versionKey, version);

  // ---- Stats (global — every game counts) -----------------------------------

  Stats loadStats() {
    final raw = _prefs.getString(_statsKey);
    if (raw == null) return Stats();
    try {
      return Stats.decode(raw);
    } catch (_) {
      return Stats();
    }
  }

  Future<void> saveStats(Stats stats) =>
      _prefs.setString(_statsKey, stats.encode());

  // ---- Daily progress -------------------------------------------------------

  WordleGame? loadDailyGame(DateTime date, String answer, int maxGuesses,
      String configKey) {
    final raw = _prefs.getString('$_dailyPrefix$configKey');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedNumber = (json['puzzleNumber'] as num?)?.toInt();
      if (savedNumber != dailyPuzzleNumber(date)) return null;
      final guesses =
          (json['guesses'] as List<dynamic>).map((e) => e.toString()).toList();
      return WordleGame(
        answer: answer,
        mode: GameMode.daily,
        maxGuesses: maxGuesses,
        puzzleNumber: dailyPuzzleNumber(date),
        guesses: guesses,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDailyGame(WordleGame game, String configKey) {
    final json = jsonEncode({
      'puzzleNumber': game.puzzleNumber,
      'guesses': game.guesses,
    });
    return _prefs.setString('$_dailyPrefix$configKey', json);
  }

  // ---- Wholesale wipe (nuclear reset) --------------------------------------

  /// Removes every Wordled key from local storage.
  Future<void> wipeAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('wordled.')).toList();
    log.w('storage', 'Wiping ${keys.length} stored keys');
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
