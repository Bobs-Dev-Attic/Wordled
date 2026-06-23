import 'package:flutter/material.dart';

import '../models/game.dart';
import '../theme.dart';

/// The on-screen QWERTY keyboard with per-key color feedback.
class Keyboard extends StatelessWidget {
  const Keyboard({
    super.key,
    required this.keyStatuses,
    required this.colors,
    required this.onKey,
    required this.onEnter,
    required this.onBackspace,
  });

  final Map<String, LetterStatus> keyStatuses;
  final GameColors colors;
  final ValueChanged<String> onKey;
  final VoidCallback onEnter;
  final VoidCallback onBackspace;

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

class _LetterKey extends StatelessWidget {
  const _LetterKey({
    required this.letter,
    required this.status,
    required this.colors,
    required this.radius,
    required this.onTap,
  });

  final String letter;
  final LetterStatus status;
  final GameColors colors;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colored = status != LetterStatus.empty;
    final bg = colored ? colors.forStatus(status) : colors.keyDefault;
    return _KeyCap(
      radius: radius,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colored ? colors.onColored : colors.keyText,
          ),
        ),
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
