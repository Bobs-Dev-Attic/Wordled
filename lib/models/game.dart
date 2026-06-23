import 'dart:math';

/// The status of a single letter after a guess is evaluated.
enum LetterStatus { empty, absent, present, correct }

/// Overall progress of a game.
enum GameStatus { playing, won, lost }

/// Which kind of game is being played.
enum GameMode { daily, practice }

/// Day zero for the daily puzzle rotation. Fixed so every device sharing a
/// calendar date computes the same word, fully offline.
final DateTime kEpoch = DateTime.utc(2021, 6, 19);

/// The daily puzzle index into a list of [listLength] answers for [date] and a
/// given [wordLength] (length is mixed in so different board sizes rotate
/// independently).
int dailyIndexFor(DateTime date, int listLength, int wordLength) {
  final localMidnight = DateTime(date.year, date.month, date.day);
  final days = localMidnight.toUtc().difference(kEpoch).inDays;
  final salted = days + wordLength * 7919;
  return ((salted % listLength) + listLength) % listLength;
}

/// The daily puzzle number shown to the player (1-based, days since epoch).
int dailyPuzzleNumber(DateTime date) {
  final localMidnight = DateTime(date.year, date.month, date.day);
  return localMidnight.toUtc().difference(kEpoch).inDays + 1;
}

/// Evaluates [guess] against [answer] using standard Wordle rules, including
/// correct handling of duplicate letters. Greens are assigned first; remaining
/// answer letters then back yellows on a first-come basis.
List<LetterStatus> evaluateGuess(String guess, String answer) {
  assert(guess.length == answer.length);
  final n = answer.length;
  final result = List<LetterStatus>.filled(n, LetterStatus.absent);
  final counts = <String, int>{};
  for (final ch in answer.split('')) {
    counts[ch] = (counts[ch] ?? 0) + 1;
  }

  for (var i = 0; i < n; i++) {
    final ch = guess[i];
    if (ch == answer[i]) {
      result[i] = LetterStatus.correct;
      counts[ch] = counts[ch]! - 1;
    }
  }
  for (var i = 0; i < n; i++) {
    if (result[i] == LetterStatus.correct) continue;
    final ch = guess[i];
    if ((counts[ch] ?? 0) > 0) {
      result[i] = LetterStatus.present;
      counts[ch] = counts[ch]! - 1;
    }
  }
  return result;
}

int _rank(LetterStatus s) => switch (s) {
      LetterStatus.correct => 3,
      LetterStatus.present => 2,
      LetterStatus.absent => 1,
      LetterStatus.empty => 0,
    };

/// Checks the Hard-mode constraint: [candidate] must keep every known-correct
/// letter in place and include every letter previously revealed as present.
/// Returns an error message to show the player, or null if the guess is legal.
String? hardModeViolation(
  List<String> previousGuesses,
  String answer,
  String candidate,
) {
  final requiredGreens = <int, String>{};
  final requiredLetters = <String, int>{};

  for (final guess in previousGuesses) {
    final eval = evaluateGuess(guess, answer);
    final perGuess = <String, int>{};
    for (var i = 0; i < guess.length; i++) {
      final ch = guess[i];
      if (eval[i] == LetterStatus.correct) {
        requiredGreens[i] = ch;
        perGuess[ch] = (perGuess[ch] ?? 0) + 1;
      } else if (eval[i] == LetterStatus.present) {
        perGuess[ch] = (perGuess[ch] ?? 0) + 1;
      }
    }
    // The strongest single-guess evidence sets the minimum count required.
    perGuess.forEach((ch, count) {
      if (count > (requiredLetters[ch] ?? 0)) requiredLetters[ch] = count;
    });
  }

  for (final entry in requiredGreens.entries) {
    if (candidate[entry.key] != entry.value) {
      final ordinal = _ordinal(entry.key + 1);
      return '$ordinal letter must be ${entry.value.toUpperCase()}';
    }
  }
  for (final entry in requiredLetters.entries) {
    final have = candidate.split('').where((c) => c == entry.key).length;
    if (have < entry.value) {
      return 'Guess must contain ${entry.key.toUpperCase()}';
    }
  }
  return null;
}

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

/// A single Wordle game.
class WordleGame {
  WordleGame({
    required this.answer,
    required this.mode,
    required this.maxGuesses,
    this.puzzleNumber,
    List<String>? guesses,
  }) : guesses = guesses ?? <String>[];

  final String answer;
  final GameMode mode;
  final int maxGuesses;
  final int? puzzleNumber;
  final List<String> guesses;

  int get wordLength => answer.length;

  GameStatus get status {
    if (guesses.isNotEmpty && guesses.last == answer) return GameStatus.won;
    if (guesses.length >= maxGuesses) return GameStatus.lost;
    return GameStatus.playing;
  }

  bool get isOver => status != GameStatus.playing;

  int? get currentRow => isOver ? null : guesses.length;

  List<List<LetterStatus>> get evaluations =>
      guesses.map((g) => evaluateGuess(g, answer)).toList();

  Map<String, LetterStatus> get keyStatuses {
    final map = <String, LetterStatus>{};
    for (final guess in guesses) {
      final eval = evaluateGuess(guess, answer);
      for (var i = 0; i < guess.length; i++) {
        final ch = guess[i];
        final next = eval[i];
        final current = map[ch];
        if (current == null || _rank(next) > _rank(current)) {
          map[ch] = next;
        }
      }
    }
    return map;
  }

  void submitGuess(String guess) {
    if (isOver) return;
    guesses.add(guess.toLowerCase());
  }

  /// An emoji grid of the result, suitable for sharing.
  String? shareText() {
    if (!isOver) return null;
    final header = mode == GameMode.daily
        ? 'Wordled ${puzzleNumber ?? ''} ($wordLength)'
        : 'Wordled (practice, $wordLength)';
    final score = status == GameStatus.won
        ? '${guesses.length}/$maxGuesses'
        : 'X/$maxGuesses';
    final buffer = StringBuffer('${header.trim()} $score\n\n');
    for (final eval in evaluations) {
      for (final s in eval) {
        buffer.write(switch (s) {
          LetterStatus.correct => '🟩',
          LetterStatus.present => '🟨',
          _ => '⬛',
        });
      }
      buffer.write('\n');
    }
    return buffer.toString().trimRight();
  }
}

/// A hint the player can request: highlight a useful keyboard key to play.
sealed class GameHint {
  const GameHint();
}

/// Flash a keyboard key — a letter that's in the answer but not yet locked into
/// place.
class KeyHint extends GameHint {
  const KeyHint(this.letter);
  final String letter;
}

final Random _hintRandom = Random();

/// Picks a random helpful hint for the current [game]: a letter that's in the
/// answer but not already placed correctly. Returns null if there's nothing
/// left to reveal (game over, or every answer letter is already solved).
GameHint? computeHint(WordleGame game, [Random? random]) {
  if (game.isOver) return null;
  final rng = random ?? _hintRandom;
  final keyStatuses = game.keyStatuses;
  final candidates = <String>{};
  for (final ch in game.answer.split('')) {
    if (keyStatuses[ch] != LetterStatus.correct) candidates.add(ch);
  }
  if (candidates.isEmpty) return null;
  final list = candidates.toList();
  return KeyHint(list[rng.nextInt(list.length)]);
}

