import 'package:flutter/material.dart';

import 'game.dart';

/// The set of tile/key colors used to render evaluations. A palette is either
/// one of the built-in presets or a user-defined custom palette.
@immutable
class Palette {
  const Palette({
    required this.id,
    required this.name,
    required this.correct,
    required this.present,
    required this.absent,
  });

  /// Stable identifier persisted in settings.
  final String id;
  final String name;
  final Color correct;
  final Color present;
  final Color absent;

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

  /// All selectable presets (excludes the special custom entry).
  static const List<Palette> presets = [
    classic,
    highContrast,
    darkForest,
    candy,
    ocean,
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
