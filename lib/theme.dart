import 'package:flutter/material.dart';

import 'models/game.dart';
import 'models/palette.dart';

/// Concrete colors used to paint the board and keyboard, derived from a
/// [Palette] (the correct/present/absent colors) plus brightness-dependent
/// "chrome" colors for empty tiles, borders, and keys.
class GameColors {
  const GameColors({
    required this.correct,
    required this.present,
    required this.absent,
    required this.emptyTile,
    required this.tileBorder,
    required this.pendingBorder,
    required this.tileText,
    required this.onColored,
    required this.keyDefault,
    required this.keyText,
    required this.background,
  });

  final Color correct;
  final Color present;
  final Color absent;
  final Color emptyTile;
  final Color tileBorder;
  final Color pendingBorder;
  final Color tileText;
  final Color onColored;
  final Color keyDefault;
  final Color keyText;
  final Color background;

  Color forStatus(LetterStatus status) => switch (status) {
        LetterStatus.correct => correct,
        LetterStatus.present => present,
        LetterStatus.absent => absent,
        LetterStatus.empty => emptyTile,
      };

  factory GameColors.from(Palette palette, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return GameColors(
      correct: palette.correct,
      present: palette.present,
      absent: palette.absent,
      emptyTile: Colors.transparent,
      tileBorder: dark ? const Color(0xFF3A3A3C) : const Color(0xFFD3D6DA),
      pendingBorder: dark ? const Color(0xFF565758) : const Color(0xFF878A8C),
      tileText: dark ? Colors.white : const Color(0xFF1A1A1B),
      onColored: Colors.white,
      keyDefault: dark ? const Color(0xFF818384) : const Color(0xFFD3D6DA),
      keyText: dark ? Colors.white : const Color(0xFF1A1A1B),
      background: dark ? const Color(0xFF121213) : Colors.white,
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? const Color(0xFF121213) : Colors.white;
  final onBg = dark ? Colors.white : const Color(0xFF1A1A1B);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF538D4E),
      brightness: brightness,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      foregroundColor: onBg,
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 5,
        color: onBg,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? const Color(0xFF1E1E20) : Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? Colors.white : const Color(0xFF1A1A1B),
      contentTextStyle: TextStyle(
        color: dark ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
