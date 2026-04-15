import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps any screen body with an animated theme-specific background layer.
/// Drop this as the first child in a Stack on top of your gradient container.
class ThemeBackground extends StatefulWidget {
  final ThemeBg style;
  final Widget child;
  const ThemeBackground({super.key, required this.style, required this.child});

  @override
  State<ThemeBackground> createState() => _ThemeBackgroundState();
}

class _ThemeBackgroundState extends State<ThemeBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  List<_Particle> _particles = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _particles = _buildParticles(widget.style);
    // 600-second duration = loop imperceptibly slow; particle speeds drive real motion
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 600),
    )..repeat();
  }

  @override
  void didUpdateWidget(ThemeBackground old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) {
      _particles = _buildParticles(widget.style);
    }
  }

  List<_Particle> _buildParticles(ThemeBg style) {
    switch (style) {
      case ThemeBg.clouds:
        return List.generate(7, (_) => _CloudParticle(_rng));
      case ThemeBg.forest:
        return List.generate(30, (_) => _LeafParticle(_rng));
      case ThemeBg.aurora:
        return List.generate(3, (_) => _AuroraWave(_rng));
      case ThemeBg.petals:
        return List.generate(25, (_) => _PetalParticle(_rng));
      case ThemeBg.rain:
        return List.generate(60, (_) => _RainDrop(_rng));
      case ThemeBg.stars:
        return List.generate(80, (_) => _StarParticle(_rng));
      case ThemeBg.fireflies:
        return List.generate(20, (_) => _FireflyParticle(_rng));
      case ThemeBg.solid:
        return [];
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.style == ThemeBg.solid) return widget.child;

    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                t: _ctrl.value * 600, // scale 0→1 back to 0→600 seconds
                primaryColor: AppColors.primary,
                style: widget.style,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle base
// ─────────────────────────────────────────────────────────────────────────────
abstract class _Particle {
  double x, y, speed, size, phase;
  _Particle(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        speed = r.nextDouble() * 0.5 + 0.1,
        size = r.nextDouble() * 10 + 4,
        phase = r.nextDouble();
}

class _CloudParticle extends _Particle {
  late double width;
  _CloudParticle(Random r) : super(r) {
    y = r.nextDouble() * 0.5;
    size = r.nextDouble() * 40 + 30;
    width = size * (1.8 + r.nextDouble());
    speed = 0.02 + r.nextDouble() * 0.03;
  }
}

class _LeafParticle extends _Particle {
  double rotation, rotSpeed, swing;
  _LeafParticle(Random r)
      : rotation = r.nextDouble() * 2 * pi,
        rotSpeed = (r.nextDouble() - 0.5) * 0.05,
        swing = r.nextDouble() * 0.08 + 0.02,
        super(r) {
    speed = 0.05 + r.nextDouble() * 0.06;
    size = 4 + r.nextDouble() * 6;
  }
}

class _AuroraWave extends _Particle {
  double amplitude, frequency;
  _AuroraWave(Random r)
      : amplitude = 0.06 + r.nextDouble() * 0.06,
        frequency = 1.5 + r.nextDouble() * 2,
        super(r) {
    y = 0.1 + r.nextDouble() * 0.4;
    speed = 0.08 + r.nextDouble() * 0.06;
  }
}

class _PetalParticle extends _Particle {
  double swing, rotation;
  _PetalParticle(Random r)
      : swing = r.nextDouble() * 0.06 + 0.02,
        rotation = r.nextDouble() * pi,
        super(r) {
    speed = 0.04 + r.nextDouble() * 0.04;
    size = 3 + r.nextDouble() * 5;
  }
}

class _RainDrop extends _Particle {
  _RainDrop(Random r) : super(r) {
    speed = 0.3 + r.nextDouble() * 0.3;
    size = 8 + r.nextDouble() * 12;
  }
}

class _StarParticle extends _Particle {
  _StarParticle(Random r) : super(r) {
    size = 0.5 + r.nextDouble() * 2;
    speed = 0.2 + r.nextDouble() * 0.4;
  }
}

class _FireflyParticle extends _Particle {
  double radiusX, radiusY;
  _FireflyParticle(Random r)
      : radiusX = 0.04 + r.nextDouble() * 0.12,
        radiusY = 0.03 + r.nextDouble() * 0.08,
        super(r) {
    size = 2 + r.nextDouble() * 3;
    speed = 0.04 + r.nextDouble() * 0.08;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Master painter — dispatches by style
// ─────────────────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final Color primaryColor;
  final ThemeBg style;

  _ParticlePainter({
    required this.particles, required this.t,
    required this.primaryColor, required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case ThemeBg.clouds:   _drawClouds(canvas, size);    break;
      case ThemeBg.forest:   _drawLeaves(canvas, size);    break;
      case ThemeBg.aurora:   _drawAurora(canvas, size);    break;
      case ThemeBg.petals:   _drawPetals(canvas, size);    break;
      case ThemeBg.rain:     _drawRain(canvas, size);      break;
      case ThemeBg.stars:    _drawStars(canvas, size);     break;
      case ThemeBg.fireflies:_drawFireflies(canvas, size); break;
      case ThemeBg.solid:    break;
    }
  }

  void _drawClouds(Canvas canvas, Size sz) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final c in particles.cast<_CloudParticle>()) {
      final cx = ((c.x + t * c.speed) % 1.2 - 0.1) * sz.width;
      final cy = c.y * sz.height;
      p.color = Colors.white.withValues(alpha: 0.07 + sin(t * 2 * pi + c.phase) * 0.02);
      // Draw fluffy cloud from overlapping ellipses
      for (int i = 0; i < 4; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + (i - 1.5) * c.width * 0.28, cy + (i % 2 == 0 ? 0 : -c.size * 0.3)),
            width: c.width * 0.5,
            height: c.size,
          ),
          p,
        );
      }
    }
  }

  void _drawLeaves(Canvas canvas, Size sz) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final l in particles.cast<_LeafParticle>()) {
      final progress = (l.y + t * l.speed) % 1.1;
      final cx = (l.x + sin(t * 2 * pi * l.swing + l.phase) * 0.08) * sz.width;
      final cy = progress * sz.height;
      final rotation = l.rotation + t * l.rotSpeed * 10;
      final opacity = progress < 0.1 ? progress * 10 : (progress > 0.95 ? (1.1 - progress) * 20 : 1.0);
      p.color = primaryColor.withValues(alpha: 0.25 * opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rotation);
      // Leaf shape (oval)
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: l.size * 1.8, height: l.size), p);
      canvas.restore();
    }
  }

  void _drawAurora(Canvas canvas, Size sz) {
    for (final w in particles.cast<_AuroraWave>()) {
      final path = Path();
      const steps = 80;
      for (int i = 0; i <= steps; i++) {
        final x = i / steps * sz.width;
        final baseY = w.y * sz.height;
        final waveY = baseY + sin(i / steps * 2 * pi * w.frequency + t * 2 * pi * w.speed + w.phase) * sz.height * w.amplitude;
        if (i == 0) {
          path.moveTo(x, waveY);
        } else {
          path.lineTo(x, waveY);
        }
      }
      path.lineTo(sz.width, 0);
      path.lineTo(0, 0);
      path.close();

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.0),
            primaryColor.withValues(alpha: 0.08 + sin(t * 2 * pi + w.phase) * 0.03),
            Colors.cyan.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height));
      canvas.drawPath(path, paint);
    }
  }

  void _drawPetals(Canvas canvas, Size sz) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final l in particles.cast<_PetalParticle>()) {
      final progress = (l.y + t * l.speed) % 1.1;
      final cx = (l.x + sin(t * 2 * pi * l.swing + l.phase) * 0.1) * sz.width;
      final cy = progress * sz.height;
      final opacity = progress < 0.1 ? progress * 10 : (progress > 0.9 ? (1.1 - progress) * 10 : 1.0);
      p.color = primaryColor.withValues(alpha: 0.35 * opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(l.rotation + t * 2);
      // Petal — two overlapping ellipses
      canvas.drawOval(Rect.fromCenter(center: Offset(l.size * 0.4, 0), width: l.size * 1.4, height: l.size * 0.7), p);
      p.color = Colors.white.withValues(alpha: 0.06 * opacity.clamp(0.0, 1.0));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: l.size * 0.8, height: l.size * 0.5), p);
      canvas.restore();
    }
  }

  void _drawRain(Canvas canvas, Size sz) {
    final p = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final r in particles.cast<_RainDrop>()) {
      final progress = (r.y + t * r.speed) % 1.05;
      final cx = r.x * sz.width;
      final cy = progress * sz.height;
      p.color = AppColors.primaryLight.withValues(alpha: 0.15);
      canvas.drawLine(Offset(cx, cy), Offset(cx - sz.width * 0.01, cy + r.size), p);
    }
  }

  void _drawStars(Canvas canvas, Size sz) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in particles.cast<_StarParticle>()) {
      final twinkle = (sin((t + s.phase) * 2 * pi * s.speed) + 1) / 2;
      p.color = Colors.white.withValues(alpha: 0.1 + twinkle * 0.45);
      canvas.drawCircle(Offset(s.x * sz.width, s.y * sz.height), s.size, p);
    }
  }

  void _drawFireflies(Canvas canvas, Size sz) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final f in particles.cast<_FireflyParticle>()) {
      final angle = t * 2 * pi * f.speed + f.phase;
      final cx = (f.x + cos(angle) * f.radiusX) * sz.width;
      final cy = (f.y + sin(angle) * f.radiusY) * sz.height;
      final glow = (sin(angle * 3 + f.phase) + 1) / 2;
      // Glow halo
      p.color = AppColors.primaryLight.withValues(alpha: 0.04 + glow * 0.06);
      canvas.drawCircle(Offset(cx, cy), f.size * 3, p);
      // Core dot
      p.color = AppColors.primaryLight.withValues(alpha: 0.5 + glow * 0.5);
      canvas.drawCircle(Offset(cx, cy), f.size * 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
