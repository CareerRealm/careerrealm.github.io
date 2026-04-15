import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 7 dramatically different timer face styles.
class TimerFaceWidget extends StatelessWidget {
  final TimerFace face;
  final double progress;    // 0.0 → 1.0
  final String timeString;  // formatted "MM:SS"
  final String centerLabel;
  final Color ringColor;
  final bool isRunning;
  final bool isComplete;
  final Animation<double> pulseAnimation;
  final String? phaseEmoji;
  final bool isCountdown;

  const TimerFaceWidget({
    super.key,
    required this.face,
    required this.progress,
    required this.timeString,
    required this.centerLabel,
    required this.ringColor,
    required this.isRunning,
    required this.isComplete,
    required this.pulseAnimation,
    this.phaseEmoji,
    this.isCountdown = true,
  });

  @override
  Widget build(BuildContext context) {
    switch (face) {
      case TimerFace.ring:    return _Ring(this);
      case TimerFace.arcs:    return _Arcs(this);
      case TimerFace.dots:    return _Dots(this);
      case TimerFace.minimal: return _Minimal(this);
      case TimerFace.neon:    return _Neon(this);
      case TimerFace.analog:  return _Analog(this);
      case TimerFace.digital: return _Digital(this);
      case TimerFace.glowNeo: return _GlowNeo(this);
      case TimerFace.celestial: return _Celestial(this);
      case TimerFace.ambientFlow: return _AmbientFlow(this);
    }
  }
}

// ─── Shared helper ──────────────────────────────────────────────────────────
Widget _centerText(TimerFaceWidget w, {double fontSize = 44}) {
  final double scale = w.timeString.length > 5 ? 0.72 : 1.0;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (w.phaseEmoji != null) Text(w.phaseEmoji!, style: const TextStyle(fontSize: 20)),
      Text(w.timeString,
          style: TextStyle(fontSize: fontSize * scale, fontWeight: FontWeight.w700,
              color: Colors.white, fontFamily: 'monospace', letterSpacing: -1)),
      Text(w.centerLabel, style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
    ],
  );
}

// ════════════════════ 1. CLASSIC RING ════════════════════════════════════════
class _Ring extends StatelessWidget {
  final TimerFaceWidget w;
  const _Ring(this.w);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: w.pulseAnimation,
    builder: (_, __) {
      final glow = w.isRunning ? 0.28 + w.pulseAnimation.value * 0.2 : 0.06;
      return Container(
        width: 220, height: 220,
        decoration: BoxDecoration(shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: w.ringColor.withValues(alpha: glow), blurRadius: 40, spreadRadius: 4)]),
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 220, height: 220,
            child: CircularProgressIndicator(
              value: w.progress, strokeWidth: 14,
              backgroundColor: AppColors.timerRingBg,
              valueColor: AlwaysStoppedAnimation(w.isComplete ? AppColors.green : w.ringColor),
              strokeCap: StrokeCap.round,
            )),
          _centerText(w),
        ]),
      );
    },
  );
}

// ════════════════════ 2. ARC SEGMENTS (60 thin arcs) ═════════════════════════
class _Arcs extends StatelessWidget {
  final TimerFaceWidget w;
  const _Arcs(this.w);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: w.pulseAnimation,
    builder: (_, __) => CustomPaint(
      size: const Size(220, 220),
      painter: _ArcsPainter(progress: w.progress, color: w.isComplete ? AppColors.green : w.ringColor,
          glow: w.isRunning ? 0.25 + w.pulseAnimation.value * 0.15 : 0.04),
      child: SizedBox(width: 220, height: 220, child: Center(child: _centerText(w))),
    ),
  );
}

