import 'dart:convert';

import 'game.dart';

/// Aggregate statistics for one board configuration, persisted locally.
class Stats {
  Stats({
    this.played = 0,
    this.wins = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    Map<int, int>? distribution,
    this.lastDailyNumber,
  }) : distribution = distribution ?? <int, int>{};

  int played;
  int wins;
  int currentStreak;
  int maxStreak;

  /// Map of guess-count -> number of daily wins achieved in that many guesses.
  final Map<int, int> distribution;

  /// Puzzle number of the most recently completed daily game (for streaks).
  int? lastDailyNumber;

  int get losses => played - wins;
  int get winPercent => played == 0 ? 0 : ((wins / played) * 100).round();

  /// Records the outcome of a finished daily [game]. Idempotent per puzzle.
  void recordDaily(WordleGame game) {
    if (game.mode != GameMode.daily || !game.isOver) return;
    final number = game.puzzleNumber;
    if (number == null || number == lastDailyNumber) return;

    final won = game.status == GameStatus.won;
    final consecutive =
        lastDailyNumber != null && number == lastDailyNumber! + 1;

    played += 1;
    if (won) {
      wins += 1;
      distribution[game.guesses.length] =
          (distribution[game.guesses.length] ?? 0) + 1;
      currentStreak = consecutive ? currentStreak + 1 : 1;
      if (currentStreak > maxStreak) maxStreak = currentStreak;
    } else {
      currentStreak = 0;
    }
    lastDailyNumber = number;
  }

  Map<String, dynamic> toJson() => {
        'played': played,
        'wins': wins,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'distribution': distribution.map((k, v) => MapEntry(k.toString(), v)),
        'lastDailyNumber': lastDailyNumber,
      };

  factory Stats.fromJson(Map<String, dynamic> json) {
    final dist = <int, int>{};
    final raw = json['distribution'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final key = int.tryParse(k.toString());
        if (key != null) dist[key] = (v as num).toInt();
      });
    }
    return Stats(
      played: (json['played'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      maxStreak: (json['maxStreak'] as num?)?.toInt() ?? 0,
      distribution: dist,
      lastDailyNumber: (json['lastDailyNumber'] as num?)?.toInt(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory Stats.decode(String source) =>
      Stats.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
