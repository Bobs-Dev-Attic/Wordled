import 'package:flutter/material.dart';

import 'game.dart';

/// The set of tile/key colors used to render evaluations. A palette may be a
/// simple color triple (correct/present/absent) or a full "theme" that also
/// overrides the background and chrome colors and forces a brightness.
@immutable
class Palette {
  const Palette({
    required this.id,
    required this.name,
    required this.correct,
    required this.present,
    required this.absent,
    this.forcedBrightness,
    this.background,
    this.tileBorder,
    this.keyDefault,
    this.onSurface,
    this.reduceMotion = false,
  });

  /// Stable identifier persisted in settings.
  final String id;
  final String name;
  final Color correct;
  final Color present;
  final Color absent;

  // Optional full-theme overrides (null = derive from brightness).
  final Brightness? forcedBrightness;
  final Color? background;
  final Color? tileBorder;
  final Color? keyDefault;
  final Color? onSurface;

  /// When true, the board skips its flip/pop animations (used by Battery Saver).
  final bool reduceMotion;

  Color forStatus(LetterStatus status) => switch (status) {
        LetterStatus.correct => correct,
        LetterStatus.present => present,
        LetterStatus.absent => absent,
        LetterStatus.empty => Colors.transparent,
      };

  Palette copyWith({String? name, Color? correct, Color? present, Color? absent}) {
    return Palette(
      id: id,
      name: name ?? this.name,
      correct: correct ?? this.correct,
      present: present ?? this.present,
      absent: absent ?? this.absent,
      forcedBrightness: forcedBrightness,
      background: background,
      tileBorder: tileBorder,
      keyDefault: keyDefault,
      onSurface: onSurface,
      reduceMotion: reduceMotion,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'correct': correct.toARGB32(),
        'present': present.toARGB32(),
        'absent': absent.toARGB32(),
      };

  factory Palette.fromJson(Map<String, dynamic> json) => Palette(
        id: json['id'] as String? ?? customId,
        name: json['name'] as String? ?? 'Custom',
        correct: Color((json['correct'] as num).toInt()),
        present: Color((json['present'] as num).toInt()),
        absent: Color((json['absent'] as num).toInt()),
      );

  static const String customId = 'custom';

  // ---- Presets --------------------------------------------------------------

  static const classic = Palette(
    id: 'classic',
    name: 'Classic',
    correct: Color(0xFF6AAA64),
    present: Color(0xFFC9B458),
    absent: Color(0xFF787C7E),
  );

  static const classicDark = Palette(
    id: 'classic',
    name: 'Classic',
    correct: Color(0xFF538D4E),
    present: Color(0xFFB59F3B),
    absent: Color(0xFF3A3A3C),
  );

  static const highContrast = Palette(
    id: 'highContrast',
    name: 'High Contrast',
    correct: Color(0xFFF5793A), // orange
    present: Color(0xFF85C0F9), // blue
    absent: Color(0xFF3A3A3C),
  );

  static const darkForest = Palette(
    id: 'darkForest',
    name: 'Dark Forest',
    correct: Color(0xFF2E7D32),
    present: Color(0xFF9E7B0E),
    absent: Color(0xFF37474F),
  );

  static const candy = Palette(
    id: 'candy',
    name: 'Candy',
    correct: Color(0xFFEC407A),
    present: Color(0xFFAB47BC),
    absent: Color(0xFF5C5C66),
  );

  static const ocean = Palette(
    id: 'ocean',
    name: 'Ocean',
    correct: Color(0xFF0277BD),
    present: Color(0xFF00ACC1),
    absent: Color(0xFF455A64),
  );

  /// A softer, dimmed dark theme that's easier on the eyes in the dark.
  static const lowLight = Palette(
    id: 'lowLight',
    name: 'Low Light',
    correct: Color(0xFF4A7A46),
    present: Color(0xFF8C7A33),
    absent: Color(0xFF2C2C2E),
    forcedBrightness: Brightness.dark,
    background: Color(0xFF0E0E0F),
    tileBorder: Color(0xFF2A2A2C),
    keyDefault: Color(0xFF55585A),
    onSurface: Color(0xFFC6C6CA),
  );

  /// Grayscale theme — relies on shape (the placement icons) plus shade.
  static const monochrome = Palette(
    id: 'monochrome',
    name: 'Monochrome',
    correct: Color(0xFFD7DADC), // light gray (dark text via luminance)
    present: Color(0xFF9AA0A3), // mid gray
    absent: Color(0xFF3A3A3C), // dark gray
    forcedBrightness: Brightness.dark,
    background: Color(0xFF121213),
    tileBorder: Color(0xFF3A3A3C),
    keyDefault: Color(0xFF6E7173),
    onSurface: Color(0xFFE6E6E6),
  );

  /// Pure-black, low-power theme; also disables board animations.
  static const batterySaver = Palette(
    id: 'batterySaver',
    name: 'Battery Saver',
    correct: Color(0xFF3E6B3A),
    present: Color(0xFF6E6130),
    absent: Color(0xFF1A1A1A),
    forcedBrightness: Brightness.dark,
    background: Color(0xFF000000),
    tileBorder: Color(0xFF262626),
    keyDefault: Color(0xFF2A2A2A),
    onSurface: Color(0xFFDADADA),
    reduceMotion: true,
  );

  /// All selectable presets (excludes the special custom entry).
  static const List<Palette> presets = [
    classic,
    highContrast,
    darkForest,
    candy,
    ocean,
    lowLight,
    monochrome,
    batterySaver,
  ];

  /// The default custom palette shown before the user edits it.
  static const defaultCustom = Palette(
    id: customId,
    name: 'Custom',
    correct: Color(0xFF7E57C2),
    present: Color(0xFFFFB300),
    absent: Color(0xFF4E4E57),
  );

  static Palette presetById(String id) =>
      presets.firstWhere((p) => p.id == id, orElse: () => classicDark);
}
