import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A dependency-free fireworks burst overlay. Bump [serial] to set off several
/// staggered bursts. Place it in a full-bleed [IgnorePointer]; draws nothing
/// when idle.
class FireworksOverlay extends StatefulWidget {
  const FireworksOverlay({super.key, required this.serial});

  final int serial;

  @override
  State<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends State<FireworksOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  List<_Burst> _bursts = const [];

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFF8E24AA),
    Color(0xFFFB8C00),
    Color(0xFFEC407A),
    Color(0xFF00E5FF),
  ];

  @override
  void didUpdateWidget(covariant FireworksOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.serial != oldWidget.serial) _fire();
  }

  void _fire() {
    final rng = math.Random();
    final n = 6 + rng.nextInt(3); // 6–8 bursts
    _bursts = List.generate(n, (i) {
      return _Burst(
        x: 0.12 + rng.nextDouble() * 0.76,
        y: 0.12 + rng.nextDouble() * 0.5,
        start: (i / n) * 0.7 + rng.nextDouble() * 0.08,
        speed: 0.16 + rng.nextDouble() * 0.14,
        particles: 22 + rng.nextInt(16),
        color: _colors[rng.nextInt(_colors.length)],
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isDismissed || _bursts.isEmpty) {
          return const SizedBox.shrink();
        }
        return CustomPaint(
          size: Size.infinite,
          painter: _FireworksPainter(_bursts, _controller.value),
        );
      },
    );
  }
}

class _Burst {
  const _Burst({
    required this.x,
    required this.y,
    required this.start,
    required this.speed,
    required this.particles,
    required this.color,
  });

  final double x; // 0..1 burst center
  final double y;
  final double start; // 0..1 launch time within the animation
  final double speed; // expansion speed
  final int particles;
  final Color color;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.bursts, this.t);

  final List<_Burst> bursts;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final b in bursts) {
      final local = (t - b.start) / (1 - b.start);
      if (local <= 0 || local >= 1) continue;
      // Ease-out expansion + fade, with a little gravity droop.
      final radius = (1 - math.pow(1 - local, 2).toDouble()) *
          b.speed *
          size.shortestSide;
      final opacity = (1 - local).clamp(0.0, 1.0);
      final cx = b.x * size.width;
      final cy = b.y * size.height + local * local * 50;
      paint.color = b.color.withValues(alpha: opacity);
      final dot = 2.6 * opacity + 0.6;
      for (var i = 0; i < b.particles; i++) {
        final ang = (i / b.particles) * 2 * math.pi;
        final px = cx + math.cos(ang) * radius;
        final py = cy + math.sin(ang) * radius;
        canvas.drawCircle(Offset(px, py), dot, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.bursts != bursts;
}

/// A festive rainbow color for celebration cycles. [t] is the animation value
/// (0..1) and [phase] (0..1) offsets each element for a wave effect.
Color celebrationColor(double t, double phase) {
  final hue = (((t * 1.5) + phase) % 1.0) * 360.0;
  return HSVColor.fromAHSV(1, hue, 0.78, 0.95).toColor();
}
