import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme.dart';
import 'board.dart' show kHintAccent;
import 'fireworks.dart' show celebrationColor;

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
    this.celebrateSerial = 0,
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

  /// Bumped on a win to run a rainbow color-cycle across the keys.
  final int celebrateSerial;

  /// Slightly more rounded corners than the original, per design request.
  static const double _radius = 8;

  static const _rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
  static const _allLetters = 'qwertyuiopasdfghjklzxcvbnm';

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
        celebrateSerial: celebrateSerial,
        celebratePhase: _allLetters.indexOf(ch) / _allLetters.length,
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
    required this.celebrateSerial,
    required this.celebratePhase,
  });

  final String letter;
  final LetterStatus status;
  final GameColors colors;
  final double radius;
  final VoidCallback onTap;
  final bool isFlashing;
  final int flashSerial;
  final int celebrateSerial;
  final double celebratePhase;

  @override
  State<_LetterKey> createState() => _LetterKeyState();
}

class _LetterKeyState extends State<_LetterKey>
    with TickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final AnimationController _celebrate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
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
    if (widget.celebrateSerial != oldWidget.celebrateSerial) {
      _celebrate.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final status = widget.status;
    final colored = status != LetterStatus.empty;

    return _KeyCap(
      radius: widget.radius,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flash, _celebrate]),
        builder: (context, _) {
          // Recomputed each tick so the celebration color cycles.
          final celebrating = _celebrate.value > 0 && _celebrate.value < 1;
          final bg = celebrating
              ? celebrationColor(_celebrate.value, widget.celebratePhase)
              : (colored ? colors.forStatus(status) : colors.keyDefault);
          final baseText =
              (colored || celebrating) ? colors.textOn(bg) : colors.keyText;
          final textColor = (status == LetterStatus.absent && !celebrating)
              ? Color.lerp(baseText, bg, 0.5)!
              : baseText;

          final t = _flash.value;
          // A few quick pulses that fade out over the animation.
          final pulse =
              (t > 0 && t < 1) ? math.sin(t * math.pi * 5).abs() * (1 - t) : 0.0;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Subtle diagonal gradient gives the keys a little depth.
              gradient: GameColors.diagonalGradient(bg, delta: 0.04),
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
            child: Text(
              widget.letter.toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          );
        },
      ),
    );
  }
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
          gradient: GameColors.diagonalGradient(colors.keyDefault, delta: 0.04),
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
