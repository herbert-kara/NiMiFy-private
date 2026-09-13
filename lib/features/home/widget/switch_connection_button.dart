import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/widget/animated_text.dart';

/// Circular connection button with a physical aircraft-style flip switch
/// inside (McGill Motorsport look): red LED that lights up when connected,
/// a flip lever that snaps ON/OFF with a spring animation, and the switch
/// cover removed — the switch itself sits directly on the disc.
class SwitchCircleButton extends StatefulWidget {
  final Color color; // outer ring color by status
  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final bool isOn; // switch position: connected/connecting => true
  final bool pulse; // outer rings pulse while connecting/connected

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
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.pulse) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SwitchCircleButton old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.pulse && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0; // rings snap to full size
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
                    // pulse 0.85..1 while animating; 1.0 when stopped
                    final double pulseVal =
                        widget.pulse ? 0.85 + 0.15 * _pulseCtrl.value : 1.0;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(end: widget.isOn ? 1 : 0),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      builder: (context, switchT, _) {
                        return CustomPaint(
                          painter: SwitchCirclePainter(
                            animationValue: pulseVal,
                            baseColor: widget.color,
                            switchValue: switchT,
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
          child: AnimatedText(widget.label, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class SwitchCirclePainter extends CustomPainter {
  final double animationValue; // 0.85..1 pulsing ring scale
  final Color baseColor;
  final double switchValue; // 0 = off, 1 = on (with slight overshoot)

  SwitchCirclePainter({
    required this.animationValue,
    required this.baseColor,
    required this.switchValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // ---- outer pulsing rings (kept from the original button rhythm) ----
    final Paint outerCirclePaint = Paint()
      ..color = baseColor.withOpacity(.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 84 * animationValue, outerCirclePaint);

    final Paint middleCirclePaint = Paint()
      ..color = baseColor.withOpacity(.3)
      ..style = PaintingStyle.fill;
    final double middleRadius = 60 * animationValue + (1 - animationValue) / 3;
    canvas.drawCircle(Offset(cx, cy), middleRadius, middleCirclePaint);

    // ---- inner disc (switch panel base) ----
    final Paint innerCirclePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [baseColor.withAlpha(230), baseColor],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 36));
    canvas.drawCircle(Offset(cx, cy), 36, innerCirclePaint);

    // brushed-metal rim around the disc
    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withAlpha(140), Colors.white.withAlpha(30)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 35));
    canvas.drawCircle(Offset(cx, cy), 34.8, rimPaint);

    // ---- aircraft-style switch mounting plate ----
    final double sv = switchValue.clamp(0.0, 1.0);
    const Color offRed = Color(0xFFC62828); // panel LED red (off state)
    final Color plateColor = Color.lerp(
      const Color(0xFF2A2A2E), // dark metal when off
      const Color(0xFFB71C1C), // red glow creeping in as it flips on
      sv,
    )!;

    // LED indicator (top): small round aviation lamp, lights up when ON
    final Offset ledCenter = Offset(cx, cy - 16);
    final double ledGlow = 0.25 + 0.75 * sv;
    // glow halo
    final Paint ledHaloPaint = Paint()
      ..color = offRed.withOpacity(0.10 + 0.45 * sv)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 6 * sv);
    canvas.drawCircle(ledCenter, 4 + 4 * sv, ledHaloPaint);
    // LED body
    final Paint ledPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF5A1A1A), // dim dark red when off
        const Color(0xFFFF3B30), // bright red LED when on
        sv,
      )!;
    canvas.drawCircle(ledCenter, 3.2, ledPaint);
    // LED specular dot
    canvas.drawCircle(
      ledCenter.translate(-0.8, -0.8),
      0.9,
      Paint()..color = Colors.white.withOpacity(0.5 + 0.4 * sv),
    );

    // ---- flip lever (the switch itself, no cover) ----
    // pivot at bottom of the slot; lever rotates up when ON
    final Offset pivot = Offset(cx, cy + 20);
    const double restAngle = 0.35;   // radians, leaning back when OFF
    const double onAngle = -0.15;   // pressed forward when ON
    final double angle = restAngle + (onAngle - restAngle) * sv;

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);

    // lever slot base (screwed plate)
    final Paint plateBgPaint = Paint()
      ..color = const Color(0xFF1A1A1D)
      ..style = PaintingStyle.fill;
    final RRect slot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 8), width: 26, height: 14),
      const Radius.circular(3),
    );
    canvas.drawRRect(slot, plateBgPaint);

    // the flip lever: rounded bar standing on the plate
    final Paint leverPaint = Paint()
      ..color = plateColor
      ..style = PaintingStyle.fill;
    final RRect lever = RRect.fromRectAndRadius(
      Rect.fromLTWH(-5, -22, 10, 30),
      const Radius.circular(2.5),
    );
    // lever shadow
    final Paint leverShadow = Paint()
      ..color = Colors.black.withAlpha(90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawRRect(lever.shift(const Offset(1, 1.5)), leverShadow);
    canvas.drawRRect(lever, leverPaint);

    // lever highlight (brushed metal streak)
    final Paint leverHiPaint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-3.5, -21, 2.2, 28),
        const Radius.circular(1.5),
      ),
      leverHiPaint,
    );

    // lever tip cap (red bat, like aviation toggles)
    final Paint tipPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;
    final RRect tip = RRect.fromRectAndRadius(
      Rect.fromLTWH(-6.2, -26, 12.4, 8),
      const Radius.circular(2),
    );
    canvas.drawRRect(tip, tipPaint);
    // tip gloss
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4.6, -24.8, 9, 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = Colors.white.withAlpha(60),
    );

    canvas.restore();

    // mounting screws (aviation plate detail, two corners)
    for (final dx in [-14.0, 14.0]) {
      final Offset screw = Offset(cx + dx, cy + 16);
      canvas.drawCircle(screw, 1.6, Paint()..color = const Color(0xFF454549));
      canvas.drawCircle(
        screw.translate(-0.4, -0.4),
        0.7,
        Paint()..color = Colors.white.withAlpha(70),
      );
    }

    // ---- "ON" / "OFF" engraving under the switch ----
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: sv > .5 ? "ON" : "OFF",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + 26));
  }

  @override
  bool shouldRepaint(SwitchCirclePainter old) => true;
}
