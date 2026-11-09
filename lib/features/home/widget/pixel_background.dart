import 'dart:math';
import 'package:flutter/material.dart';

/// Global touch state: while the user holds a finger anywhere on the home
/// page, the pixels dim (switch off).
final pixelTouched = ValueNotifier<bool>(false);

/// Floating colored pixels — same RGB palette as the portfolio hero header.
/// Positioned behind home page content; replaces the old world-map image.
class PixelBackgroundWidget extends StatefulWidget {
  const PixelBackgroundWidget({super.key});

  @override
  State<PixelBackgroundWidget> createState() => _PixelBackgroundWidgetState();
}

class _PixelBackgroundWidgetState extends State<PixelBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = Random();
  final List<_Pixel> _pixels = [];

  static const _palette = <Color>[
    Color(0xFFC33B2E), // red
    Color(0xFF3F9D4F), // green
    Color(0xFF3B6FC3), // blue
  ];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 28; i++) {
      _pixels.add(
        _Pixel(
          color: _palette[i % 3],
          x: _random.nextDouble(),
          y: .5 + _random.nextDouble() * .55,
          drift: (_random.nextDouble() * 90 - 45) / 600,
          size: i % 6 == 0 ? 7.0 : 4.0 + _random.nextDouble() * 1.5,
          speed: .04 + _random.nextDouble() * .05,
          phase: _random.nextDouble() * 2 * pi,
        ),
      );
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, pixelTouched]),
      builder: (context, _) {
        return CustomPaint(
          painter: _PixelPainter(
            pixels: _pixels,
            time: _controller.value * 120,
            touched: pixelTouched.value,
          ),
        );
      },
    );
  }
}

class _Pixel {
  _Pixel({
    required this.color,
    required this.x,
    required this.y,
    required this.drift,
    required this.size,
    required this.speed,
    required this.phase,
  });

  final Color color;
  final double x;
  final double y;
  final double drift;
  final double size;
  final double speed;
  final double phase;
}

class _PixelPainter extends CustomPainter {
  _PixelPainter({required this.pixels, required this.time, required this.touched});

  final List<_Pixel> pixels;
  final double time;
  final bool touched;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint();
    for (final p in pixels) {
      var progress = (p.y - time * p.speed) % 1;
      if (progress < 0) progress += 1;
      final dy = size.height * progress;
      final wobble = sin(time * .6 + p.phase) * p.drift;
      final dx = (size.width * p.x + size.width * wobble) % size.width;

      var opacity = 1.0;
      const edge = .1;
      if (progress > 1 - edge) {
        opacity = (1 - progress) / edge;
      } else if (progress < edge) {
        opacity = progress / edge;
      }

      final base = touched ? .08 : .5; // dimmed while touched
      paint.color = p.color.withValues(alpha: base * opacity);

      final rect = Rect.fromCenter(
        center: Offset(dx, dy),
        width: p.size,
        height: p.size,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) =>
      old.time != time || old.touched != touched;
}
