import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/widget/animated_text.dart';

/// Circular connection button with a physical toggle-switch inside.
/// The switch cover is removed; the switch itself is red and animates
/// (knob slides + track color changes) on connect/disconnect.
class SwitchCircleButton extends StatelessWidget {
  final double animationValue; // pulse 0.8..1 while connecting/connected
  final Color color; // outer ring color by status
  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final bool isOn; // switch position: connected/connecting => true

  const SwitchCircleButton({
    super.key,
    required this.animationValue,
    required this.color,
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.isOn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            width: 168,
            height: 168,
            child: Material(
              key: const ValueKey("home_connection_button"),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: isOn ? 1 : 0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    builder: (context, switchT, _) {
                      return CustomPaint(
                        painter: SwitchCirclePainter(
                          animationValue: animationValue,
                          baseColor: color,
                          switchValue: switchT,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ).animate(target: enabled ? 0 : 1).blurXY(end: 1),
        ).animate(target: enabled ? 0 : 1).scaleXY(end: .88, curve: Curves.easeIn),
        const Gap(16),
        ExcludeSemantics(child: AnimatedText(label, style: Theme.of(context).textTheme.titleMedium)),
      ],
    );
  }
}

class SwitchCirclePainter extends CustomPainter {
  final double animationValue;
  final Color baseColor;
  final double switchValue; // 0 = off (disconnected), 1 = on (connected)

  SwitchCirclePainter({
    required this.animationValue,
    required this.baseColor,
    required this.switchValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // ---- outer pulsing rings (same rhythm as old button) ----
    final Paint outerCirclePaint =
        Paint()..color = baseColor.withOpacity(.15)..style = PaintingStyle.fill;
    final double outerRadius = 84 * animationValue;
    canvas.drawCircle(Offset(cx, cy), outerRadius, outerCirclePaint);

    final Paint middleCirclePaint =
        Paint()..color = baseColor.withOpacity(.3)..style = PaintingStyle.fill;
    final double middleRadius = 60 * animationValue + (1 - animationValue) / 3;
    canvas.drawCircle(Offset(cx, cy), middleRadius, middleCirclePaint);

    // ---- inner disc (track of the switch, no cover) ----
    const Color offRed = Color(0xFFD32F2F); // switch red when off
    const Color onGreen = Color(0xFF2E7D32); // track turns green when on
    final Color trackColor = Color.lerp(offRed, onGreen, switchValue)!;

    final Paint innerCirclePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [trackColor.withAlpha(230), trackColor],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 36));
    canvas.drawCircle(Offset(cx, cy), 36, innerCirclePaint);

    // subtle inner rim
    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withAlpha(60);
    canvas.drawCircle(Offset(cx, cy), 34, rimPaint);

    // ---- the physical toggle switch ----
    // track: rounded rect inside the disc
    final double trackW = 34;
    final double trackH = 15;
    final Rect trackRect = Rect.fromCenter(
      center: Offset(cx, cy + 12),
      width: trackW,
      height: trackH,
    );
    final RRect track = RRect.fromRectAndRadius(trackRect, Radius.circular(trackH / 2));
    final Paint trackPaint = Paint()
      ..color = Colors.white.withAlpha(90 + (110 * switchValue).round());
    canvas.drawRRect(track, trackPaint);

    // knob: white circle sliding left(off) -> right(on)
    final double knobX = trackRect.left + 4 + (trackW - 8 - 10) * switchValue;
    final Offset knobCenter = Offset(knobX + 5, trackRect.center.dy);
    final Paint knobPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0); // solid
    // knob shadow
    canvas.drawCircle(knobCenter.translate(0, 1.2), 6, Paint()..color = Colors.black26);
    canvas.drawCircle(knobCenter, 6, knobPaint);
    // knob inner dot (accent)
    canvas.drawCircle(knobCenter, 2.4, Paint()..color = trackColor);

    // ---- "ON/OFF" ticks: power symbol above the switch ----
    // vertical line + arc drawn white, like a power button glyph
    final Paint glyphPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    // arc (head of power symbol), opens at top
    final double gR = 9.5;
    final Offset gC = Offset(cx, cy - 8);
    canvas.drawArc(Rect.fromCircle(center: gC, radius: gR), -1.0472, 4.18879, false, glyphPaint);
    // vertical line
    canvas.drawLine(
      Offset(cx, cy - 19),
      Offset(cx, cy - 11),
      glyphPaint,
    );

    // small "ON" / "OFF" label under the switch
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: switchValue > .5 ? "ON" : "OFF",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + 24));
  }

  @override
  bool shouldRepaint(SwitchCirclePainter old) => true;
}
