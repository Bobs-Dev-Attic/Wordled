import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme.dart';

/// Shows the "How To Play" sheet, styled after the official game.
Future<void> showHowToPlay(
  BuildContext context,
  GameColors colors, {
  required int wordLength,
  required int maxGuesses,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: HowToPlayContent(
          colors: colors,
          wordLength: wordLength,
          maxGuesses: maxGuesses,
        ),
      ),
    ),
  );
}

class HowToPlayContent extends StatelessWidget {
  const HowToPlayContent({
    super.key,
    required this.colors,
    required this.wordLength,
    required this.maxGuesses,
  });

  final GameColors colors;
  final int wordLength;
  final int maxGuesses;

  @override
  Widget build(BuildContext context) {
    final textColor = colors.tileText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Text('How To Play',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 4),
            Text('Guess the WORDLED in $maxGuesses tries.',
                style: TextStyle(fontSize: 18, color: textColor)),
            const SizedBox(height: 14),
            _Bullet('Each guess must be a valid $wordLength-letter word.',
                textColor),
            _Bullet(
                'The color of the tiles will change to show how close your '
                'guess was to the word.',
                textColor),
            const SizedBox(height: 18),
            Text('Examples',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 12),
            _Example(
              word: 'WORDY',
              index: 0,
              status: LetterStatus.correct,
              explanation: 'W is in the word and in the correct spot.',
              colors: colors,
            ),
            const SizedBox(height: 14),
            _Example(
              word: 'LIGHT',
              index: 1,
              status: LetterStatus.present,
              explanation: 'I is in the word but in the wrong spot.',
              colors: colors,
            ),
            const SizedBox(height: 14),
            _Example(
              word: 'ROGUE',
              index: 3,
              status: LetterStatus.absent,
              explanation: 'U is not in the word in any spot.',
              colors: colors,
            ),
            const SizedBox(height: 18),
            Divider(color: colors.tileBorder),
            const SizedBox(height: 10),
            Text('Tile & key markers',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 8),
            _MarkerRow(
              icon: Icons.check,
              text: 'A check marks a letter in the correct spot.',
              colors: colors,
            ),
            const SizedBox(height: 6),
            _MarkerRow(
              icon: Icons.circle,
              iconSize: 9,
              text: 'A dot marks a correct letter in the wrong spot.',
              colors: colors,
            ),
            const SizedBox(height: 6),
            _MarkerRow(
              icon: Icons.keyboard,
              text: 'Letters not in the word are dimmed with a diagonal line '
                  'across the key.',
              colors: colors,
            ),
            const SizedBox(height: 16),
            Text('Hints',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 6),
            Text(
              'Tap the 💡 hint button (next to the stats icon) to either flash a '
              'useful keyboard letter or point an arrow at a misplaced letter on '
              'the board. The number of hints per game is set in Settings.',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 16),
            Divider(color: colors.tileBorder),
            const SizedBox(height: 8),
            Text(
              'A new daily puzzle is released every day at midnight. Choose a '
              'theme, word length, difficulty and more in Settings. Wordled '
              'works fully offline once installed — play it in airplane mode.',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({
    required this.icon,
    required this.text,
    required this.colors,
    this.iconSize = 18,
  });

  final IconData icon;
  final String text;
  final GameColors colors;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Center(
            child: Icon(icon, size: iconSize, color: colors.tileText),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: colors.tileText)),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: TextStyle(fontSize: 15, color: color)),
          Expanded(
              child:
                  Text(text, style: TextStyle(fontSize: 15, color: color))),
        ],
      ),
    );
  }
}

class _Example extends StatelessWidget {
  const _Example({
    required this.word,
    required this.index,
    required this.status,
    required this.explanation,
    required this.colors,
  });

  final String word;
  final int index;
  final LetterStatus status;
  final String explanation;
  final GameColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < word.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _MiniTile(
                  letter: word[i],
                  status: i == index ? status : LetterStatus.empty,
                  colors: colors,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: colors.tileText),
            children: [
              TextSpan(
                  text: word[index],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: explanation.substring(1)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({
    required this.letter,
    required this.status,
    required this.colors,
  });

  final String letter;
  final LetterStatus status;
  final GameColors colors;

  @override
  Widget build(BuildContext context) {
    final filled = status != LetterStatus.empty;
    final bg = filled ? colors.forStatus(status) : colors.emptyTile;
    final border = filled ? bg : colors.tileBorder;
    final textColor = filled ? colors.textOn(bg) : colors.tileText;
    final marker = switch (status) {
      LetterStatus.correct => Icons.check,
      LetterStatus.present => Icons.circle,
      _ => null,
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 2),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          if (marker != null)
            Positioned(
              top: 2,
              left: 2,
              child: Icon(
                marker,
                size: status == LetterStatus.present ? 7 : 11,
                color: textColor.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}
