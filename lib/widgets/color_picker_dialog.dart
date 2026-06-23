import 'package:flutter/material.dart';

/// A lightweight swatch-based color picker — no external dependencies. Offers a
/// grid of useful colors plus a brightness/shade row for the selected hue.
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({
    super.key,
    required this.title,
    required this.initial,
  });

  final String title;
  final Color initial;

  static Future<Color?> show(
    BuildContext context, {
    required String title,
    required Color initial,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(title: title, initial: initial),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selected = widget.initial;

  static const List<MaterialColor> _hues = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
  ];

  static const List<int> _shades = [300, 400, 500, 600, 700, 800];

  static const List<Color> _greys = [
    Color(0xFF000000),
    Color(0xFF3A3A3C),
    Color(0xFF565758),
    Color(0xFF787C7E),
    Color(0xFF9E9E9E),
    Color(0xFFD3D6DA),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: _selected,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${_selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                  color: _selected.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hue in _hues)
                  for (final shade in _shades) _swatch(hue[shade]!),
              ],
            ),
            const Divider(height: 24),
            const Text('Greys', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final c in _greys) _swatch(c)],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _swatch(Color color) {
    final selected = color.toARGB32() == _selected.toARGB32();
    return GestureDetector(
      onTap: () => setState(() => _selected = color),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.black26,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [const BoxShadow(color: Colors.black45, blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}