class _ArcsPainter extends CustomPainter {
  final double progress, glow; final Color color;
  _ArcsPainter({required this.progress, required this.color, required this.glow});
  @override
  void paint(Canvas canvas, Size size) {
    const n = 60; const gap = 0.04;
    final r = size.width / 2 - 16; final c = Offset(size.width / 2, size.height / 2);
    final filled = (progress * n).round();
    for (int i = 0; i < n; i++) {
      final a = -pi / 2 + i * (2 * pi / n);
      final rect = Rect.fromCircle(center: c, radius: r);
      if (i < filled) {
        canvas.drawArc(rect, a, 2 * pi / n - gap, false,
            Paint()..style = PaintingStyle.stroke ..strokeWidth = 12 ..strokeCap = StrokeCap.round
                   ..color = color.withValues(alpha: glow) ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawArc(rect, a, 2 * pi / n - gap, false,
            Paint()..style = PaintingStyle.stroke ..strokeWidth = 10 ..strokeCap = StrokeCap.round ..color = color);
      } else {
        canvas.drawArc(rect, a, 2 * pi / n - gap, false,
            Paint()..style = PaintingStyle.stroke ..strokeWidth = 6 ..strokeCap = StrokeCap.round ..color = AppColors.timerRingBg);
      }
    }
  }
  @override bool shouldRepaint(_ArcsPainter o) => true;
}

// ════════════════════ 3. DOT RING (48 dots) ══════════════════════════════════
class _Dots extends StatelessWidget {
  final TimerFaceWidget w;
  const _Dots(this.w);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: w.pulseAnimation,
    builder: (_, __) => CustomPaint(
      size: const Size(220, 220),
      painter: _DotsPainter(progress: w.progress, color: w.isComplete ? AppColors.green : w.ringColor,
          glow: w.isRunning ? 0.12 + w.pulseAnimation.value * 0.15 : 0.04),
      child: SizedBox(width: 220, height: 220, child: Center(child: _centerText(w))),
    ),
  );
}

class _DotsPainter extends CustomPainter {
  final double progress, glow; final Color color;
  _DotsPainter({required this.progress, required this.color, required this.glow});
  @override
  void paint(Canvas canvas, Size size) {
    const n = 48;
    final r = size.width / 2 - 14; final c = Offset(size.width / 2, size.height / 2);
    final filled = (progress * n).round();
    for (int i = 0; i < n; i++) {
      final a = -pi / 2 + i * (2 * pi / n);
      final p = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      if (i < filled) {
        canvas.drawCircle(p, 7, Paint()..color = color.withValues(alpha: glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawCircle(p, 5.5, Paint()..color = color);
      } else {
        canvas.drawCircle(p, 3, Paint()..color = AppColors.timerRingBg);
      }
    }
  }
  @override bool shouldRepaint(_DotsPainter o) => true;
}

// ════════════════════ 4. MINIMAL (thin glowing ring) ═════════════════════════
class _Minimal extends StatelessWidget {
  final TimerFaceWidget w;
  const _Minimal(this.w);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: w.pulseAnimation,
    builder: (_, __) {
      final glowR = w.isRunning ? 24.0 + w.pulseAnimation.value * 20 : 6.0;
      return SizedBox(width: 220, height: 220, child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 214, height: 214,
          child: CircularProgressIndicator(value: w.progress, strokeWidth: 2.5,
            backgroundColor: AppColors.timerRingBg,
            valueColor: AlwaysStoppedAnimation(w.ringColor.withValues(alpha: 0.8)))),
        Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: w.ringColor.withValues(alpha: w.isRunning ? 0.18 : 0.05), blurRadius: glowR)])),
        _centerText(w, fontSize: 52),
      ]));
    },
  );
}

