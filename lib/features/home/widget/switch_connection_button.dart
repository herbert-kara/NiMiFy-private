import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/widget/animated_text.dart';

/// EXACT McGill Motorsport aviation flip switch, scaled into the 168px
/// circle. From the product photo:
///  - glossy BLACK oval-panel face, chrome bezel ring
///  - a TALL RED bat lever with an oval tip, leaning back when OFF,
///    snapped upright when ON (glossy red, bright rim light)
///  - small RED LED dot under the switch
///  - engraved ON/OFF, chrome slot screws
class SwitchCircleButton extends StatefulWidget {
  final Color color; // accent tint of the plate (by connection status)
  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final bool isOn; // connected/connecting => lever up
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
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
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
                      curve: Curves.easeOutBack,
                      builder: (context, flipT, _) {
                        return CustomPaint(
                          painter: McGillSwitchPainter(
                            accent: widget.color,
                            glow: glow,
                            flipValue: flipT.clamp(-0.3, 1.3),
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

class McGillSwitchPainter extends CustomPainter {
  final Color accent;
  final double glow;
  final double flipValue;

  McGillSwitchPainter({
    required this.accent,
    required this.glow,
    required this.flipValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double fv = flipValue.clamp(0.0, 1.0);
    final double os = flipValue; // may overshoot

    // ambient glow behind the switch (breathes with pulse)
    final Paint breath = Paint()
      ..color = accent.withOpacity(0.08 + 0.14 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(Offset(cx, cy), 88, breath);

    // ---- chrome bezel ring (outer) ----
    canvas.drawCircle(Offset(cx, cy), 84, Paint()..color = const Color(0xFF101216));
    final Paint bezel = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-0.7, -0.7),
        end: Alignment(0.7, 0.7),
        colors: [
          Color(0xFFF2F5F9), Color(0xFFAEB6C2), Color(0xFF5C626D),
          Color(0xFFD7DCE4), Color(0xFF4E545E),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 82));
    canvas.drawCircle(Offset(cx, cy), 82, bezel);
    canvas.drawCircle(
      Offset(cx, cy),
      76,
      Paint()
        ..color = Colors.black.withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ---- black oval panel face (vertical oval like the McGill plate) ----
    final Rect face = Rect.fromCenter(center: Offset(cx, cy), width: 132, height: 142);
    final RRect panel = RRect.fromRectAndRadius(face, const Radius.circular(56));
    final Paint panelPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        radius: 1.2,
        colors: [
          const Color(0xFF34383F),
          const Color(0xFF23262C),
          const Color(0xFF16181D),
        ],
      ).createShader(face);
    canvas.drawRRect(panel, panelPaint);
    // subtle accent wash
    canvas.drawRRect(
      panel,
      Paint()..color = accent.withOpacity(0.03 + 0.07 * fv),
    );
    // panel inner bevel
    canvas.drawRRect(
      panel.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withAlpha(28),
    );

    // ---- chrome slot screws at panel corners ----
    for (final pos in [
      Offset(cx - 42, cy - 50),
      Offset(cx + 42, cy - 50),
      Offset(cx - 42, cy + 50),
      Offset(cx + 42, cy + 50),
    ]) {
      canvas.drawCircle(pos, 3.4, Paint()..color = const Color(0xFF111318));
      canvas.drawCircle(
        pos,
        2.6,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD3D9E2), Color(0xFF575E69)],
          ).createShader(Rect.fromCircle(center: pos, radius: 2.6)),
      );
      canvas.drawLine(
        pos.translate(-1.5, 0),
        pos.translate(1.5, 0),
        Paint()
          ..color = const Color(0xFF23262D)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );
    }

    // ---- red LED (small dot at panel top, like the product's Red LED) ----
    final Offset led = Offset(cx, cy - 56);
    final Paint ledHalo = Paint()
      ..color = const Color(0xFFFF3B30).withOpacity(0.12 + 0.55 * fv * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 5 * fv);
    canvas.drawCircle(led, 4 + 3 * fv, ledHalo);
    canvas.drawCircle(
      led,
      3,
      Paint()
        ..color = Color.lerp(const Color(0xFF70231E), const Color(0xFFFF453A), fv)!,
    );
    canvas.drawCircle(
      led.translate(-0.8, -0.8),
      0.9,
      Paint()..color = Colors.white.withOpacity(0.4 + 0.5 * fv),
    );

    // ---- engraved "ON" (top) / "OFF" (bottom) around the lever ----
    TextPainter tp(String text, double alpha) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: Colors.white.withAlpha(alpha.round()),
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.6,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    final onActive = fv > 0.5;
    tp("ON", onActive ? 235 : 75).paint(canvas, Offset(cx - 8.5, cy - 40));
    tp("OFF", onActive ? 75 : 235).paint(canvas, Offset(cx - 10.5, cy + 34));

    // ---- the switch: round bezel + slot + RED bat lever ----
    // round black bezel with chrome ring, centered lower half
    final Offset swc = Offset(cx, cy + 18);
    // chrome bezel ring of the switch
    final Paint swBezel = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE6EAF0), Color(0xFF8E96A2), Color(0xFF505760)],
      ).createShader(Rect.fromCircle(center: swc, radius: 30));
    canvas.drawCircle(swc, 30, swBezel);
    // black recessed face
    final Paint swFace = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.1,
        colors: [const Color(0xFF26292F), const Color(0xFF0F1115)],
      ).createShader(Rect.fromCircle(center: swc, radius: 26));
    canvas.drawCircle(swc, 26, swFace);

    // lever slot: dark vertical opening at the center of the switch
    final Rect slotRect = Rect.fromCenter(center: swc, width: 13, height: 34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slotRect, const Radius.circular(6.5)),
      Paint()..color = const Color(0xFF07080B),
    );

    // RED bat lever, hinged at the slot bottom
    final Offset pivot = Offset(slotRect.center.dx, slotRect.bottom - 2);
    // OFF: leans back 38deg; ON: upright -6deg
    final double angle = 0.66 + (-0.10 - 0.66) * os;

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);

    // lever arm (short red stem)
    const double stemW = 9;
    const double stemH = 30;
    final RRect stem = RRect.fromRectAndRadius(
      Rect.fromLTWH(-stemW / 2, -stemH, stemW, stemH),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      stem.shift(const Offset(1.2, 1.5)),
      Paint()
        ..color = Colors.black.withAlpha(120)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    final Paint stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF7E1813), Color(0xFFD0271D), Color(0xFF6E1511)],
      ).createShader(Rect.fromLTWH(-stemW / 2, -stemH, stemW, stemH));
    canvas.drawRRect(stem, stemPaint);

    // RED oval tip (the McGill bat head — wide, rounded, glossy)
    final RRect tip = RRect.fromRectAndRadius(
      Rect.fromLTWH(-10, -stemH - 16, 20, 19),
      const Radius.circular(9),
    );
    // drop shadow
    canvas.drawRRect(
      tip.shift(const Offset(1.5, 2)),
      Paint()
        ..color = Colors.black.withAlpha(140)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // red gradient — brighter when ON
    final Paint tipPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFF9E1F18), const Color(0xFFFF5045), fv)!,
          Color.lerp(const Color(0xFF7C120D), const Color(0xFFE01B12), fv)!,
        ],
      ).createShader(tip.outerRect);
    canvas.drawRRect(tip, tipPaint);
    // glossy highlight streak across the tip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-7, -stemH - 14.5, 14, 6),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withAlpha(60 + (70 * fv).round()),
    );
    // tip rim light (chrome edge, like the photo's specular)
    canvas.drawRRect(
      tip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFFF8A80).withOpacity(0.35 + 0.3 * fv),
    );

    canvas.restore();

    // ---- small engraved arc ticks beside the switch (aviation detail) ----
    final Paint tickPaint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final dx in [-1.0, 1.0]) {
      canvas.drawLine(
        swc.translate(dx * 38, -6),
        swc.translate(dx * 42, -6),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(McGillSwitchPainter old) => true;
}
