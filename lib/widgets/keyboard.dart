import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme.dart';
import 'board.dart' show kHintAccent;

/// The on-screen QWERTY keyboard with per-key color feedback.
class Keyboard extends StatelessWidget {
  const Keyboard({
    super.key,
    required this.keyStatuses,
    required this.colors,
    required this.onKey,
    required this.onEnter,
    required this.onBackspace,
    this.flashLetter,
    this.flashSerial = 0,
  });

  final Map<String, LetterStatus> keyStatuses;
  final GameColors colors;
  final ValueChanged<String> onKey;
  final VoidCallback onEnter;
  final VoidCallback onBackspace;

  /// A keyboard letter to flash as a hint, or null.
  final String? flashLetter;

  /// Bumped each time a key hint is requested, to re-trigger the flash.
  final int flashSerial;

  /// Slightly more rounded corners than the original, per design request.
  static const double _radius = 8;

  static const _rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildRow(_rows[i], isLast: i == _rows.length - 1),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRow(String letters, {required bool isLast}) {
    final keys = <Widget>[];
    if (isLast) {
      keys.add(_SpecialKey(label: 'ENTER', onTap: onEnter, colors: colors));
    }
    for (final ch in letters.split('')) {
      keys.add(_LetterKey(
        letter: ch,
        status: keyStatuses[ch] ?? LetterStatus.empty,
        colors: colors,
        radius: _radius,
        onTap: () => onKey(ch),
        isFlashing: flashLetter == ch,
        flashSerial: flashSerial,
      ));
    }
    if (isLast) {
      keys.add(_SpecialKey(
        icon: Icons.backspace_outlined,
        onTap: onBackspace,
        colors: colors,
      ));
    }
    return keys;
  }
}

class _LetterKey extends StatefulWidget {
  const _LetterKey({
    required this.letter,
    required this.status,
    required this.colors,
    required this.radius,
    required this.onTap,
    required this.isFlashing,
    required this.flashSerial,
  });

  final String letter;
  final LetterStatus status;
  final GameColors colors;
  final double radius;
  final VoidCallback onTap;
  final bool isFlashing;
  final int flashSerial;

  @override
  State<_LetterKey> createState() => _LetterKeyState();
}

class _LetterKeyState extends State<_LetterKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isFlashing) _flash.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _LetterKey oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlashing &&
        (widget.flashSerial != oldWidget.flashSerial || !oldWidget.isFlashing)) {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final status = widget.status;
    final colored = status != LetterStatus.empty;
    final struck = status == LetterStatus.absent;
    final baseBg = colored ? colors.forStatus(status) : colors.keyDefault;
    // Absent keys are darkened and get a faint diagonal strike across the cap.
    final bg = struck ? _darken(baseBg, 0.32) : baseBg;
    final textColor = colored ? colors.textOn(bg) : colors.keyText;

    return _KeyCap(
      radius: widget.radius,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flash,
        builder: (context, child) {
          final t = _flash.value;
          // A few quick pulses that fade out over the animation.
          final pulse =
              (t > 0 && t < 1) ? math.sin(t * math.pi * 5).abs() * (1 - t) : 0.0;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(widget.radius),
              border: pulse > 0
                  ? Border.all(color: kHintAccent, width: 2.5)
                  : null,
              boxShadow: pulse > 0
                  ? [
                      BoxShadow(
                        color: kHintAccent.withValues(alpha: pulse),
                        blurRadius: 12 * pulse,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              widget.letter.toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (struck)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.radius),
                  child: CustomPaint(
                    painter: _DiagonalStrikePainter(
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Darkens [c] by [amount] (0–1) via HSL lightness.
  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Paints a single diagonal line from the bottom-left to the top-right corner.
class _DiagonalStrikePainter extends CustomPainter {
  const _DiagonalStrikePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DiagonalStrikePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SpecialKey extends StatelessWidget {
  const _SpecialKey({
    this.label,
    this.icon,
    required this.onTap,
    required this.colors,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final GameColors colors;

  @override
  Widget build(BuildContext context) {
    return _KeyCap(
      flex: 3,
      radius: 8,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.keyDefault,
          borderRadius: BorderRadius.circular(8),
        ),
        child: icon != null
            ? Icon(icon, color: colors.keyText, size: 22)
            : Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.keyText,
                ),
              ),
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({
    required this.child,
    required this.onTap,
    required this.radius,
    this.flex = 2,
  });

  final Widget child;
  final VoidCallback onTap;
  final double radius;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: SizedBox(
          height: 56,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