// ════════════════════ 5. NEON DOUBLE RING ════════════════════════════════════
class _Neon extends StatelessWidget {
  final TimerFaceWidget w;
  const _Neon(this.w);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: w.pulseAnimation,
    builder: (_, __) {
      final glow = w.isRunning ? 0.45 + w.pulseAnimation.value * 0.25 : 0.1;
      return Stack(alignment: Alignment.center, children: [
        Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: w.ringColor.withValues(alpha: glow * 0.4), blurRadius: 60)])),
        SizedBox(width: 238, height: 238,
          child: CircularProgressIndicator(value: 1.0, strokeWidth: 1.5,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(w.ringColor.withValues(alpha: 0.18)))),
        Container(width: 215, height: 215,
          decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: w.ringColor.withValues(alpha: glow), blurRadius: 22, spreadRadius: 2)]),
          child: CircularProgressIndicator(value: w.progress, strokeWidth: 9,
            backgroundColor: AppColors.timerRingBg,
            valueColor: AlwaysStoppedAnimation(w.isComplete ? AppColors.green : w.ringColor),
            strokeCap: StrokeCap.round)),
        SizedBox(width: 215, height: 215, child: Center(child: _centerText(w))),
      ]);
    },
  );
}

// ════════════════════ 6. ANALOG CLOCK ════════════════════════════════════════
class _Analog extends StatelessWidget {
  final TimerFaceWidget w;
  const _Analog(this.w);

  @override
  Widget build(BuildContext context) {
    // Parse MM:SS from timeString
    final parts = w.timeString.split(':');
    final minutes = int.tryParse(parts.length >= 2 ? parts[parts.length - 2] : '0') ?? 0;
    final secs    = int.tryParse(parts.last) ?? 0;

    return AnimatedBuilder(
      animation: w.pulseAnimation,
      builder: (_, __) => CustomPaint(
        size: const Size(220, 220),
        painter: _AnalogPainter(
          minutes: minutes, seconds: secs, progress: w.progress,
          ringColor: w.isComplete ? AppColors.green : w.ringColor,
          glow: w.isRunning ? 0.3 + w.pulseAnimation.value * 0.2 : 0.08,
          isRunning: w.isRunning,
          isCountdown: w.isCountdown,
        ),
        child: SizedBox(width: 220, height: 220),
      ),
    );
  }
}

class _AnalogPainter extends CustomPainter {
  final int minutes, seconds;
  final double progress, glow;
  final Color ringColor;
  final bool isRunning;
  final bool isCountdown;

  _AnalogPainter({required this.minutes, required this.seconds, required this.progress,
      required this.ringColor, required this.glow, required this.isRunning, required this.isCountdown});

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 10;

    // Outer glow ring
    canvas.drawCircle(c, r, Paint()..color = ringColor.withValues(alpha: glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));

    // Dial face
    canvas.drawCircle(c, r, Paint()..color = AppColors.surface);
    canvas.drawCircle(c, r, Paint()..color = ringColor.withValues(alpha: 0.18) ..style = PaintingStyle.stroke ..strokeWidth = 2);

    // Tick marks
    for (int i = 0; i < 60; i++) {
      final a = -pi / 2 + i * (2 * pi / 60);
      final isMajor = i % 5 == 0;
      final inner = isMajor ? r - 14 : r - 8;
      canvas.drawLine(
        Offset(c.dx + inner * cos(a), c.dy + inner * sin(a)),
        Offset(c.dx + (r - 3) * cos(a), c.dy + (r - 3) * sin(a)),
        Paint()..color = isMajor ? ringColor.withValues(alpha: 0.8) : AppColors.stroke ..strokeWidth = isMajor ? 2.5 : 1,
      );
    }

    // Draw sweep hand (always move clockwise reliably)
    final double sweepProg = isCountdown ? (60.0 - (minutes + seconds / 60.0) % 60.0) % 60.0 : (minutes % 60 + seconds / 60.0);
    final minAngle = -pi / 2 + sweepProg * (2 * pi / 60);
    _drawHand(canvas, c, minAngle, r * 0.72, 3.5, ringColor);

    // Second hand
    final double secProg = isCountdown ? (60.0 - seconds) % 60.0 : seconds.toDouble();
    final secAngle = -pi / 2 + secProg * (2 * pi / 60);
    _drawHand(canvas, c, secAngle, r * 0.82, 1.5, AppColors.green);

