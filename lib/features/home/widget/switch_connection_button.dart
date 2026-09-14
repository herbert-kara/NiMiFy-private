import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/widget/animated_text.dart';

/// Connection button styled as a REAL aviation flip switch (McGill Motorsport):
/// the whole 168px circle IS the switch — chrome bezel ring, brushed metal
/// face plate, and a big red-bat lever that flips DOWN (off) to UP (on)
/// with a spring snap. No tiny panel inside a circle: the button is the switch.
class SwitchCircleButton extends StatefulWidget {
  final Color color; // bezel accent by status
  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final bool isOn; // connected/connecting => lever up
  final bool pulse; // outer glow pulses while connecting/connected

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
                    final double glow =
                        widget.pulse ? 0.45 + 0.55 * _pulseCtrl.value : 1.0;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(end: widget.isOn ? 1 : 0),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.elasticOut,
                      builder: (context, flipT, _) {
                        return CustomPaint(
                          painter: FlipSwitchPainter(
                            accent: widget.color,
                            glow: glow,
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

class FlipSwitchPainter extends CustomPainter {
  final Color accent;
  final double glow; // 0..1 breathing halo
  final double flipValue; // 0 = lever DOWN (off), 1 = UP (on); elastic overshoot ok

  FlipSwitchPainter({
    required this.accent,
    required this.glow,
    required this.flipValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double fv = flipValue.clamp(0.0, 1.0);
    final double overshoot = flipValue.clamp(-0.4, 1.4);

    // ---------- breathing halo behind everything ----------
    final Paint haloPaint = Paint()
      ..color = accent.withOpacity(0.10 + 0.16 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(cx, cy), 86, haloPaint);

    // ---------- chrome bezel (outer ring) ----------
    // dark base ring
    canvas.drawCircle(
      Offset(cx, cy),
      84,
      Paint()..color = const Color(0xFF15181E),
    );
    // chrome gradient ring
    final Rect bezelRect = Rect.fromCircle(center: Offset(cx, cy), radius: 84);
    final Paint bezelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE8ECF2),
          const Color(0xFF9AA3AF),
          const Color(0xFF4A5058),
          const Color(0xFFB8C0CA),
          const Color(0xFF5A616B),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(bezelRect);
    canvas.drawCircle(Offset(cx, cy), 82, bezelPaint);
    // inner rim shadow
    final Paint rimShadowPaint = Paint()
      ..color = Colors.black.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx, cy), 65, rimShadowPaint);

    // ---------- face plate (brushed dark metal) ----------
    final Rect faceRect = Rect.fromCircle(center: Offset(cx, cy), radius: 66);
    final Paint facePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.4,
        colors: [
          const Color(0xFF3E434C),
          const Color(0xFF2B2F37),
          const Color(0xFF202329),
        ],
      ).createShader(faceRect);
    canvas.drawCircle(Offset(cx, cy), 66, facePaint);

    // status tint: subtle accent wash that strengthens when ON
    final Paint tintPaint = Paint()
      ..color = accent.withOpacity(0.04 + 0.10 * fv);
    canvas.drawCircle(Offset(cx, cy), 64, tintPaint);

    // ---------- screws (4, plate corners) ----------
    for (final pos in [
      Offset(cx + 33, cy - 33),
      Offset(cx - 33, cy - 33),
      Offset(cx - 33, cy + 33),
      Offset(cx + 33, cy + 33),
    ]) {
      // slot-head screw: dark circle + metal ring + cross slot
      canvas.drawCircle(pos, 4.2, Paint()..color = const Color(0xFF191C21));
      canvas.drawCircle(
        pos,
        3.2,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFC9CFD8), const Color(0xFF565D67)],
          ).createShader(Rect.fromCircle(center: pos, radius: 3.2)),
      );
      canvas.drawLine(
        pos.translate(-1.8, 0),
        pos.translate(1.8, 0),
        Paint()
          ..color = const Color(0xFF2A2D33)
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );
    }

    // ---------- LED indicator (top center of the face) ----------
    final Offset ledPos = Offset(cx, cy - 44);
    // halo when ON
    final Paint ledHaloPaint = Paint()
      ..color = const Color(0xFFFF3B30).withOpacity(0.10 + 0.50 * fv * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + 5 * fv);
    canvas.drawCircle(ledPos, 5 + 4 * fv, ledHaloPaint);
    final Paint ledPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF6B2521),
        const Color(0xFFFF453A),
        fv,
      )!;
    canvas.drawCircle(ledPos, 3.6, ledPaint);
    canvas.drawCircle(
      ledPos.translate(-0.9, -0.9),
      1.1,
      Paint()..color = Colors.white.withOpacity(0.45 + 0.45 * fv),
    );

    // ---------- the big flip lever ----------
    // pivot at bottom-center of the face; the lever is a long chrome arm
    // with a red bat that lays almost flat (down) or stands tall (up).
    final Offset pivot = Offset(cx, cy + 38);
    // lever angles: OFF = leaning far back (toward user, ~62deg from vertical),
    // ON = standing straight up with slight forward press.
    final double downAngle = 0.55; // radians
    final double upAngle = -0.10;
    final double angle = downAngle + (upAngle - downAngle) * overshoot;

    // lever slot (dark recess arc the bat sits in when off)
    final Paint slotPaint = Paint()
      ..color = const Color(0xFF121419);
    final Path slotPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 6), width: 46, height: 46),
        const Radius.circular(23),
      ));
    canvas.drawPath(slotPath, slotPaint);

    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);

    // ---- chrome arm ----
    const double armW = 12;
    const double armH = 52;
    final RRect arm = RRect.fromRectAndRadius(
      Rect.fromLTWH(-armW / 2, -armH, armW, armH),
      const Radius.circular(3),
    );
    // arm drop shadow
    canvas.drawRRect(
      arm.shift(const Offset(1.5, 2)),
      Paint()
        ..color = Colors.black.withAlpha(140)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // brushed chrome
    final Paint armPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF7B828D),
          const Color(0xFFE9EDF3),
          const Color(0xFF8B929D),
          const Color(0xFF3F454E),
        ],
        stops: const [0.0, 0.3, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(-armW / 2, -armH, armW, armH));
    canvas.drawRRect(arm, armPaint);

    // ---- red bat (lever head) ----
    final double batGlow = fv;
    final RRect bat = RRect.fromRectAndRadius(
      Rect.fromLTWH(-13, -armH - 13, 26, 17),
      const Radius.circular(4),
    );
    // bat shadow
    canvas.drawRRect(
      bat.shift(const Offset(1.5, 2)),
      Paint()
        ..color = Colors.black.withAlpha(130)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final Paint batPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFFA62C24), const Color(0xFFFF5147), batGlow)!,
          Color.lerp(const Color(0xFF801D16), const Color(0xFFE01616), batGlow)!,
        ],
      ).createShader(bat.outerRect);
    canvas.drawRRect(bat, batPaint);
    // bat gloss
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-9, -armH - 11.5, 18, 5.5),
        const Radius.circular(2.5),
      ),
      Paint()..color = Colors.white.withAlpha(50 + (50 * batGlow).round()),
    );
    // bat side ribs (aviation texture)
    for (final dx in [-6.0, 0.0, 6.0]) {
      canvas.drawLine(
        Offset(dx, -armH - 11),
        Offset(dx, -armH - 1),
        Paint()
          ..color = Colors.black.withAlpha(45)
          ..strokeWidth = 1.2,
      );
    }

    canvas.restore();

    // ---------- engraved labels ----------
    TextPainter tp(String text, double alpha, double size) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: Colors.white.withAlpha(alpha.round()),
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    // ON (above slot, left side) / OFF (below slot) — engraved, active one lit
    final onActive = fv > 0.5;
    final onTp = tp("ON", onActive ? 230 : 70, 9);
    final offTp = tp("OFF", onActive ? 70 : 230, 9);
    onTp.paint(canvas, Offset(cx - onTp.width / 2, cy - 26));
    offTp.paint(canvas, Offset(cx - offTp.width / 2, cy + 28));
  }

  @override
  bool shouldRepaint(FlipSwitchPainter old) => true;
}
