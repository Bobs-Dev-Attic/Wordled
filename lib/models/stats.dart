import 'dart:convert';

/// Aggregate statistics across every finished game — all word lengths, guess
/// counts and modes. Also tracks solve time (first → last guess) and hint use.
class Stats {
  Stats({
    this.played = 0,
    this.wins = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    Map<int, int>? distribution,
    Map<int, int>? playedByLength,
    Map<int, int>? winsByLength,
    this.totalHints = 0,
    this.solveCount = 0,
    this.totalSolveMs = 0,
    this.bestSolveMs = 0,
  })  : distribution = distribution ?? <int, int>{},
        playedByLength = playedByLength ?? <int, int>{},
        winsByLength = winsByLength ?? <int, int>{};

  int played;
  int wins;
  int currentStreak;
  int maxStreak;

  /// Wins bucketed by how many guesses they took (any guess number).
  final Map<int, int> distribution;

  /// Games played / won, bucketed by word length.
  final Map<int, int> playedByLength;
  final Map<int, int> winsByLength;

  /// Total hints used across all games.
  int totalHints;

  /// Won games that have a recorded solve time, and the running totals/best.
  int solveCount;
  int totalSolveMs;
  int bestSolveMs;

  int get losses => played - wins;
  int get winPercent => played == 0 ? 0 : ((wins / played) * 100).round();

  /// Average guesses per win (e.g. 3.8), or 0 when there are no wins.
  double get averageGuesses {
    if (wins == 0) return 0;
    var total = 0;
    distribution.forEach((guesses, count) => total += guesses * count);
    return total / wins;
  }

  /// Average solve time across timed wins, or null if none.
  Duration? get averageSolve =>
      solveCount == 0 ? null : Duration(milliseconds: totalSolveMs ~/ solveCount);

  Duration? get bestSolve =>
      bestSolveMs == 0 ? null : Duration(milliseconds: bestSolveMs);

  /// Records a finished game of any length / guess count / mode.
  void record({
    required bool won,
    required int guesses,
    required int wordLength,
    required int hints,
    Duration? solveTime,
  }) {
    played += 1;
    totalHints += hints;
    playedByLength[wordLength] = (playedByLength[wordLength] ?? 0) + 1;
    if (won) {
      wins += 1;
      winsByLength[wordLength] = (winsByLength[wordLength] ?? 0) + 1;
      distribution[guesses] = (distribution[guesses] ?? 0) + 1;
      currentStreak += 1;
      if (currentStreak > maxStreak) maxStreak = currentStreak;
      if (solveTime != null) {
        final ms = solveTime.inMilliseconds;
        solveCount += 1;
        totalSolveMs += ms;
        if (bestSolveMs == 0 || ms < bestSolveMs) bestSolveMs = ms;
      }
    } else {
      currentStreak = 0;
    }
  }

  static Map<int, int> _toIntKeys(Object? raw) {
    final result = <int, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final key = int.tryParse(k.toString());
        if (key != null) result[key] = (v as num).toInt();
      });
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'played': played,
        'wins': wins,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'distribution': distribution.map((k, v) => MapEntry(k.toString(), v)),
        'playedByLength':
            playedByLength.map((k, v) => MapEntry(k.toString(), v)),
        'winsByLength': winsByLength.map((k, v) => MapEntry(k.toString(), v)),
        'totalHints': totalHints,
        'solveCount': solveCount,
        'totalSolveMs': totalSolveMs,
        'bestSolveMs': bestSolveMs,
      };

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        played: (json['played'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
        maxStreak: (json['maxStreak'] as num?)?.toInt() ?? 0,
        distribution: _toIntKeys(json['distribution']),
        playedByLength: _toIntKeys(json['playedByLength']),
        winsByLength: _toIntKeys(json['winsByLength']),
        totalHints: (json['totalHints'] as num?)?.toInt() ?? 0,
        solveCount: (json['solveCount'] as num?)?.toInt() ?? 0,
        totalSolveMs: (json['totalSolveMs'] as num?)?.toInt() ?? 0,
        bestSolveMs: (json['bestSolveMs'] as num?)?.toInt() ?? 0,
      );

  String encode() => jsonEncode(toJson());

  factory Stats.decode(String source) =>
      Stats.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
