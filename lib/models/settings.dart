import 'dart:convert';

import 'package:flutter/material.dart';

import 'palette.dart';

/// How strict the game is.
enum Difficulty {
  /// Relaxed: any sequence of letters of the right length is accepted as a
  /// guess (no dictionary check).
  easy,

  /// Standard: guesses must be real words.
  normal,

  /// Hard: guesses must be real words AND must reuse every revealed hint.
  hard,
}

extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.normal => 'Normal',
        Difficulty.hard => 'Hard',
      };

  String get description => switch (this) {
        Difficulty.easy => 'Any letters accepted — no dictionary check.',
        Difficulty.normal => 'Guesses must be real words.',
        Difficulty.hard => 'Real words only, and revealed hints must be reused.',
      };
}

/// Bounds for the configurable board.
const int kMinWordLength = 3;
const int kMaxWordLength = 9;
const int kMinGuesses = 4;
const int kMaxGuesses = 20;

/// Persisted, user-editable game settings.
class GameSettings {
  GameSettings({
    this.wordLength = 5,
    this.guessCount = 6,
    this.difficulty = Difficulty.normal,
    this.themeMode = ThemeMode.dark,
    this.paletteId = 'classic',
    Palette? customPalette,
  }) : customPalette = customPalette ?? Palette.defaultCustom;

  int wordLength;
  int guessCount;
  Difficulty difficulty;
  ThemeMode themeMode;

  /// Either a preset id, or [Palette.customId] for the custom palette.
  String paletteId;
  Palette customPalette;

  bool get usesCustomPalette => paletteId == Palette.customId;

  /// The active palette, resolved against the current theme brightness for the
  /// classic preset (which has light/dark variants).
  Palette resolvedPalette(Brightness brightness) {
    if (usesCustomPalette) return customPalette;
    if (paletteId == 'classic') {
      return brightness == Brightness.light
          ? Palette.classic
          : Palette.classicDark;
    }
    return Palette.presetById(paletteId);
  }

  GameSettings copyWith({
    int? wordLength,
    int? guessCount,
    Difficulty? difficulty,
    ThemeMode? themeMode,
    String? paletteId,
    Palette? customPalette,
  }) {
    return GameSettings(
      wordLength: wordLength ?? this.wordLength,
      guessCount: guessCount ?? this.guessCount,
      difficulty: difficulty ?? this.difficulty,
      themeMode: themeMode ?? this.themeMode,
      paletteId: paletteId ?? this.paletteId,
      customPalette: customPalette ?? this.customPalette,
    );
  }

  /// A short signature used to scope per-configuration save data (stats and
  /// daily progress are kept separately per board size).
  String get configKey => '${wordLength}x$guessCount';

  Map<String, dynamic> toJson() => {
        'wordLength': wordLength,
        'guessCount': guessCount,
        'difficulty': difficulty.name,
        'themeMode': themeMode.name,
        'paletteId': paletteId,
        'customPalette': customPalette.toJson(),
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      wordLength: (json['wordLength'] as num?)?.toInt().clamp(
                kMinWordLength,
                kMaxWordLength,
              ) ??
          5,
      guessCount: (json['guessCount'] as num?)?.toInt().clamp(
                kMinGuesses,
                kMaxGuesses,
              ) ??
          6,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => Difficulty.normal,
      ),
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == json['themeMode'],
        orElse: () => ThemeMode.dark,
      ),
      paletteId: json['paletteId'] as String? ?? 'classic',
      customPalette: json['customPalette'] is Map
          ? Palette.fromJson(
              (json['customPalette'] as Map).cast<String, dynamic>())
          : Palette.defaultCustom,
    );
  }

  String encode() => jsonEncode(toJson());

  factory GameSettings.decode(String source) =>
      GameSettings.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
