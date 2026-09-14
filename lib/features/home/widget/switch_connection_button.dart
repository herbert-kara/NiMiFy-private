import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/widget/animated_text.dart';

/// Dribbble "VPN Mobile App Design" style power button:
///  - light-gray circle with a vertical gradient
///  - engraved white "POWER" at the top, white power glyph in the center
///  - dashed accent ring hugging the circle (mint when connected)
class SwitchCircleButton extends StatefulWidget {
  final Color color; // accent tint (by connection status)
  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final bool isOn; // connected/connecting => ring bright
  final bool pulse;

  const SwitchCircleButton({
    super.key,
    required this.color,
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.isOn,
    this.pulse = true,
  });

  @override
  State<SwitchCircleButton> createState() => _SwitchCircleButtonState();
}

class _SwitchCircleButtonState extends State<SwitchCircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    if (widget.pulse) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SwitchCircleButton old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.pulse && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: widget.enabled,
          label: widget.label,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            width: 168,
            height: 168,
            child: Material(
              key: const ValueKey("home_connection_button"),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.onTap,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final double glow =
                        widget.pulse ? 0.35 + 0.65 * _pulseCtrl.value : 1.0;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(end: widget.isOn ? 1 : 0),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      builder: (context, onT, _) {
                        return CustomPaint(
                          painter: PowerButtonPainter(
                            accent: widget.color,
                            glow: glow,
                            onT: onT.clamp(0.0, 1.0),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ).animate(target: widget.enabled ? 0 : 1).blurXY(end: 1),
        ).animate(target: widget.enabled ? 0 : 1).scaleXY(end: .88, curve: Curves.easeIn),
        const Gap(16),
        ExcludeSemantics(
          child:
              AnimatedText(widget.label, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class PowerButtonPainter extends CustomPainter {
  final Color accent; // status color (idle indigo / connected green)
  final double glow; // 0..1, breathes while pulse
  final double onT; // 0 = disconnected, 1 = connected

  PowerButtonPainter({required this.accent, required this.glow, required this.onT});

  static const Color mint = Color(0xFF0DFFC4);

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double on = onT;
    // gray when OFF; accent/mint tint only when ON
    final Color offGray = const Color(0xFF8E8E93);
    final Color onColor = Color.lerp(accent, mint, 0.45)!;
    final Color ringAccent = Color.lerp(offGray, onColor, on)!;

    // ---- ambient glow behind the button (breathes with pulse) ----
    final Paint halo = Paint()
      ..color = ringAccent.withOpacity((0.04 + 0.10 * on) * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(cx, cy), 84, halo);

    // ---- dashed accent ring hugging the circle ----
    const double ringR = 75;
    final Paint dash = Paint()
      ..color = ringAccent.withOpacity(0.35 + 0.35 * on + 0.3 * glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    const int dashes = 64;
    const double sweep = 2 * 3.141592653589793 / dashes;
    const double dashLen = sweep * 0.5;
    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: ringR),
        i * sweep,
        dashLen,
        false,
        dash,
      );
    }

    // ---- main circle: vertical gray gradient ----
    final Rect circleRect = Rect.fromCircle(center: Offset(cx, cy), radius: 64);
    canvas.drawCircle(
      Offset(cx, cy),
      64,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF737373), Color(0xFF8A8A8A), Color(0xFF979797)],
        ).createShader(circleRect),
    );
    // subtle dark rim
    canvas.drawCircle(
      Offset(cx, cy),
      63.4,
      Paint()
        ..color = Colors.black.withAlpha(24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ---- engraved "POWER" at the top ----
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: "POWER",
        style: TextStyle(
          color: Colors.white.withAlpha(235),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 3.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - 40 - tp.height / 2));

    // ---- power glyph: ring with a top gap + stem, white ----
    final Offset gc = Offset(cx, cy + 7);
    const double gR = 12;
    const double gap = 0.9; // radians
    final Paint glyph = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: gc, radius: gR),
      -3.141592653589793 / 2 + gap / 2,
      2 * 3.141592653589793 - gap,
      false,
      glyph,
    );
    canvas.drawLine(
      Offset(gc.dx, gc.dy - gR - 6),
      Offset(gc.dx, gc.dy - 2),
      glyph,
    );
  }

  @override
  bool shouldRepaint(PowerButtonPainter old) => true;
}
