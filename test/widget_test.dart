import 'package:flutter_test/flutter_test.dart';

import 'package:wordled/models/game.dart';
import 'package:wordled/models/settings.dart';
import 'package:wordled/models/stats.dart';

void main() {
  group('evaluateGuess', () {
    test('all correct', () {
      expect(evaluateGuess('crane', 'crane'),
          List.filled(5, LetterStatus.correct));
    });

    test('present in wrong position', () {
      final r = evaluateGuess('bezel', 'abide');
      expect(r[0], LetterStatus.present); // b
      expect(r[1], LetterStatus.present); // e
      expect(r[2], LetterStatus.absent); // z
      expect(r[3], LetterStatus.absent); // only one e
      expect(r[4], LetterStatus.absent); // l
    });

    test('duplicate letters: only as many yellows as remain', () {
      final r = evaluateGuess('llama', 'pearl');
      final lStatuses = [r[0], r[1]];
      expect(lStatuses.where((s) => s == LetterStatus.present).length, 1);
      expect(lStatuses.where((s) => s == LetterStatus.absent).length, 1);
    });

    test('green consumes the slot before yellows', () {
      final r = evaluateGuess('babes', 'abbey');
      expect(r[2], LetterStatus.correct);
    });

    test('works for non-five-letter words', () {
      expect(evaluateGuess('cat', 'cat'),
          List.filled(3, LetterStatus.correct));
      expect(evaluateGuess('mango', 'tango')[0], LetterStatus.absent);
    });
  });

  group('hardModeViolation', () {
    test('requires a revealed green in place', () {
      // answer "crane"; guess "crisp" reveals c,r green at 0,1.
      final v = hardModeViolation(['crisp'], 'crane', 'plumb');
      expect(v, isNotNull);
    });

    test('requires a revealed yellow to be reused', () {
      // answer "crane"; guess "trace" -> r,a,e present/correct somewhere.
      final v = hardModeViolation(['saint'], 'crane', 'mommy');
      expect(v, isNotNull); // 'a' was present and must be reused
    });

    test('passes when constraints are met', () {
      final v = hardModeViolation(['crisp'], 'crane', 'crane');
      expect(v, isNull);
    });
  });

  group('daily word', () {
    test('index is deterministic and in range', () {
      final a = dailyIndexFor(DateTime(2024, 1, 1), 500, 5);
      final b = dailyIndexFor(DateTime(2024, 1, 1), 500, 5);
      expect(a, b);
      expect(a >= 0 && a < 500, isTrue);
    });

    test('different lengths rotate independently', () {
      final five = dailyIndexFor(DateTime(2024, 1, 1), 500, 5);
      final six = dailyIndexFor(DateTime(2024, 1, 1), 500, 6);
      expect(five == six, isFalse);
    });

    test('stays in range before the epoch', () {
      final idx = dailyIndexFor(DateTime(1999, 1, 1), 300, 4);
      expect(idx >= 0 && idx < 300, isTrue);
    });
  });

  group('WordleGame', () {
    test('wins when last guess matches', () {
      final g =
          WordleGame(answer: 'crane', mode: GameMode.practice, maxGuesses: 6);
      g.submitGuess('crane');
      expect(g.status, GameStatus.won);
    });

    test('loses after the configured number of guesses', () {
      final g =
          WordleGame(answer: 'crane', mode: GameMode.practice, maxGuesses: 4);
      for (var i = 0; i < 4; i++) {
        g.submitGuess('plumb');
      }
      expect(g.status, GameStatus.lost);
    });

    test('share text shows score, length and grid', () {
      final g =
          WordleGame(answer: 'crane', mode: GameMode.practice, maxGuesses: 6);
      g.submitGuess('crane');
      final text = g.shareText()!;
      expect(text, contains('1/6'));
      expect(text, contains('🟩🟩🟩🟩🟩'));
    });
  });

  group('computeHint', () {
    test('returns a key hint (answer letter) when no guesses yet', () {
      final g =
          WordleGame(answer: 'crane', mode: GameMode.practice, maxGuesses: 6);
      final hint = computeHint(g);
      expect(hint, isA<KeyHint>());
      expect('crane'.contains((hint as KeyHint).letter), isTrue);
    });

    test('points at a misplaced letter on the board when one exists', () {
      final g =
          WordleGame(answer: 'crane', mode: GameMode.practice, maxGuesses: 6);
      g.submitGuess('react'); // r, e, c are present (misplaced)
      final hint = computeHint(g);
      expect(hint, isA<BoardHint>());
      expect((hint as BoardHint).row, 0);
    });

    test('returns null when the game is over', () {
      final g =
          WordleGame(answer: 'crane', mode: GameMode.practice, maxGuesses: 6);
      g.submitGuess('crane');
      expect(computeHint(g), isNull);
    });
  });

  group('GameSettings', () {
    test('round-trips through JSON with bounds clamped', () {
      final s = GameSettings(wordLength: 7, guessCount: 10);
      final restored = GameSettings.decode(s.encode());
      expect(restored.wordLength, 7);
      expect(restored.guessCount, 10);
      expect(restored.configKey, '7x10');
    });

    test('clamps out-of-range values from storage', () {
      final json = '{"wordLength": 99, "guessCount": 1, "hintsPerGame": 99}';
      final s = GameSettings.decode(json);
      expect(s.wordLength, kMaxWordLength);
      expect(s.guessCount, kMinGuesses);
      expect(s.hintsPerGame, kMaxHints);
    });

    test('round-trips hints per game', () {
      final s = GameSettings(hintsPerGame: 4);
      expect(GameSettings.decode(s.encode()).hintsPerGame, 4);
    });
  });

  group('Stats', () {
    test('records a daily win and updates streak', () {
      final stats = Stats();
      final g = WordleGame(
          answer: 'crane',
          mode: GameMode.daily,
          maxGuesses: 6,
          puzzleNumber: 5);
      g.submitGuess('crane');
      stats.recordDaily(g);
      expect(stats.played, 1);
      expect(stats.wins, 1);
      expect(stats.currentStreak, 1);
    });

    test('is idempotent for the same puzzle number', () {
      final stats = Stats();
      final g = WordleGame(
          answer: 'crane',
          mode: GameMode.daily,
          maxGuesses: 6,
          puzzleNumber: 5);
      g.submitGuess('crane');
      stats.recordDaily(g);
      stats.recordDaily(g);
      expect(stats.played, 1);
    });

    test('round-trips through JSON', () {
      final stats =
          Stats(played: 3, wins: 2, currentStreak: 2, maxStreak: 4);
      final restored = Stats.decode(stats.encode());
      expect(restored.played, 3);
      expect(restored.maxStreak, 4);
    });
  });
}
