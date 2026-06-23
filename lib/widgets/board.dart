import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme.dart';

/// Accent color used for the flashing hint arrow.
const Color kHintAccent = Color(0xFFFFC107);

/// The grid of letter tiles, sized to the game's word length and guess count.
class Board extends StatelessWidget {
  const Board({
    super.key,
    required this.game,
    required this.currentInput,
    required this.colors,
    required this.shake,
    required this.revealRow,
    this.reduceMotion = false,
    this.hintCell,
    this.hintSerial = 0,
  });

  final WordleGame game;

  /// Letters typed into the active row but not yet submitted.
  final String currentInput;
  final GameColors colors;

  /// Horizontal shake animation for the active row (e.g. invalid word).
  final Animation<double> shake;

  /// The row index that should play its reveal flip animation, or null.
  final int? revealRow;

  /// When true, skip the flip/pop animations (Battery Saver).
  final bool reduceMotion;

  /// The tile to flash a hint arrow on, as (row, col), or null.
  final (int, int)? hintCell;

  /// Bumped each time a board hint is requested, to re-trigger the flash.
  final int hintSerial;

  /// Per-column flip delay used both here and by the screen's reveal timing.
  static Duration flipDelay(int col) => Duration(milliseconds: col * 200);

  @override
  Widget build(BuildContext context) {
    final cols = game.wordLength;
    final rows = game.maxGuesses;
    final evaluations = game.evaluations;
    final activeRow = game.currentRow;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = rows > 8 ? 4.0 : 5.0;
        final maxTileW = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final maxTileH = (constraints.maxHeight - gap * (rows - 1)) / rows;
        final tile = math.min(maxTileW, maxTileH).clamp(0.0, 64.0);
        final boardWidth = tile * cols + gap * (cols - 1);

        return Center(
          child: SizedBox(
            width: boardWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var row = 0; row < rows; row++)
                  Padding(
                    padding:
                        EdgeInsets.only(bottom: row == rows - 1 ? 0 : gap),
                    child: _buildRow(
                      row: row,
                      tile: tile,
                      gap: gap,
                      cols: cols,
                      evaluations: evaluations,
                      activeRow: activeRow,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow({
    required int row,
    required double tile,
    required double gap,
    required int cols,
    required List<List<LetterStatus>> evaluations,
    required int? activeRow,
  }) {
    final isActive = row == activeRow;
    final isSubmitted = row < game.guesses.length;
    final letters =
        isSubmitted ? game.guesses[row] : (isActive ? currentInput : '');

    Widget rowWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var col = 0; col < cols; col++)
          Padding(
            padding: EdgeInsets.only(right: col == cols - 1 ? 0 : gap),
            child: _Tile(
              size: tile,
              letter: col < letters.length ? letters[col].toUpperCase() : '',
              status:
                  isSubmitted ? evaluations[row][col] : LetterStatus.empty,
              colors: colors,
              reveal: revealRow == row,
              reduceMotion: reduceMotion,
              flipDelay: flipDelay(col),
              flashArrow: hintCell != null &&
                  hintCell!.$1 == row &&
                  hintCell!.$2 == col,
              flashSerial: hintSerial,
            ),
          ),
      ],
    );

    if (isActive) {
      rowWidget = AnimatedBuilder(
        animation: shake,
        builder: (context, child) {
          final dx =
              math.sin(shake.value * math.pi * 4) * 8 * (1 - shake.value);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: rowWidget,
      );
    }

    return rowWidget;
  }
}

/// A single letter tile that pops when a letter is entered, flips to reveal its
/// evaluated color, shows a small placement icon, and can flash a hint arrow.
class _Tile extends StatefulWidget {
  const _Tile({
    required this.size,
    required this.letter,
    required this.status,
    required this.colors,
    required this.reveal,
    required this.reduceMotion,
    required this.flipDelay,
    required this.flashArrow,
    required this.flashSerial,
  });

  final double size;
  final String letter;
  final LetterStatus status;
  final GameColors colors;
  final bool reveal;
  final bool reduceMotion;
  final Duration flipDelay;
  final bool flashArrow;
  final int flashSerial;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 1.0,
    upperBound: 1.08,
  );
  late final AnimationController _arrow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  LetterStatus _shownStatus = LetterStatus.empty;

  @override
  void initState() {
    super.initState();
    _shownStatus = widget.status;
    if (widget.reveal &&
        !widget.reduceMotion &&
        widget.status != LetterStatus.empty) {
      _startReveal();
    }
  }

  @override
  void didUpdateWidget(covariant _Tile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.reduceMotion &&
        widget.letter.isNotEmpty &&
        oldWidget.letter.isEmpty &&
        widget.status == LetterStatus.empty) {
      _pop.forward(from: 1.0).then((_) => _pop.reverse());
    }

    if (widget.reveal &&
        !widget.reduceMotion &&
        widget.status != LetterStatus.empty &&
        oldWidget.status == LetterStatus.empty) {
      _startReveal();
    } else if ((!widget.reveal || widget.reduceMotion) &&
        widget.status != _shownStatus) {
      _shownStatus = widget.status;
      _flip.value = 0;
    }

    if (widget.flashArrow && widget.flashSerial != oldWidget.flashSerial) {
      _arrow.forward(from: 0);
    }
  }

  Future<void> _startReveal() async {
    await Future<void>.delayed(widget.flipDelay);
    if (!mounted) return;
    _flip.forward(from: 0);
  }

  @override
  void dispose() {
    _flip.dispose();
    _pop.dispose();
    _arrow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return AnimatedBuilder(
      animation: Listenable.merge([_flip, _pop, _arrow]),
      builder: (context, _) {
        final t = _flip.value;
        if (t >= 0.5 && _shownStatus != widget.status) {
          _shownStatus = widget.status;
        }
        final angle = t * math.pi;
        final displayAngle = angle > math.pi / 2 ? math.pi - angle : angle;

        final status = _shownStatus;
        final filled = status != LetterStatus.empty;
        final hasLetter = widget.letter.isNotEmpty;

        final bg = colors.forStatus(status);
        final borderColor = filled
            ? bg
            : (hasLetter ? colors.pendingBorder : colors.tileBorder);
        final textColor = filled ? colors.textOn(bg) : colors.tileText;

        return Transform.scale(
          scale: _pop.value,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(displayAngle),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: filled ? bg : colors.emptyTile,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      widget.letter,
                      style: TextStyle(
                        fontSize: widget.size * 0.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (filled) _placementIcon(status, textColor),
                  if (widget.flashArrow && _arrow.value > 0 && _arrow.value < 1)
                    _hintArrow(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// A small corner glyph: a check for a correctly-placed letter, a dot for a
  /// present-but-misplaced letter. Doubles as a color-blind cue.
  Widget _placementIcon(LetterStatus status, Color color) {
    final icon = switch (status) {
      LetterStatus.correct => Icons.check,
      LetterStatus.present => Icons.circle,
      _ => null,
    };
    if (icon == null) return const SizedBox.shrink();
    return Positioned(
      top: 2,
      left: 2,
      child: Icon(
        icon,
        size: widget.size * (status == LetterStatus.present ? 0.16 : 0.26),
        color: color.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _hintArrow() {
    // Pulse the arrow's opacity a few times across the animation.
    final pulse = (math.sin(_arrow.value * math.pi * 6) + 1) / 2;
    return Positioned.fill(
      child: Center(
        child: Icon(
          Icons.swap_horiz,
          size: widget.size * 0.62,
          color: kHintAccent.withValues(alpha: 0.4 + 0.6 * pulse),
        ),
      ),
    );
  }
}
