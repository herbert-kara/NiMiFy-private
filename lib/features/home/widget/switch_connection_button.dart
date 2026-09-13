import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/widget/animated_text.dart';

/// Connection button styled as an aviation flip-switch panel (McGill
/// Motorsport look): a metal plate sits in the center of the pulsing
/// circle, with a red-bat flip lever that snaps UP when connected and
/// DOWN when disconnected. Spring overshoot on the flip, no cover.
class SwitchCircleButton extends StatefulWidget {
  final Color color; // outer ring color by status
  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final bool isOn; // connected/connecting => lever up
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
                    final double pulseVal =
                        widget.pulse ? 0.85 + 0.15 * _pulseCtrl.value : 1.0;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(end: widget.isOn ? 1 : 0),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.elasticOut,
                      builder: (context, flipT, _) {
                        return CustomPaint(
                          painter: SwitchPanelPainter(
                            animationValue: pulseVal,
                            baseColor: widget.color,
                            flipValue: flipT,
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

class SwitchPanelPainter extends CustomPainter {
  final double animationValue; // 0.85..1 pulsing ring scale
  final Color baseColor;
  final double flipValue; // 0 = lever down (off), 1 = lever up (on); elastic overshoot allowed

  SwitchPanelPainter({
    required this.animationValue,
    required this.baseColor,
    required this.flipValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // ---- outer pulsing rings ----
    final Paint outerPaint = Paint()
      ..color = baseColor.withOpacity(.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 84 * animationValue, outerPaint);

    final Paint middlePaint = Paint()
      ..color = baseColor.withOpacity(.3)
      ..style = PaintingStyle.fill;
    final double middleRadius = 60 * animationValue + (1 - animationValue) / 3;
    canvas.drawCircle(Offset(cx, cy), middleRadius, middlePaint);

    // ---- inner disc ----
    final Paint discPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [baseColor.withAlpha(230), baseColor],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 36));
    canvas.drawCircle(Offset(cx, cy), 36, discPaint);

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withAlpha(140), Colors.white.withAlpha(30)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 35));
    canvas.drawCircle(Offset(cx, cy), 34.8, rimPaint);

    // ---- aviation switch plate ----
    final double fv = flipValue.clamp(-0.4, 1.4);

    // rounded metal plate
    final Rect plateRect = Rect.fromCenter(
      center: Offset(cx, cy + 2),
      width: 46,
      height: 52,
    );
    final RRect plate = RRect.fromRectAndRadius(plateRect, const Radius.circular(6));
    final Paint platePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3A3F4A),
          const Color(0xFF23262E),
          const Color(0xFF2B303A),
        ],
      ).createShader(plateRect);
    canvas.drawRRect(plate, platePaint);
    // plate bevel highlight
    final Paint plateHi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withAlpha(45);
    canvas.drawRRect(plate.shift(const Offset(0, -0.6)), plateHi);

    // corner screws
    for (final s in [
      plateRect.topLeft + const Offset(5, 5),
      plateRect.topRight + const Offset(-5, 5),
      plateRect.bottomLeft + const Offset(5, -5),
      plateRect.bottomRight + const Offset(-5, -5),
    ]) {
      canvas.drawCircle(s, 1.5, Paint()..color = const Color(0xFF171A20));
      canvas.drawCircle(
        s.translate(-0.3, -0.3),
        0.7,
        Paint()..color = Colors.white.withAlpha(80),
      );
    }

    // LED strip at plate top: red, glows when ON
    final Rect ledRect = Rect.fromCenter(
      center: Offset(cx, plateRect.top + 8),
      width: 22,
      height: 4,
    );
    final double glow = fv.clamp(0.0, 1.0);
    // glow halo behind LED
    final Paint ledHalo = Paint()
      ..color = const Color(0xFFFF5252).withOpacity(0.08 + 0.35 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ledRect.inflate(3), const Radius.circular(4)),
      ledHalo,
    );
    final Paint ledPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF7A2A22),
        const Color(0xFFFF3B30),
        glow,
      )!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(ledRect, const Radius.circular(2)),
      ledPaint,
    );
    // LED specular
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        ledRect.deflate(1).shift(const Offset(0, -0.5)),
        const Radius.circular(1),
      ),
      Paint()..color = Colors.white.withAlpha(40 + 80 * glow),
    );

    // ---- the flip lever ----
    // pivot near the bottom of the slot; lever flips up when ON
    final Offset pivot = Offset(cx, plateRect.bottom - 14);
    // lever angles: down (off) = 0.42 rad back, up (on) = -0.20 rad forward
    final double downAngle = 0.42;
    final double upAngle = -0.20;
    final double angle = downAngle + (upAngle - downAngle) * fv;

    // slot behind lever
    final Paint slotPaint = Paint()..color = const Color(0xFF12141A);
    final Rect slotRect = Rect.fromCenter(
      center: Offset(cx, pivot.dy - 12),
      width: 16,
      height: 26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(slotRect, const Radius.circular(3)),
      slotPaint,
    );

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);

    // lever arm: brushed metal bar
    const double armW = 8;
    const double armH = 34;
    final RRect arm = RRect.fromRectAndRadius(
      Rect.fromLTWH(-armW / 2, -armH, armW, armH),
      const Radius.circular(2),
    );
    final Paint armShadowPaint = Paint()
      ..color = Colors.black.withAlpha(110)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawRRect(arm.shift(const Offset(0.8, 1)), armShadowPaint);
    final Paint armPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF4A505B),
          const Color(0xFF6B7280),
          const Color(0xFF39404A),
        ],
      ).createShader(Rect.fromLTWH(-armW / 2, -armH, armW, armH));
    canvas.drawRRect(arm, armPaint);

    // red bat tip (aviation toggle cap)
    final double batGlow = fv.clamp(0.0, 1.0);
    final RRect bat = RRect.fromRectAndRadius(
      Rect.fromLTWH(-7, -armH - 7, 14, 10),
      const Radius.circular(2.5),
    );
    // bat shadow
    canvas.drawRRect(
      bat.shift(const Offset(0.8, 1)),
      Paint()..color = Colors.black.withAlpha(100),
    );
    final Paint batPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFF9E2B25), const Color(0xFFFF453A), batGlow)!,
          Color.lerp(const Color(0xFF7A1F1A), const Color(0xFFD70015), batGlow)!,
        ],
      ).createShader(bat.outerRect);
    canvas.drawRRect(bat, batPaint);
    // bat gloss
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-5, -armH - 6, 10, 3.5),
        const Radius.circular(1.5),
      ),
      Paint()..color = Colors.white.withAlpha(55),
    );

    canvas.restore();

    // engraved ON above slot, OFF below (aviation panel labels)
    TextPainter label(bool on) => TextPainter(
          text: TextSpan(
            text: on ? "ON" : "OFF",
            style: TextStyle(
              color: Colors.white.withAlpha(on == (fv > .5) ? 220 : 90),
              fontSize: 6.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    final onTp = label(true);
    final offTp = label(false);
    onTp.paint(canvas, Offset(cx - onTp.width / 2, plateRect.top + 14));
    offTp.paint(canvas, Offset(cx - offTp.width / 2, plateRect.bottom - 9));
  }

  @override
  bool shouldRepaint(SwitchPanelPainter old) => true;
}