    // Center dot
    canvas.drawCircle(c, 6, Paint()..color = ringColor);
    canvas.drawCircle(c, 3, Paint()..color = Colors.white);

    // Time text below center
    final tp = TextPainter(
      text: TextSpan(
        text: '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy + r * 0.38));
  }

  void _drawHand(Canvas canvas, Offset c, double angle, double length, double width, Color color) {
    final p2 = Offset(c.dx + length * cos(angle), c.dy + length * sin(angle));
    final p0 = Offset(c.dx - (length * 0.18) * cos(angle), c.dy - (length * 0.18) * sin(angle));
    canvas.drawLine(p0, p2, Paint()..color = color ..strokeWidth = width ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_AnalogPainter o) => true;
}

// ════════════════════ 7. DIGITAL LCD (7-segment style) ════════════════════════
class _Digital extends StatelessWidget {
  final TimerFaceWidget w;
  const _Digital(this.w);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: w.pulseAnimation,
    builder: (_, __) {
      final glow = w.isRunning ? 0.5 + w.pulseAnimation.value * 0.35 : 0.15;
      final color = w.isComplete ? AppColors.green : w.ringColor;
      return Container(
        width: 280, height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: glow * 0.4), blurRadius: 30, spreadRadius: 2)],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (w.phaseEmoji != null) Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(w.phaseEmoji!, style: const TextStyle(fontSize: 16)),
          ),
          // Main time digits
          ShaderMask(
            shaderCallback: (r) => LinearGradient(colors: [color, color.withValues(alpha: 0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(r),
            child: Text(w.timeString,
              style: TextStyle(
                fontSize: w.timeString.length > 5 ? 42 : 68, fontWeight: FontWeight.w900, color: Colors.white,
                fontFamily: 'monospace', letterSpacing: 4,
                shadows: [Shadow(color: color.withValues(alpha: glow), blurRadius: 18)],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Progress bar below digits
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: w.progress),
                duration: const Duration(milliseconds: 500),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v, minHeight: 5,
                  backgroundColor: AppColors.timerRingBg,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(w.centerLabel,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6), letterSpacing: 2, fontFamily: 'monospace')),
        ]),
      );
    },
  );
}

