import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/game.dart';
import 'logger.dart';

/// Loads and caches the bundled word lists. Lists live as text assets
/// (`assets/words/answers_N.txt`, `assets/words/allowed_N.txt`) so they are
/// available offline. Each length is loaded lazily the first time it is needed.
class WordRepository {
  WordRepository();

  final Map<int, List<String>> _answers = {};
  final Map<int, Set<String>> _allowed = {};

  bool isLoaded(int length) => _answers.containsKey(length);

  /// Loads the word lists for [length] if not already loaded.
  Future<void> ensureLoaded(int length) async {
    if (isLoaded(length)) return;
    final sw = Stopwatch()..start();
    final answersRaw = await rootBundle.loadString('assets/words/answers_$length.txt');
    final allowedRaw = await rootBundle.loadString('assets/words/allowed_$length.txt');
    final answers = _parse(answersRaw);
    final allowed = _parse(allowedRaw).toSet()..addAll(answers);
    _answers[length] = answers;
    _allowed[length] = allowed;
    log.i('words',
        'Loaded length $length: ${answers.length} answers, ${allowed.length} '
        'allowed in ${sw.elapsedMilliseconds}ms');
  }

  List<String> _parse(String raw) => raw
      .split('\n')
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toList();

  List<String> answers(int length) =>
      _answers[length] ?? (throw StateError('Length $length not loaded'));

  Set<String> allowed(int length) =>
      _allowed[length] ?? (throw StateError('Length $length not loaded'));

  /// Whether [word] is an accepted guess for the given [length].
  bool isValidGuess(int length, String word) {
    final w = word.toLowerCase();
    return w.length == length && (_allowed[length]?.contains(w) ?? false);
  }

  /// The deterministic daily answer for [date] at [length].
  String dailyAnswer(int length, DateTime date) {
    final list = answers(length);
    return list[dailyIndexFor(date, list.length, length)];
  }

  final Random _random = Random();

  /// A random answer for practice mode.
  String randomAnswer(int length) {
    final list = answers(length);
    return list[_random.nextInt(list.length)];
  }
}
