import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/timer_face_widget.dart';
// ignore: unused_import
import '../widgets/theme_background.dart';

class FullscreenTimerView extends StatefulWidget {
  final Room room;
  final int elapsedMs;
  final VoidCallback onPlayPause;
  final VoidCallback onClose;

  const FullscreenTimerView({
    super.key,
    required this.room,
    required this.elapsedMs,
    required this.onPlayPause,
    required this.onClose,
  });

  @override
  State<FullscreenTimerView> createState() => _FullscreenTimerViewState();
}

class _FullscreenTimerViewState extends State<FullscreenTimerView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pulse.dispose();
    super.dispose();
  }

  String _fmt(Room room, int ms) {
    final total = (room.timerMode == 'DOWN'
            ? max(0, room.currentDurationMs - ms)
            : ms) ~/
        1000;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double _progress(Room room, int ms) {
    if (room.currentDurationMs == 0) return 0;
    return room.timerMode == 'DOWN'
        ? max(0.0, (room.currentDurationMs - ms) / room.currentDurationMs)
        : min(1.0, ms / room.currentDurationMs);
  }

  Color _ringColor(Room room) {
    final p = room.currentPhase;
    if (p == PomodoroPhase.shortBreak) return const Color(0xFF059669);
    if (p == PomodoroPhase.longBreak) return const Color(0xFF0891B2);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final room      = widget.room;
    final ms        = widget.elapsedMs;
    final face      = context.watch<ThemeProvider>().timerFace;
    final isRunning = !room.isPaused && !room.timerCompleted;
    final timeStr   = room.timerCompleted ? '00:00' : _fmt(room, ms);
    final progress  = _progress(room, ms);
    final ringColor = _ringColor(room);

    final playIcon = Icon(
      room.timerCompleted
          ? Icons.replay_rounded
          : isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
      color: Colors.white, size: 44,
    );

    final timerFaceWidget = FittedBox(
      fit: BoxFit.contain,
      child: TimerFaceWidget(
        face: face,
        progress: progress,
        timeString: timeStr,
        centerLabel: room.pomodoroEnabled
            ? room.currentPhase.label
            : (room.timerMode == 'DOWN' ? 'Count Down' : 'Count Up'),
        ringColor: ringColor,
        isRunning: isRunning,
        isComplete: room.timerCompleted,
        pulseAnimation: _pulse,
        phaseEmoji: room.pomodoroEnabled ? room.currentPhase.emoji : null,
        isCountdown: room.timerMode == 'DOWN',
      ),
    );

    final playBtn = GestureDetector(
      onTap: widget.onPlayPause,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [ringColor, ringColor.withValues(alpha: 0.7)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: ringColor.withValues(alpha: 0.55), blurRadius: 32, spreadRadius: 4)],
        ),
        child: playIcon,
      ),
    );

    final topBar = Positioned(
      top: 0, left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
            child: Text('🔑 ${room.id}', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white70, size: 28),
            ),
          ),
        ]),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrientationBuilder(builder: (ctx, orientation) {
        if (orientation == Orientation.landscape) {
          // LANDSCAPE: Timer completely fills screen, controls float
          return Stack(
            children: [
              // Massive Center Timer
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  child: timerFaceWidget,
                ),
              ),
              // Floating Play Button
              Positioned(
                bottom: 24, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(40)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        playBtn,
                        const SizedBox(width: 20),
                        Text('${face.emoji}  ${face.label}', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ),
              ),
              topBar,
            ],
          );
        } else {
          // PORTRAIT: Maximize vertical space safely
          return SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 60), // Room for top bar
                    if (room.pomodoroEnabled)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: ringColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: ringColor.withValues(alpha: 0.4))),
                        child: Text('${room.currentPhase.emoji}  ${room.currentPhase.label}', style: TextStyle(fontSize: 16, color: ringColor, fontWeight: FontWeight.w600)),
                      )
                    else
                      const SizedBox(height: 10),
                    
                    // Maximized Timer
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox.expand(child: timerFaceWidget),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    playBtn,
                    const SizedBox(height: 16),
                    Text('${face.emoji}  ${face.label}', style: TextStyle(fontSize: 14, color: AppColors.textMuted.withValues(alpha: 0.6))),
                    const SizedBox(height: 40),
                  ],
                ),
                topBar,
              ],
            ),
          );
        }
      }),
    );
  }
}


// ─── Twinkling star field (used as overlay on solid themes) ─────────────────
class _StarField extends StatefulWidget {
  const _StarField();
  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = Random();
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _stars = List.generate(60, (_) => _Star(_rng));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _StarPainter(_stars, _ctrl.value),
        ),
      );
}

class _Star {
  final double x, y, size, twinkleOffset;
  _Star(Random r)
      : x = r.nextDouble(), y = r.nextDouble(),
        size = r.nextDouble() * 2.5 + 0.5,
        twinkleOffset = r.nextDouble();
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final tw = (sin((t + s.twinkleOffset) * 2 * pi) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: 0.12 + tw * 0.45);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => true;
}
