import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A dependency-free confetti burst. Bump [serial] to fire; [count] sets how
/// many pieces fall (the game scales this by how few tries the win took). Place
/// it in a full-bleed [IgnorePointer] so it never blocks taps. Draws nothing
/// when idle.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.serial, required this.count});

  final int serial;
  final int count;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );

  List<_Particle> _particles = const [];

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFF8E24AA),
    Color(0xFFFB8C00),
    Color(0xFFEC407A),
    Color(0xFF00ACC1),
  ];

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.serial != oldWidget.serial && widget.count > 0) {
      _fire();
    }
  }

  void _fire() {
    final rng = math.Random();
    _particles = List.generate(widget.count, (_) {
      return _Particle(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 0.25,
        speed: 0.7 + rng.nextDouble() * 0.6,
        drift: (rng.nextDouble() * 2 - 1) * 0.12,
        size: 6 + rng.nextDouble() * 8,
        ratio: 0.5 + rng.nextDouble(),
        rot: (rng.nextDouble() * 2 - 1) * 4,
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
        if (_controller.isDismissed || _particles.isEmpty) {
          return const SizedBox.shrink();
        }
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.ratio,
    required this.rot,
    required this.color,
  });

  final double x; // 0..1 horizontal start
  final double delay; // 0..0.25 start delay (fraction of the animation)
  final double speed; // fall speed multiplier
  final double drift; // horizontal sway amplitude
  final double size; // piece width in logical px
  final double ratio; // height/width ratio
  final double rot; // rotation speed
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final local = (t - p.delay) / (1 - p.delay);
      if (local <= 0) continue;
      final prog = local * p.speed;
      final y = -0.05 + prog * 1.2;
      if (y > 1.15) continue;
      final x = p.x + p.drift * math.sin(prog * math.pi * 3);
      final opacity =
          local > 0.85 ? (1 - (local - 0.85) / 0.15).clamp(0.0, 1.0) : 1.0;
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(p.rot * prog * math.pi);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * p.ratio),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.particles != particles;
}