// ════════════════════ 8. GLOW NEO ═══════════════════════════════════════════
/// A borderless, pure glowing 3D-text timer face.
class _GlowNeo extends StatelessWidget {
  final TimerFaceWidget w;
  const _GlowNeo(this.w);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: w.pulseAnimation,
    builder: (_, __) {
      final t     = w.pulseAnimation.value;           // 0.0..1.0
      final base  = HSLColor.fromColor(w.isComplete ? AppColors.green : w.ringColor);
      
      // Dramatic hue shifting while running to give life to the text
      final hue1  = (base.hue + (w.isRunning ? 30 * sin(t * pi) : 0)) % 360;
      final hue2  = (base.hue - (w.isRunning ? 20 * sin(t * pi + 0.5) : 0)) % 360;
      final c1    = HSLColor.fromAHSL(1, hue1, base.saturation, base.lightness).toColor();
      final c2    = HSLColor.fromAHSL(1, hue2, base.saturation.clamp(0.4, 1.0),
                      (base.lightness + 0.12).clamp(0.0, 1.0)).toColor();
      
      // Big glow intensity
      final glow  = w.isRunning ? 0.7 + t * 0.3 : 0.3;
      final scale = w.timeString.length > 5 ? 0.75 : 1.0;

      return SizedBox(
        width: 280, height: 280, 
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (w.phaseEmoji != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(w.phaseEmoji!, style: const TextStyle(fontSize: 24)),
                ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ShaderMask(
                    shaderCallback: (r) => LinearGradient(
                      colors: [c1, c2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(r),
                    child: Text(
                      w.timeString,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 72 * scale, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.white,
                        fontFamily: 'monospace', 
                        letterSpacing: 2,
                        shadows: [
                          Shadow(color: c1.withValues(alpha: glow), blurRadius: 30),
                          Shadow(color: c2.withValues(alpha: glow * 0.7), blurRadius: 60, offset: const Offset(0, 10)),
                          Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                w.centerLabel.toUpperCase(), 
                style: TextStyle(
                  fontSize: 12, 
                  color: c1.withValues(alpha: 0.8), 
                  letterSpacing: 4, 
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: c1.withValues(alpha: 0.5), blurRadius: 10)]
                )
              ),
            ],
          ),
        ),
      );
    },
  );
}
// ════════════════════ 9. CELESTIAL ═══════════════════════════════════════════
class _Celestial extends StatelessWidget {
  final TimerFaceWidget w;
  const _Celestial(this.w);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: w.pulseAnimation,
    builder: (_, __) {
      final t = w.pulseAnimation.value;
      final c = w.isComplete ? AppColors.green : w.ringColor;
      
      return SizedBox(
        width: 250, height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Deep background glow
            Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: c.withValues(alpha: 0.15 + (w.isRunning ? t * 0.1 : 0)), blurRadius: 80, spreadRadius: 20),
                ]),
            ),
            // Slow spinning dashed galaxy ring
            Transform.rotate(
              angle: w.isRunning ? (DateTime.now().millisecondsSinceEpoch % 10000) / 10000 * 2 * pi : 0,
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _CelestialRingPainter(color: c.withValues(alpha: 0.5), strokeWidth: 2, dashWidth: 4, dashSpace: 8),
              ),
            ),
            // Inner gradient solid ring
            Container(
              width: 190, height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.withValues(alpha: 0.3), width: 1.5),
                gradient: RadialGradient(
                  colors: [Colors.transparent, c.withValues(alpha: w.isRunning ? 0.2 + t * 0.1 : 0.05)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            // Progress arc glowing brightly
            SizedBox(
              width: 190, height: 190,
              child: CircularProgressIndicator(
                value: w.progress,
                strokeWidth: 4,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(c),
                strokeCap: StrokeCap.round,
              ),
            ),
            _centerText(w, fontSize: 38),
          ],
        ),
      );
    },
  );
}

class _CelestialRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _CelestialRingPainter({required this.color, required this.strokeWidth, required this.dashWidth, required this.dashSpace});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color ..strokeWidth = strokeWidth ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final circumference = 2 * pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    
    for (int i = 0; i < dashCount; i++) {
        final startAngle = i * (dashWidth + dashSpace) / radius;
        final sweepAngle = dashWidth / radius;
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════ 10. AMBIENT FLOW ════════════════════════════════════════
class _AmbientFlow extends StatelessWidget {
  final TimerFaceWidget w;
  const _AmbientFlow(this.w);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: w.pulseAnimation,
    builder: (_, __) {
      final t = w.pulseAnimation.value;
      final c = w.isComplete ? AppColors.green : w.ringColor;
      final p = w.progress.clamp(0.0, 1.0);
      
      // We simulate a fluid-filled orb
      return Container(
        width: 230, height: 230,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c.withValues(alpha: w.isRunning ? 0.3 + t*0.15 : 0.1), blurRadius: 40)],
          border: Border.all(color: c.withValues(alpha: 0.5), width: 3),
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Liquid behind
              Positioned(
                bottom: -10, left: -20, right: -20,
                height: 250 * p + (w.isRunning ? 15 * sin(t * pi) : 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(w.isRunning ? 100 + 40 * cos(t * pi) : 100)),
                  ),
                ),
              ),
              // Liquid front
              Positioned(
                bottom: -10, left: -20, right: -20,
                height: 250 * p + (w.isRunning ? 15 * cos(t * pi) : 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(w.isRunning ? 100 + 40 * sin(t * pi) : 100)),
                  ),
                ),
              ),
              _centerText(w, fontSize: 46),
            ],
          ),
        ),
      );
    },
  );
}
