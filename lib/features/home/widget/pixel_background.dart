import 'dart:math';
import 'package:flutter/material.dart';

/// Dribbble-style home background: vertical charcoal gradient with a soft
/// accent glow behind the power button — neutral gray-blue when
/// disconnected, mint-green tint when connected. Replaces floating pixels.
class PixelBackgroundWidget extends StatefulWidget {
  const PixelBackgroundWidget({super.key});

  @override
  State<PixelBackgroundWidget> createState() => _PixelBackgroundWidgetState();
}

class _PixelBackgroundWidgetState extends State<PixelBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // bg accent, mirrored from the connection button state
  static final ValueNotifier<Color> bgAccent =
      ValueNotifier(const Color(0xFF4A4D8B));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, bgAccent]),
      builder: (context, _) {
        final accent = bgAccent.value;
        // true when the accent is greenish (connected)
        final on = accent.green > accent.red;
        return CustomPaint(
          painter: _GlowBgPainter(
            accent: accent,
            on: on ? 1 : 0,
            breath: _controller.value,
          ),
        );
      },
    );
  }
}

class _GlowBgPainter extends CustomPainter {
  final Color accent;
  final double on; // 1 connected, 0 disconnected
  final double breath; // 0..1 slow breathing

  _GlowBgPainter({required this.accent, required this.on, required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // base charcoal gradient, slight blue-gray tint
    final Rect full = Offset.zero & size;
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF34383E),
            Color(0xFF2C3036),
            Color(0xFF23272C),
          ],
        ).createShader(full),
    );

    // big soft radial glow behind the button (center of screen)
    final Offset c = Offset(size.width / 2, size.height * 0.42);
    final double glowR = size.longestSide * 0.62;
    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withOpacity(0.16 + 0.10 * on + 0.05 * breath * on),
          accent.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: glowR));
    canvas.drawCircle(c, glowR, glow);
  }

  @override
  bool shouldRepaint(_GlowBgPainter old) =>
      old.accent != accent || old.on != on || old.breath != breath;
}
