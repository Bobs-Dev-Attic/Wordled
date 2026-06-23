import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/stats.dart';
import '../util/format.dart';

/// A modal showing aggregate statistics and, when a game just finished, the
/// guess distribution plus share / play-again actions.
class StatsDialog extends StatelessWidget {
  const StatsDialog({
    super.key,
    required this.stats,
    required this.maxGuesses,
    this.finishedGame,
    this.onShare,
    this.onNewWord,
  });

  final Stats stats;
  final int maxGuesses;
  final WordleGame? finishedGame;
  final VoidCallback? onShare;

  /// Starts a fresh game with a new random word. Offered on game over.
  final VoidCallback? onNewWord;

  @override
  Widget build(BuildContext context) {
    final game = finishedGame;
    final justWon = game != null && game.status == GameStatus.won;
    final justLost = game != null && game.status == GameStatus.lost;

    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (justWon)
            _titleLine(_praise(game.guesses.length))
          else if (justLost) ...[
            _titleLine(_encouragement(game.answer)),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'The word was ${game.answer.toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
          const Text('STATISTICS',
              style: TextStyle(fontSize: 14, letterSpacing: 1)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(value: commas(stats.played), label: 'Played'),
                _Stat(value: '${stats.winPercent}', label: 'Win %'),
                _Stat(
                    value: commas(stats.currentStreak),
                    label: 'Current\nStreak'),
                _Stat(value: commas(stats.maxStreak), label: 'Max\nStreak'),
              ],
            ),
            const SizedBox(height: 20),
            const Text('GUESS DISTRIBUTION',
                style: TextStyle(fontSize: 13, letterSpacing: 1)),
            const SizedBox(height: 8),
            _Distribution(
              stats: stats,
              maxGuesses: maxGuesses,
              highlight: justWon ? game.guesses.length : null,
            ),
          ],
        ),
      ),
      actions: [
        if (game != null && onNewWord != null)
          if (justLost)
            FilledButton(
                onPressed: onNewWord, child: const Text('New word'))
          else
            TextButton(onPressed: onNewWord, child: const Text('New word')),
        if (game != null && onShare != null)
          if (justWon)
            FilledButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share'),
            )
          else
            TextButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share'),
            ),
        if (game == null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }

  Widget _titleLine(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  String _praise(int guesses) => switch (guesses) {
        1 => 'Genius!',
        2 => 'Magnificent!',
        3 => 'Impressive!',
        4 => 'Splendid!',
        5 => 'Great!',
        _ => 'Phew!',
      };

  /// A stable-per-word encouragement message for a loss.
  String _encouragement(String answer) {
    const messages = [
      'So close — you\'ll get the next one!',
      'Don\'t give up, give it another go!',
      'Tough one! Shake it off and try again.',
      'Nice effort — a fresh word awaits.',
      'Almost had it! Ready for another?',
      'Better luck on the next word!',
    ];
    return messages[answer.hashCode.abs() % messages.length];
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w400)),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, height: 1.1)),
      ],
    );
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({
    required this.stats,
    required this.maxGuesses,
    this.highlight,
  });
  final Stats stats;
  final int maxGuesses;
  final int? highlight;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        stats.distribution.values.fold<int>(1, (m, v) => v > m ? v : m);
    return Column(
      children: [
        for (var i = 1; i <= maxGuesses; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text('$i', style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final count = stats.distribution[i] ?? 0;
                      final width = (count / maxCount) * c.maxWidth;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: width.clamp(24.0, c.maxWidth),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          alignment: Alignment.centerRight,
                          color: i == highlight
                              ? const Color(0xFF538D4E)
                              : const Color(0xFF3A3A3C),
                          child: Text(commas(count),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
