import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../services/room_service.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_background.dart';
import '../widgets/timer_face_widget.dart';
import 'fullscreen_timer_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  const RoomScreen({super.key, required this.roomId});
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final _rs  = RoomService();
  final _snd = SoundService();
  final _msgCtrl   = TextEditingController();
  final _chatScroll = ScrollController();
  static const _cleanupChannel = MethodChannel('com.zworlddev.harmonitimer/room_cleanup');

  // Timer state
  Timer?  _tick;
  int     _elapsedMs = 0;
  bool    _lastPaused = true;
  bool    _isFullscreen = false;
  int     _unrecordedMs = 0;
  int     _lastTickMs = 0;
  final   Map<String, int> _taskExtraMs = {};
  final   Map<String, int> _taskBaseElapsed = {}; // snapshot at last sync
  int     _lastTaskSyncMs = 0;
  bool    _isSyncingTasks = false;
  PomodoroPhase? _prevPhase;
  int     _lastChatCount = 0;
  final   Set<int> _shownMilestones = {}; // track which hour milestones shown this session
  Room?   _room;
  List<Task> _tasks = [];
  List<ChatMessage> _msgs = [];

  // HP / attendance bar state
  double _hp = 1.0;         // 1.0 = full HP, decreases during focus
  bool   _hpZeroPlayed = false; // prevent repeated alert at 0

  // Sound selection — persists across sound sheet open/close
  String? _selectedAmbient;

  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<ChatMessage>>? _chatSub;

  late AnimationController _pulse;
  late TabController _mainTabCtrl;
  late AppProvider _ap;

  AppLifecycleState _appState = AppLifecycleState.resumed;

  bool    _isLeaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().onAction = _handleNotificationAction;
    _ap = context.read<AppProvider>();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _mainTabCtrl = TabController(length: 3, vsync: this);
    _mainTabCtrl.addListener(() {
      if (_mainTabCtrl.index == 2) {
        final me = _ap.user?.displayName;
        if (me != null) _rs.markMessagesSeen(widget.roomId, me);
      }
    });
    _joinRoom();
    
    _tasksSub = _rs.tasksStream(widget.roomId).listen((t) { if (mounted) setState(() => _tasks = t); });
    _chatSub = _rs.chatStream(widget.roomId).listen((c) {
      if (mounted) {
        // Play notification for new messages from others
        if (c.length > _lastChatCount && _lastChatCount > 0) {
          final newest = c.last;
          if (!newest.isSystem && newest.sender != (_ap.user?.displayName ?? '')) {
            if (_appState == AppLifecycleState.paused || _appState == AppLifecycleState.hidden) {
              NotificationService().show(
                id: newest.id.hashCode.abs(),
                title: newest.sender,
                body: newest.text,
              );
            } else {
              _snd.playNotification();
            }
          }
        }
        _lastChatCount = c.length;
        setState(() => _msgs = c);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = state;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _updateOngoingNotification();
    } else if (state == AppLifecycleState.resumed) {
      NotificationService().cancel(999);
    }
  }

  void _updateOngoingNotification() {
    final r = _room;
    if (r == null || r.timerCompleted) return;
    if (_appState == AppLifecycleState.resumed) return;

    final remainMs = r.currentDurationMs - _elapsedMs;
    final targetMs = DateTime.now().millisecondsSinceEpoch + remainMs;

    NotificationService().showOngoingTimer(
      title: 'Focus Realm',
      body: r.isPaused ? 'Timer Paused' : r.currentPhase.name.toUpperCase(),
      targetTimeMs: targetMs,
      isPaused: r.isPaused,
    );
  }

  void _handleNotificationAction(String action) {
    if (_room == null) return;
    if (action == 'pause_timer') {
      _rs.pauseTimer(widget.roomId, _elapsedMs);
    } else if (action == 'resume_timer') {
      _rs.resumeTimer(widget.roomId, _elapsedMs);
    } else if (action == 'stop_timer') {
      _rs.completeTimer(widget.roomId);
      NotificationService().cancel(999);
    } else if (action == 'stop_sound') {
      _snd.stopAmbient();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    stopKioskMode();
    _pulse.dispose();
    _mainTabCtrl.dispose();
    _msgCtrl.dispose();
    _chatScroll.dispose();
    _tasksSub?.cancel();
    _chatSub?.cancel();
    super.dispose();
  }

  void _joinRoom() {
    final u = _ap.user;
    if (u != null) {
      _rs.joinRoom(
        widget.roomId,
        u.displayName,
        rankLabel: context.read<ThemeProvider>().showRank ? u.rank : '',
        photoUrl: u.photoUrl,
      );
      // Clean old system (join/left) messages — user messages are never deleted
      _rs.cleanOldSystemMessages(widget.roomId);
      if (defaultTargetPlatform == TargetPlatform.android) {
        _cleanupChannel.invokeMethod('startService', {
          'roomId': widget.roomId,
          'userName': u.displayName,
        }).catchError((_) {});
      }
    }
  }

  // Issue 4 — Back: stay in room silently, timer keeps running
  void _goBack() => Navigator.pop(context);

  void _leaveRoom() async {
    if (_isLeaving) return;
    _isLeaving = true;
    _tick?.cancel();
    stopKioskMode();
    await _syncFocus(session: false);
    await _syncTasks();
    final u = _ap.user;
    if (u != null) await _rs.leaveRoom(widget.roomId, u.displayName);
    if (defaultTargetPlatform == TargetPlatform.android) {
      _cleanupChannel.invokeMethod('stopService').catchError((_) {});
    }
    _ap.setCurrentRoom(null);
    _snd.stopAmbient(); // only stop on actual leave
    _selectedAmbient = null;
    if (mounted) Navigator.pop(context);
  }

  // ── Timer sync ────────────────────────────────────────────────────────────
  void _onRoomUpdate(Room room) {
    final running = !room.isPaused && !room.timerCompleted;
    final wasRunning = !_lastPaused;
    _lastPaused = !running;

    // Phase change detection (Pomodoro)
    if (_prevPhase != null && _prevPhase != room.currentPhase) {
      _snd.playAlert(room.currentPhase == PomodoroPhase.focus
          ? (room.breakAlertSound ?? 'bell')
          : (room.focusAlertSound ?? 'airhorn'));
      // Reset HP at start of each new focus phase
      if (room.currentPhase == PomodoroPhase.focus) {
        _hp = 1.0; _hpZeroPlayed = false;
      }
      setState(() { _elapsedMs = 0; _taskExtraMs.clear(); _taskBaseElapsed.clear(); _lastTaskSyncMs = 0; _shownMilestones.clear(); });
    }
    _prevPhase ??= room.currentPhase;
    _prevPhase = room.currentPhase;

    // (Reverted forced auto-sync that was unintentionally clearing local playback variables)

    // Sync elapsed from server
    if (room.isPaused) {
      // Always sync from server when paused — covers reset case (pausedElapsedMs=0)
      final serverElapsed = room.pausedElapsedMs ?? 0;
      if (_elapsedMs != serverElapsed) {
        setState(() => _elapsedMs = serverElapsed);
      }
    } else if (room.timerStartTime != null) {
      final computed = DateTime.now().millisecondsSinceEpoch - room.timerStartTime!;
      final isUnlimited = room.timerMode == 'UP' &&
          !(room.pomodoroEnabled && room.currentPhase != PomodoroPhase.focus);
      if ((_elapsedMs - computed).abs() > 2000) {
        _elapsedMs = isUnlimited ? computed.clamp(0, computed) : computed.clamp(0, room.currentDurationMs);
      }
    }

    if (running && !wasRunning) { 
      _lastTaskSyncMs = _elapsedMs; 
      _startTick(room); 
      if (context.read<ThemeProvider>().strictFocusMode) {
        startKioskMode();
      }
      // Auto-resume selected sound when timer starts
      if (_selectedAmbient != null) {
        _snd.playAmbient(_selectedAmbient!);
      }
      _updateOngoingNotification();
    }
    if (!running && wasRunning) {
      _tick?.cancel(); _tick = null;
      _syncFocus(session: false); _syncTasks();
      _snd.stopAmbient();
      stopKioskMode();
      _updateOngoingNotification();
    }
  }

  void _startTick(Room room) {
    _tick?.cancel();
    _lastTickMs = DateTime.now().millisecondsSinceEpoch;
    // Snapshot current task elapsed values as our base for incremental updates
    for (final id in room.selectedTaskIds) {
      final t = _tasks.where((t) => t.id == id).firstOrNull;
      if (t != null) _taskBaseElapsed[id] = t.elapsedTimeSec;
    }
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        final currentRoom = _room;
        if (currentRoom == null) return;
        
        final now = DateTime.now().millisecondsSinceEpoch;
        final delta = now - _lastTickMs;
        _lastTickMs = now;
        
        final prevElapsed = _elapsedMs;
        _elapsedMs += delta;
        
        // Sync elapsed from server (only correct large drift)
        if (currentRoom.timerStartTime != null) {
          final computed = now - currentRoom.timerStartTime!;
          final isUnlimitedTick = currentRoom.timerMode == 'UP' &&
              !(currentRoom.pomodoroEnabled && currentRoom.currentPhase != PomodoroPhase.focus);
          if ((_elapsedMs - computed).abs() > 3000) {
            _elapsedMs = isUnlimitedTick ? computed.clamp(0, computed) : computed.clamp(0, currentRoom.currentDurationMs);
          }
        }

        // Effective mode: break phases always count DOWN even in untimed mode
        final bool effectiveDown = currentRoom.timerMode == 'DOWN' ||
            (currentRoom.pomodoroEnabled && currentRoom.currentPhase != PomodoroPhase.focus);

        int activeDelta = delta;
        if (effectiveDown) {
           if (prevElapsed + delta > currentRoom.currentDurationMs) {
               activeDelta = currentRoom.currentDurationMs - prevElapsed;
           }
        }
        if (activeDelta < 0) activeDelta = 0;

        _unrecordedMs += activeDelta;

        // Only track task progress during Focus phases
        final bool isFocusPhase = !currentRoom.pomodoroEnabled ||
            currentRoom.currentPhase == PomodoroPhase.focus;
        if (isFocusPhase) {
          for (final id in (currentRoom.selectedTaskIds)) {
            _taskExtraMs[id] = (_taskExtraMs[id] ?? 0) + activeDelta;
          }
        }

        // ── HP / attendance bar ──────────────────────────────────────────
        // Focus phase: HP drains. Break phase: HP recovers.
        final isBreakPhase = currentRoom.pomodoroEnabled &&
            currentRoom.currentPhase != PomodoroPhase.focus;
        if (!isBreakPhase && activeDelta > 0) {
          // During focus, HP drains based on the focus duration
          // For untimed (UP) mode use a fixed 60-min reference so HP still drains
          final focusDurMs = currentRoom.timerMode == 'UP'
              ? 60 * 60 * 1000.0   // 60 min reference for untimed mode
              : currentRoom.timerDuration.toDouble();
          if (focusDurMs > 0) {
            final prevHp = _hp;
            _hp = (_hp - activeDelta / focusDurMs).clamp(0.0, 1.0);
            if (prevHp > 0 && _hp <= 0 && !_hpZeroPlayed) {
              _hpZeroPlayed = true;
              _snd.playAlert('bell');
              _showHpAlert();
            }
          }
        } else if (isBreakPhase && activeDelta > 0) {
          // During break, HP recovers based on break duration
          final breakDurMs = currentRoom.currentDurationMs.toDouble();
          if (breakDurMs > 0) {
            _hp = (_hp + activeDelta / breakDurMs).clamp(0.0, 1.0);
            _hpZeroPlayed = false; // reset so alert can fire again next focus
          }
        }

        // Sync every 60s
        if (_unrecordedMs >= 60000) _syncFocus(session: false);
        if (_elapsedMs - _lastTaskSyncMs >= 30000) { _lastTaskSyncMs = _elapsedMs; _syncTasks(); }

        // Focus milestone alerts (1h, 2h, 3h, 4h)
        if (currentRoom.pomodoroEnabled && currentRoom.currentPhase == PomodoroPhase.focus) {
          for (final hours in [1, 2, 3, 4]) {
            final ms = hours * 3600000;
            if (prevElapsed < ms && _elapsedMs >= ms && !_shownMilestones.contains(hours)) {
              _shownMilestones.add(hours);
              _snd.playAlert('bell3');
              _showFocusMilestone(hours);
            }
          }
        }

        // Countdown complete (also applies to break phases in untimed mode)
        if (effectiveDown && _elapsedMs >= currentRoom.currentDurationMs) {
          _tick?.cancel(); _lastPaused = true; _onComplete(currentRoom);
        }
      });
    });
  }

  Future<void> _syncFocus({required bool session}) async {
    final ms = _unrecordedMs; if (ms <= 0) return;
    _unrecordedMs = 0;
    
    final isBreak = _room?.pomodoroEnabled == true && _room?.currentPhase != PomodoroPhase.focus;
    await _ap.recordFocusTime((ms / 1000).round(), countSession: session, isBreak: isBreak);
  }

  Future<void> _syncTasks() async {
    if (_isSyncingTasks) return;
    _isSyncingTasks = true;
    try {
      for (final id in _taskExtraMs.keys.toList()) {
        final extraMs = _taskExtraMs[id] ?? 0;
        if (extraMs <= 0) continue;
        final base = _taskBaseElapsed[id] ?? 0;
        final newTotal = base + extraMs ~/ 1000;
        await _rs.updateTaskElapsed(widget.roomId, id, newTotal);
        // Update our base to the new value so next sync is incremental
        _taskBaseElapsed[id] = newTotal;
        _taskExtraMs[id] = extraMs % 1000; // keep sub-second remainder
      }
    } finally {
      _isSyncingTasks = false;
    }
  }

  void _onComplete(Room room) async {
    await _syncFocus(session: true); await _syncTasks();
    await _rs.completeTimer(widget.roomId);
    _snd.stopAmbient();
    if (!mounted) return;
    _showBanner(room);
    if (room.pomodoroEnabled) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) { await _rs.advancePomodoroPhase(widget.roomId, room); setState(() { _elapsedMs = 0; _taskExtraMs.clear(); }); }
    }
  }

  static const _milestoneMessages = {
    1: {"emoji": "🔥", "msg": "Amazing dedication! You've been focusing for 1 hour straight. Remember to stretch and rest your eyes briefly when you can.", "color": 0xFFB45309},
    2: {"emoji": "⚡", "msg": "Incredible! 2 hours of non-stop focus! You're on fire. Take a short walk to recharge.", "color": 0xFF7C3AED},
    3: {"emoji": "🏆", "msg": "3 hours of pure concentration! You're a focus champion. Please make sure to hydrate and take a proper break soon.", "color": 0xFF059669},
    4: {"emoji": "👑", "msg": "4 hours straight?! Legendary focus session! Seriously, take a real break now — your brain has earned it.", "color": 0xFFDC2626},
  };

  void _showFocusMilestone(int hours) {
    final data = _milestoneMessages[hours];
    if (data == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.transparent, elevation: 0, duration: const Duration(seconds: 15),
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Color(data["color"] as int), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Text(data["emoji"] as String, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Text(data["msg"] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ]),
      ),
    ));
  }

  void _showBanner(Room room) {
    final focus = room.currentPhase == PomodoroPhase.focus;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.transparent, elevation: 0, duration: const Duration(seconds: 4),
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: focus ? [Color(0xFF065F46), Color(0xFF047857)] : [Color(0xFF1E1A3E), Color(0xFF6D28D9)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Text(focus ? '🎉' : '🎯', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Text(focus ? 'Focus done! Break time 🧘' : 'Break over! Back to focus 💪',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ]),
      ),
    ));
  }

  String _fmtTime(Room room) {
    final effectiveDown = room.timerMode == 'DOWN' ||
        (room.pomodoroEnabled && room.currentPhase != PomodoroPhase.focus);
    int ms = effectiveDown ? max(0, room.currentDurationMs - _elapsedMs) : _elapsedMs;
    final s = ms ~/ 1000; final h = s ~/ 3600; final m = (s % 3600) ~/ 60; final sec = s % 60;
    return h > 0
        ? '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}'
        : '${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';
  }

  double _progress(Room room) {
    if (room.currentDurationMs == 0) return 0;
    final effectiveDown = room.timerMode == 'DOWN' ||
        (room.pomodoroEnabled && room.currentPhase != PomodoroPhase.focus);
    return effectiveDown
        ? max(0.0, (room.currentDurationMs - _elapsedMs) / room.currentDurationMs)
        : min(1.0, _elapsedMs / room.currentDurationMs);
  }

  void _toggleTimer(Room room) async {
    if (room.timerCompleted) { await _rs.resetTimer(widget.roomId); setState(() { _elapsedMs = 0; _taskExtraMs.clear(); _taskBaseElapsed.clear(); }); return; }
    if (room.isPaused) {
      room.timerStartTime == null ? await _rs.startTimer(widget.roomId) : await _rs.resumeTimer(widget.roomId, _elapsedMs);
    } else {
      // Stop tick immediately to prevent seconds going backwards
      _tick?.cancel();
      _tick = null;
      _snd.stopAmbient();
      await _syncTasks();
      await _rs.pauseTimer(widget.roomId, _elapsedMs);
    }
  }

  Color get _ringColor {
    final p = _room?.currentPhase ?? PomodoroPhase.focus;
    if (p == PomodoroPhase.shortBreak) return Color(0xFF059669);
    if (p == PomodoroPhase.longBreak)  return Color(0xFF0891B2);
    return AppColors.primary;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Room?>(
      stream: _rs.roomStream(widget.roomId),
      builder: (ctx, snap) {
        // Handle stream errors gracefully
        if (snap.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('⚠️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('Connection error', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Could not connect to this room', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ]),
              ),
            ),
          );
        }

        final room = snap.data;
        if (room != null) {
          _room = room;
          WidgetsBinding.instance.addPostFrameCallback((_) => _onRoomUpdate(room));
          for (final id in room.selectedTaskIds) {
            _taskExtraMs.putIfAbsent(id, () => 0);
          }
          _taskExtraMs.removeWhere((id, _) => !room.selectedTaskIds.contains(id));
        }
        return PopScope(
          canPop: !_isFullscreen,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            setState(() => _isFullscreen = false);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: ThemeBackground(
              style: AppColors.activeTheme.bg,
              child: _isFullscreen
                ? FullscreenTimerView(
                    room: room!, elapsedMs: _elapsedMs,
                    onPlayPause: () => _toggleTimer(room),
                    onClose: () => setState(() => _isFullscreen = false),
                  )
                : SafeArea(child: Column(children: [
                    _topBar(room),
                    if (room == null)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else
                      Expanded(child: _content(room)),
                  ])),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(Room? room) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    color: AppColors.surface.withValues(alpha: 0.85),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), color: AppColors.primaryLight, onPressed: _goBack, tooltip: 'Back (stay in room)'),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Study Room', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
        Text('ID: ${widget.roomId}', style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.5)),
      ])),
      if (room?.pomodoroEnabled == true)
        _badge('${room!.currentPhase.emoji} ${room.currentPhase.label}'),
      IconButton(icon: const Icon(Icons.copy_rounded, size: 16), color: AppColors.textSecondary, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, constraints: const BoxConstraints(),
          onPressed: () { Clipboard.setData(ClipboardData(text: widget.roomId)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room ID copied!'))); }),
      const SizedBox(width: 4),
      IconButton(icon: const Icon(Icons.bar_chart_rounded, size: 20), color: AppColors.textSecondary, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, constraints: const BoxConstraints(), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()))),
      const SizedBox(width: 4),
      IconButton(icon: const Icon(Icons.settings_outlined, size: 20), color: AppColors.textSecondary, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, constraints: const BoxConstraints(), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      const SizedBox(width: 4),
      TextButton(onPressed: _leaveRoom, style: TextButton.styleFrom(foregroundColor: Colors.red.shade400, padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('Leave', style: TextStyle(fontSize: 12))),
      const SizedBox(width: 4),
    ]),
  );

  Widget _badge(String text) => Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  Widget _content(Room room) => Column(children: [
      Container(color: AppColors.surface.withValues(alpha: 0.85),
        child: TabBar(controller: _mainTabCtrl, tabs: const [Tab(text: '⏱ Timer'), Tab(text: '📋 Tasks'), Tab(text: '💬 Chat')])),
      Expanded(child: TabBarView(controller: _mainTabCtrl, children: [_timerTab(room), _tasksTab(room), _chatTab()])),
    ]);

  // ══════════════════════ TIMER TAB ═══════════════════════════════════════
  Widget _timerTab(Room room) {
    return LayoutBuilder(builder: (ctx, constraints) {
      // Use wide layout on large screens (desktop/tablet landscape) and
      // portrait layout on small/narrow screens (phone portrait).
      final isWide = constraints.maxWidth >= 600;
      if (isWide) return _timerLandscape(room);
      return _timerPortrait(room);
    });
  }

  Widget _timerPortrait(Room room) {
    final isRunning = !room.isPaused && !room.timerCompleted;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(children: [
        if (room.pomodoroEnabled) _pomodoroBar(room),
        const SizedBox(height: 14),
        TimerFaceWidget(
          face: context.watch<ThemeProvider>().timerFace, progress: _progress(room),
          timeString: room.timerCompleted ? '00:00' : _fmtTime(room),
          centerLabel: room.pomodoroEnabled ? room.currentPhase.label : (room.timerMode == 'DOWN' ? 'Count Down' : 'Count Up'),
          ringColor: _ringColor, isRunning: isRunning, isComplete: room.timerCompleted,
          pulseAnimation: _pulse, phaseEmoji: room.pomodoroEnabled ? room.currentPhase.emoji : null,
          isCountdown: room.timerMode == 'DOWN',
        ),
        const SizedBox(height: 12),
        // HP attendance bar
        _hpBar(room),
        if (room.selectedTaskIds.isNotEmpty)
          ..._tasks.where((t) => room.selectedTaskIds.contains(t.id))
              .map((t) => _TaskMini(task: t, extraSec: (_taskExtraMs[t.id] ?? 0) ~/ 1000)),
        if (room.selectedTaskIds.isEmpty)
          Text('No task assigned · go to Tasks tab', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 16),
        _controls(room),
        const SizedBox(height: 14),
        _pomodoroCard(room),
        const SizedBox(height: 10),
        if (room.participants.isNotEmpty) _participantsCard(room),
      ]),
      ),
    );
  }

  Widget _timerLandscape(Room room) {
    final isRunning = !room.isPaused && !room.timerCompleted;
    return Row(children: [
      // Left: face + pomodoro bar
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (room.pomodoroEnabled) ...[_pomodoroBar(room), const SizedBox(height: 10)],
          TimerFaceWidget(
            face: context.watch<ThemeProvider>().timerFace, progress: _progress(room),
            timeString: room.timerCompleted ? '00:00' : _fmtTime(room),
            centerLabel: room.pomodoroEnabled ? room.currentPhase.label : (room.timerMode == 'DOWN' ? 'Count Down' : 'Count Up'),
            ringColor: _ringColor, isRunning: isRunning, isComplete: room.timerCompleted,
            pulseAnimation: _pulse, phaseEmoji: room.pomodoroEnabled ? room.currentPhase.emoji : null,
            isCountdown: room.timerMode == 'DOWN',
          ),
        ]),
      )),
      // Right: controls + HP bar + tasks + pomodoro card + participants
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(children: [
        _controls(room),
        const SizedBox(height: 10),
        _hpBar(room),
        if (room.selectedTaskIds.isNotEmpty)
          ..._tasks.where((t) => room.selectedTaskIds.contains(t.id))
              .map((t) => _TaskMini(task: t, extraSec: (_taskExtraMs[t.id] ?? 0) ~/ 1000)),
        if (room.selectedTaskIds.isEmpty)
          Text('No task assigned · go to Tasks tab', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 14),
        _pomodoroCard(room),
        const SizedBox(height: 10),
        if (room.participants.isNotEmpty) _participantsCard(room),
      ]))),
    ]);
  }

  Widget _controls(Room room) {
    final isRunning = !room.isPaused && !room.timerCompleted;
    return Column(children: [
      // 1. Prominent Play/Pause Button
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _toggleTimer(room),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_ringColor, _ringColor.withValues(alpha: 0.7)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _ringColor.withValues(alpha: 0.4), blurRadius: 18)],
            ),
            child: Icon(room.timerCompleted ? Icons.replay_rounded : isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 38),
          ),
        ),
      ),
      const SizedBox(height: 20),
      // 2. Secondary controls neatly wrapped below
      Wrap(spacing: 24, runSpacing: 16, alignment: WrapAlignment.center, children: [
        _CtrlBtn(icon: room.timerMode == 'DOWN' ? Icons.south_rounded : Icons.north_rounded,
            label: room.timerMode, onTap: () => _rs.setTimerMode(widget.roomId, room.timerMode == 'DOWN' ? 'UP' : 'DOWN')),
        _CtrlBtn(icon: Icons.skip_next_rounded, label: room.pomodoroEnabled ? 'Skip' : 'Reset',
            onTap: () async {
              await _syncFocus(session: false); await _syncTasks();
              room.pomodoroEnabled ? await _rs.skipPhase(widget.roomId, room) : await _rs.resetTimer(widget.roomId);
              setState(() { _elapsedMs = 0; _taskExtraMs.clear(); });
            }),
        _CtrlBtn(icon: Icons.timer_outlined, label: '${room.timerDuration ~/ 60000}m', onTap: () => _showDuration(room)),
        _CtrlBtn(icon: Icons.music_note_rounded, label: room.selectedAmbient != null ? '♪ On' : 'Sound',
            active: room.selectedAmbient != null, onTap: () => _showSound(room)),
        _CtrlBtn(icon: Icons.watch_rounded, label: context.watch<ThemeProvider>().timerFace.label.split(' ').first,
            active: true, onTap: () => _showFacePicker(context)),
        _CtrlBtn(icon: Icons.fullscreen_rounded, label: 'Full',
            onTap: () => setState(() => _isFullscreen = true)),
      ]),
    ]);
  }

  Widget _pomodoroBar(Room room) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.stroke)),
    child: Row(children: [
      Text('Round ${(room.pomodoroRound % 4) + 1}/4', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      const Spacer(),
      ...List.generate(4, (i) => Container(
        width: 10, height: 10, margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: (room.pomodoroRound % 4) > i ? AppColors.primary : AppColors.surfaceLight,
          border: Border.all(color: AppColors.stroke)),
      )),
      const SizedBox(width: 8),
      Text('${room.pomodoroRound} 🍅', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
    ]),
  );

  Widget _pomodoroCard(Room room) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.stroke)),
    child: Row(children: [
      const Text('🍅', style: TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pomodoro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(room.pomodoroEnabled ? '${room.timerDuration ~/ 60000}m · ${room.shortBreakDuration ~/ 60000}m · ${room.longBreakDuration ~/ 60000}m' : 'Tap to enable auto focus/break cycles',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ])),
      if (room.pomodoroEnabled) IconButton(icon: Icon(Icons.tune_rounded, size: 18, color: AppColors.primaryLight), onPressed: () => _showDuration(room)),
      Switch(value: room.pomodoroEnabled, onChanged: (v) => _rs.setPomodoroEnabled(widget.roomId, v), activeThumbColor: AppColors.primary),
    ]),
  );

  Widget _participantsCard(Room room) {
    final isCreator = (_ap.user?.displayName ?? '') == room.createdBy;
    return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.stroke)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('👥 ${room.participants.length} focusing',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
        const Spacer(),
        if (isCreator)
          Text('👑 Room Owner', style: TextStyle(fontSize: 9, color: AppColors.amber, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: room.participants.map((name) {
        final data   = room.participantData[name] ?? {};
        final photo  = data['photoUrl'] as String?;
        final rank   = data['rank'] as String? ?? '';
        final isMe   = name == (_ap.user?.displayName ?? '');
        final isOwner = name == room.createdBy;
        return GestureDetector(
          onLongPress: (isCreator && !isMe) ? () => _showKickDialog(name) : null,
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isMe ? AppColors.primary.withValues(alpha: 0.5) : AppColors.stroke),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            // Avatar
            Stack(children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                backgroundImage: (photo != null && photo.isNotEmpty) ? getAvatarProvider(photo) : null,
                child: (photo == null || photo.isEmpty)
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))
                    : null,
              ),
              Positioned(right: 0, bottom: 0, child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle,
                    border: Border.all(color: AppColors.card, width: 1)),
              )),
            ]),
            const SizedBox(width: 7),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (isOwner) Padding(padding: const EdgeInsets.only(right: 3), child: Text('👑', style: TextStyle(fontSize: 10))),
                Text(name, style: TextStyle(
                    color: isMe ? AppColors.primaryLight : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              if (rank.isNotEmpty)
                Text(rank, style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ]),
            // Kick button for creator (not on self, not on creator)
            if (isCreator && !isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () => _showKickDialog(name),
                  child: Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                ),
              ),
          ]),
        ));
      }).toList()),
    ]),
  );}

  void _showKickDialog(String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Remove "$userName" from this room?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              _rs.kickMember(widget.roomId, userName);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userName removed from room')));
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // ══════════════════ TASKS TAB ════════════════════════════════════════════
  Widget _tasksTab(Room room) {
    final me = _ap.user?.displayName ?? '';
    final avatars = room.participantData.map((k, v) => MapEntry(k, v['photoUrl'] as String?));
    final myTasks = _tasks.where((t) => t.createdBy == me).toList();
    final othersTasks = _tasks.where((t) => t.createdBy != me).toList();
    final inProgress = myTasks.where((t) => !t.completed).toList();
    final finished = myTasks.where((t) => t.completed).toList();

    // Calculate progress stats — completed tasks count as 100% done
    int myTotalTargetMin = 0, myTotalProgressMin = 0;
    for (final t in myTasks) {
      myTotalTargetMin += t.targetTimeSec ~/ 60;
      if (t.completed) {
        myTotalProgressMin += t.targetTimeSec ~/ 60;
      } else {
        myTotalProgressMin += (t.elapsedTimeSec + ((_taskExtraMs[t.id] ?? 0) ~/ 1000)) ~/ 60;
      }
    }

    return DefaultTabController(
      length: 2,
      child: Column(children: [
        // Header with Add button and progress stats
        Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 0), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📋 Tasks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            if (myTasks.isNotEmpty)
              Text('${myTotalProgressMin}m done / ${myTotalTargetMin}m planned',
                  style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w500)),
          ])),
          ElevatedButton.icon(onPressed: _showAddTask, icon: const Icon(Icons.add, size: 16), label: const Text('Add'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
        ])),
        const SizedBox(height: 6),
        // Sub-tabs: My Tasks / All Tasks
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
          child: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: '🎯 My Tasks (${myTasks.length})'),
              Tab(text: '👥 All Tasks (${_tasks.length})'),
            ],
          ),
        ),
        Expanded(child: TabBarView(children: [
          // ── My Tasks tab ──
          _tasks.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('📝', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text('No tasks yet', style: TextStyle(color: AppColors.textMuted)),
              ]))
            : ListView(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), children: [
                if (inProgress.isNotEmpty) ...[
                  _taskSectionHeader('🔄 In Progress', inProgress.length),
                  ...inProgress.map((t) => _buildTaskTile(t, room, avatars, isOwner: true)),
                ],
                if (finished.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _taskSectionHeader('✅ Finished', finished.length),
                  ...finished.map((t) => _buildTaskTile(t, room, avatars, isOwner: true)),
                ],
                if (myTasks.isEmpty)
                  Padding(padding: const EdgeInsets.only(top: 40), child: Center(
                    child: Text('Add your first task!', style: TextStyle(color: AppColors.textMuted)))),
              ]),
          // ── All Tasks tab (view-only for others' tasks) ──
          ListView(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), children: [
            // My tasks first
            if (myTasks.isNotEmpty) ...[
              _taskSectionHeader('🎯 My Tasks', myTasks.length, myTotalProgressMin, myTotalTargetMin),
              ...inProgress.map((t) => _buildTaskTile(t, room, avatars, isOwner: true)),
              ...finished.map((t) => _buildTaskTile(t, room, avatars, isOwner: true)),
            ],
            // Others' tasks (view-only)
            ...othersTasks.fold<Map<String, List<Task>>>({}, (map, t) {
              map[t.createdBy] = (map[t.createdBy] ?? [])..add(t);
              return map;
            }).entries.map((e) {
              final userName = e.key;
              final userTasks = e.value;
              int userTotalTargetMin = 0, userTotalProgressMin = 0;
              for (final t in userTasks) {
                userTotalTargetMin += t.targetTimeSec ~/ 60;
                if (t.completed) {
                  userTotalProgressMin += t.targetTimeSec ~/ 60;
                } else {
                  userTotalProgressMin += (t.elapsedTimeSec + ((_taskExtraMs[t.id] ?? 0) ~/ 1000)) ~/ 60;
                }
              }
              final userInProgress = userTasks.where((t) => !t.completed);
              final userFinished = userTasks.where((t) => t.completed);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _taskSectionHeader('👤 $userName\'s Tasks', userTasks.length, userTotalProgressMin, userTotalTargetMin),
                  ...userInProgress.map((t) => _buildTaskTile(t, room, avatars, isOwner: false)),
                  ...userFinished.map((t) => _buildTaskTile(t, room, avatars, isOwner: false)),
                ],
              );
            }),
            if (_tasks.isEmpty)
              Padding(padding: const EdgeInsets.only(top: 40), child: Center(
                child: Text('No tasks in this room yet', style: TextStyle(color: AppColors.textMuted)))),
          ]),
        ])),
      ]),
    );
  }

  Widget _taskSectionHeader(String title, int count, [int? progMin, int? targetMin]) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Row(children: [
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
        child: Text('$count', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ),
      if (progMin != null && targetMin != null) ...[
        const Spacer(),
        Text('${progMin}m / ${targetMin}m', style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w500)),
      ],
    ]),
  );

  Widget _buildTaskTile(Task t, Room room, Map<String, String?> avatars, {required bool isOwner}) {
    final sel = room.isTaskSelected(t.id);
    return _TaskTile(
      task: t, isSelected: sel, liveExtra: (_taskExtraMs[t.id] ?? 0) ~/ 1000,
      creatorAvatar: avatars[t.createdBy],
      onSelect: isOwner ? () => _rs.toggleTaskSelected(widget.roomId, t.id, !sel) : () {},
      onComplete: isOwner ? (v) => _rs.toggleTaskComplete(widget.roomId, t.id, v) : (_) {},
      onDelete: isOwner ? () => _rs.deleteTask(widget.roomId, t.id) : () {},
      onEdit: isOwner ? () => _showEditTask(t) : null,
      isReadOnly: !isOwner,
    );
  }

  // ══════════════════ CHAT TAB ═════════════════════════════════════════════
  Widget _chatTab() {
    final me     = _ap.user?.displayName ?? 'User';
    final myPhoto = _ap.user?.photoUrl;
    
    final avatars = _room?.participantData.map((k, v) => MapEntry(k, v['photoUrl'] as String?)) ?? {};
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final displayMsgs = _msgs.where((m) => !m.isSystem || m.sentAt.isAfter(today)).toList();
    
    return Column(children: [
      Expanded(child: displayMsgs.isEmpty
          ? Center(child: Text('No messages 💬', style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              controller: _chatScroll, 
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              itemCount: displayMsgs.length,
              itemBuilder: (_, i) {
                final m = displayMsgs[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: m.isSystem
                      ? _SysMsg(text: m.text)
                      : _ChatBubble(
                          msg: m, isMe: m.sender == me,
                          avatars: avatars,
                          showSeen: true,
                          onReact: (emoji) => _rs.toggleReaction(widget.roomId, m.id, emoji, me),
                          onEdit: m.sender == me ? (newText) => _rs.editMessage(widget.roomId, m.id, newText) : null,
                          onDelete: m.sender == me ? () => _rs.deleteMessage(widget.roomId, m.id) : null,
                        ),
                );
              })),
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.stroke))),
        child: Row(children: [
          Expanded(child: TextField(controller: _msgCtrl, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: null,
              decoration: const InputDecoration(hintText: 'Send a message...', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              onSubmitted: (_) => _send(me, myPhoto))),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => _send(me, myPhoto),
            child: Container(width: 42, height: 42,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
        ])),
    ]);
  }

  void _send(String me, String? photoUrl) {
    if (_msgCtrl.text.trim().isEmpty) return;
    _rs.sendMessage(widget.roomId, me, _msgCtrl.text, senderPhotoUrl: photoUrl);
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_chatScroll.hasClients) _chatScroll.animateTo(_chatScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  // ── Bottom sheets ─────────────────────────────────────────────────────────
  void _showDuration(Room room) => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => _DurationSheet(room: room, onSave: (f, s, l, mode) {
      _rs.setFocusDuration(widget.roomId, f * 60000);
      _rs.setBreakDurations(widget.roomId, s * 60000, l * 60000);
      _rs.setTimerMode(widget.roomId, mode);
      setState(() { _elapsedMs = 0; _taskExtraMs.clear(); _taskBaseElapsed.clear(); });
      Navigator.pop(context);
    }));

  // Sound is per-user: ambient plays locally only, not shared via Firestore
  void _showSound(Room room) => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => _SoundSheet(room: room,
      roomId: widget.roomId,
      onAmbient: (k) {
        _selectedAmbient = k;
        if (k == null) { _snd.stopAmbient(); } else { _snd.playAmbient(k); }
        
        // Broadcast to room if synced
        if (_room?.syncTimerSounds == true) {
          _rs.setAmbientSound(widget.roomId, k);
        }
      },
      selectedAmbient: _selectedAmbient,
      onFocusAlert: (k) { _rs.setFocusAlert(widget.roomId, k); _snd.playAlert(k); },
      onBreakAlert: (k) { _rs.setBreakAlert(widget.roomId, k); _snd.playAlert(k); },
      onSyncToggle: (v) { _rs.setSyncTimerSounds(widget.roomId, v); },
      isRunning: _room != null && !_room!.isPaused,
    ));

  void _showAddTask() => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => _AddTaskSheet(onAdd: (title, desc, min) {
      _rs.addTask(widget.roomId, title, desc, min * 60, _ap.user?.displayName ?? '');
      Navigator.pop(context);
    }));

  void _showEditTask(Task task) => showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => _EditTaskSheet(
      task: task,
      onSave: (title, desc, targetMin, elapsedSec) async {
        await _rs.updateTask(widget.roomId, task.id,
          title: title, description: desc,
          targetTimeSec: targetMin * 60, elapsedTimeSec: elapsedSec);
        // Sync local tracking so live display is correct
        _taskBaseElapsed[task.id] = elapsedSec;
        _taskExtraMs[task.id] = 0;
        if (mounted) Navigator.pop(context);
      },
    ));

  void _showHpAlert() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.transparent, elevation: 0,
      duration: const Duration(seconds: 8),
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF065F46), borderRadius: BorderRadius.circular(16)),
        child: const Row(children: [
          Text('⚡', style: TextStyle(fontSize: 24)),
          SizedBox(width: 10),
          Expanded(child: Text('Break HP depleted! Time to get back to studying 💪',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ]),
      ),
    ));
  }

  // ── HP attendance bar ───────────────────────────────────────────────────────
  Widget _hpBar(Room room) {
    final isBreak = room.pomodoroEnabled && room.currentPhase != PomodoroPhase.focus;
    final isRunning = !room.isPaused && !room.timerCompleted;
    // Show bar whenever running or HP isn't at default full (1.0)
    if (_hp >= 1.0 && !isRunning && !isBreak) return const SizedBox.shrink();
    final hpColor = _hp > 0.6
        ? const Color(0xFF34D399)
        : _hp > 0.3 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444);
    // Label: during break HP recovers (↑), during focus it drains (↓)
    final hpLabel = isBreak ? '↑ recovering' : '↓ draining';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hpColor.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('❤️ Focus HP', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${(_hp * 100).toInt()}%', style: TextStyle(fontSize: 11, color: hpColor, fontWeight: FontWeight.w700)),
          if (isRunning) ...[const SizedBox(width: 6), Text(hpLabel, style: TextStyle(fontSize: 9, color: AppColors.textMuted))],
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: _hp, end: _hp),
            duration: const Duration(milliseconds: 300),
            builder: (_, v, __) => LinearProgressIndicator(
              value: v, minHeight: 7,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(hpColor),
            ),
          ),
        ),
        if (!isBreak && _hp <= 0) ...[const SizedBox(height: 4), Text('💀 HP Depleted! Take a break soon.', style: TextStyle(fontSize: 10, color: hpColor))],
        if (isBreak && _hp >= 1.0) ...[const SizedBox(height: 4), Text('⚡ HP Fully Restored! Ready to focus.', style: TextStyle(fontSize: 10, color: hpColor))],
      ]),
    );
  }

  void _showFacePicker(BuildContext context) => showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (ctx) => Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.stroke, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        const Text('⏱ Timer Face', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Choose your timer style', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        Consumer<ThemeProvider>(builder: (_, tp, __) {
          final currentFace = tp.timerFace;
          return Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            children: TimerFace.values.map((f) {
              final sel = currentFace == f;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                onTap: () { tp.setTimerFace(f); Navigator.pop(ctx); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary.withValues(alpha: 0.18) : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.stroke, width: sel ? 2 : 1),
                    boxShadow: sel ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12)] : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // Face preview
                    _FacePreview(face: f, color: sel ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(height: 8),
                    Text(f.label, style: TextStyle(fontSize: 10, color: sel ? AppColors.primaryLight : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400), textAlign: TextAlign.center),
                    if (sel) Container(width: 20, height: 2, margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                  ]),
                ),
              ));
            }).toList(),
          ));
        }),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ────────────────────────────────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback? onTap; final bool active;
  const _CtrlBtn({required this.icon, required this.label, this.onTap, this.active = false});
  @override
  Widget build(BuildContext context) => MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: onTap, child: Column(children: [
    Container(width: 42, height: 42,
      decoration: BoxDecoration(color: active ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLight, shape: BoxShape.circle, border: Border.all(color: active ? AppColors.primary : AppColors.stroke)),
      child: Icon(icon, color: active ? AppColors.primaryLight : AppColors.textSecondary, size: 18)),
    const SizedBox(height: 3),
    Text(label, style: TextStyle(fontSize: 9, color: active ? AppColors.primaryLight : AppColors.textMuted), overflow: TextOverflow.ellipsis),
  ])));
}

class _TaskMini extends StatelessWidget {
  final Task task; final int extraSec;
  const _TaskMini({required this.task, required this.extraSec});
  @override
  Widget build(BuildContext context) {
    // Completed tasks count as 100%
    final total = task.completed ? task.targetTimeSec : task.elapsedTimeSec + extraSec;
    final prog  = task.targetTimeSec > 0 ? (total / task.targetTimeSec).clamp(0.0, 1.0) : (task.completed ? 1.0 : 0.0);
    final dispTime = task.completed ? task.formattedTarget : task.formattedLive(extraSec);
    return Container(margin: const EdgeInsets.symmetric(vertical: 3), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: task.completed ? AppColors.surfaceLight.withValues(alpha: 0.7) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10), border: Border.all(color: task.completed ? const Color(0xFF34D399).withValues(alpha: 0.4) : AppColors.stroke)),
      child: Row(children: [
        Text(task.completed ? '✅' : '🎯', style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task.title, style: TextStyle(color: task.completed ? AppColors.textMuted : Colors.white, fontSize: 11, fontWeight: FontWeight.w600, decoration: task.completed ? TextDecoration.lineThrough : null), overflow: TextOverflow.ellipsis),
          if (task.description.isNotEmpty) Text(task.description, style: TextStyle(fontSize: 9, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: prog, minHeight: 3, backgroundColor: AppColors.timerRingBg, valueColor: AlwaysStoppedAnimation(task.completed ? const Color(0xFF34D399) : AppColors.primary))),
        ])),
        const SizedBox(width: 8),
        Text(dispTime, style: TextStyle(color: task.completed ? const Color(0xFF34D399) : AppColors.primaryLight, fontSize: 10, fontFamily: 'monospace')),
      ]));
  }
}

class _TaskTile extends StatelessWidget {
  final Task task; final bool isSelected; final int liveExtra; final String? creatorAvatar;
  final VoidCallback onSelect; final ValueChanged<bool> onComplete; final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final bool isReadOnly;
  const _TaskTile({required this.task, required this.isSelected, required this.liveExtra, this.creatorAvatar, required this.onSelect, required this.onComplete, required this.onDelete, this.onEdit, this.isReadOnly = false});
  @override
  Widget build(BuildContext context) {
    // Completed tasks count as fully done
    final total = task.completed ? task.targetTimeSec : task.elapsedTimeSec + liveExtra;
    final prog  = task.targetTimeSec > 0 ? (total / task.targetTimeSec).clamp(0.0, 1.0) : (task.completed ? 1.0 : 0.0);
    return GestureDetector(onTap: isReadOnly ? null : onSelect, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isReadOnly ? AppColors.surfaceLight.withValues(alpha: 0.5) : (isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.stroke, width: isSelected ? 1.5 : 1)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Checkbox(
            value: task.completed,
            onChanged: isReadOnly ? null : (v) => onComplete(v ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(task.title, style: TextStyle(color: task.completed ? AppColors.textMuted : Colors.white, fontWeight: FontWeight.w600, decoration: task.completed ? TextDecoration.lineThrough : null, fontSize: 13), overflow: TextOverflow.ellipsis)),
            if (isSelected && !isReadOnly) Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
              child: Text('ACTIVE', style: TextStyle(fontSize: 7, color: AppColors.primaryLight, fontWeight: FontWeight.w700))),
            if (isReadOnly) Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.visibility_outlined, size: 8, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Text('VIEW', style: TextStyle(fontSize: 7, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ])),
          ]),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(task.description, style: TextStyle(fontSize: 11, color: AppColors.textMuted, decoration: task.completed ? TextDecoration.lineThrough : null), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(children: [
            CircleAvatar(
              radius: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              backgroundImage: (creatorAvatar != null && creatorAvatar!.isNotEmpty) ? getAvatarProvider(creatorAvatar!) : null,
              child: (creatorAvatar == null || creatorAvatar!.isEmpty)
                  ? Text(task.createdBy.isNotEmpty ? task.createdBy[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 5, fontWeight: FontWeight.w700, color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 4),
            Text(task.createdBy, style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(task.completed ? task.formattedTarget : task.formattedLive(liveExtra),
                style: TextStyle(fontSize: 9, color: task.completed ? const Color(0xFF34D399) : AppColors.primaryLight, fontFamily: 'monospace')),
            Text(' / ${task.formattedTarget}', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontFamily: 'monospace')),
            const SizedBox(width: 6),
            SizedBox(width: 40, child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: prog, minHeight: 3, backgroundColor: AppColors.timerRingBg, valueColor: AlwaysStoppedAnimation(task.completed ? const Color(0xFF34D399) : AppColors.primary)))),
          ]),
        ])),
        if (isReadOnly)
          Padding(padding: const EdgeInsets.only(top: 8), child: Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted))
        else
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (onEdit != null)
              IconButton(icon: Icon(Icons.edit_rounded, size: 15, color: AppColors.textMuted), onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            IconButton(icon: Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
      ])));
  }
}

// Issue 9 — system message centered bubble
class _SysMsg extends StatelessWidget {
  final String text;
  const _SysMsg({required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5),
    child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.stroke)),
      child: Text(text, style: TextStyle(color: AppColors.textMuted, fontSize: 10)))));
}

// Issue 6 — chat bubble with emoji reactions, sender avatar, seen indicator
class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final ValueChanged<String> onReact;
  final ValueChanged<String>? onEdit;
  final VoidCallback? onDelete;
  final Map<String, String?> avatars;
  final bool showSeen;
  const _ChatBubble({required this.msg, required this.isMe, required this.onReact, required this.avatars, this.showSeen = false, this.onEdit, this.onDelete});

  static const _reactEmojis = ['👍', '❤️', '😂', '🎉', '🔥'];

  @override
  Widget build(BuildContext context) {
    final photo = msg.senderPhotoUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Sender avatar (only for received messages)
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              backgroundImage: (photo != null && photo.isNotEmpty) ? getAvatarProvider(photo) : null,
              child: (photo == null || photo.isEmpty)
                  ? Text(msg.sender.isNotEmpty ? msg.sender[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
                builder: (_) => Container(padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _reactEmojis.map((e) =>
                      GestureDetector(onTap: () { onReact(e); Navigator.pop(context); },
                        child: Text(e, style: const TextStyle(fontSize: 32)))).toList()),
                    if (isMe && onEdit != null) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      ListTile(
                        leading: const Icon(Icons.edit, color: Colors.white70),
                        title: const Text('Edit message', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          _showEditDialog(context, msg.text, onEdit!);
                        },
                      ),
                    ],
                    if (isMe && onDelete != null) ...[
                      ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
                        title: Text('Delete message', style: TextStyle(color: Colors.red.shade400)),
                        onTap: () {
                          Navigator.pop(context);
                          onDelete!();
                        },
                      ),
                    ],
                  ]))),
              child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                Container(margin: const EdgeInsets.only(bottom: 2), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                  decoration: AppStyle.chatBubble(isMe: isMe),
                  child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                    if (!isMe) Text(msg.sender, style: TextStyle(fontSize: 9, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                    Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    if (msg.isEdited) Text('(edited)', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5), fontStyle: FontStyle.italic)),
                  ])),
                if (msg.reactions.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(spacing: 4, children: msg.reactions.entries.map((e) =>
                    GestureDetector(onTap: () => onReact(e.key),
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.stroke)),
                        child: Text('${e.key} ${e.value.length}', style: const TextStyle(fontSize: 11))))).toList())),
                // Seen by row (only on last message for the sender)
                if (showSeen && isMe && msg.seenBy.length > 1)
                  Padding(padding: const EdgeInsets.only(bottom: 2),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Seen ', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                      ...msg.seenBy.where((n) => n != msg.sender).take(5).map((n) {
                        final photo = avatars[n];
                        return Container(
                          margin: const EdgeInsets.only(left: 2),
                          width: 14, height: 14,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.4),
                              border: Border.all(color: AppColors.background, width: 1),
                              image: (photo != null && photo.isNotEmpty) ? DecorationImage(image: getAvatarProvider(photo), fit: BoxFit.cover) : null),
                          child: (photo == null || photo.isEmpty) ? Center(child: Text(n.isNotEmpty ? n[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white))) : null,
                        );
                      }),
                    ])),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static void _showEditDialog(BuildContext context, String currentText, ValueChanged<String> onEdit) {
    final ctrl = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Edit your message...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              final newText = ctrl.text.trim();
              Navigator.pop(ctx);
              if (newText.isNotEmpty && newText != currentText) onEdit(newText);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Duration sheet ────────────────────────────────────────────────────────────
class _DurationSheet extends StatefulWidget {
  final Room room; final Function(int,int,int,String) onSave;
  const _DurationSheet({required this.room, required this.onSave});
  @override State<_DurationSheet> createState() => _DurationSheetState();
}
class _DurationSheetState extends State<_DurationSheet> {
  late int _f, _s, _l;
  late String _mode;
  @override void initState() { super.initState(); 
    _f = widget.room.timerDuration ~/ 60000; 
    _s = widget.room.shortBreakDuration ~/ 60000; 
    _l = widget.room.longBreakDuration ~/ 60000; 
    _mode = widget.room.timerMode;
  }
  String _fmtDuration(int min) {
    if (min < 60) return '${min}m';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('⏱ Timer Durations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 16),
      
      // Mode toggle
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _mode = 'DOWN'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: _mode == 'DOWN' ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text('⏳ Countdown', style: TextStyle(color: _mode == 'DOWN' ? AppColors.primaryLight : AppColors.textSecondary, fontWeight: _mode == 'DOWN' ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
            ))),
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _mode = 'UP'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: _mode == 'UP' ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text('🏃‍♂️ Untimed', style: TextStyle(color: _mode == 'UP' ? AppColors.primaryLight : AppColors.textSecondary, fontWeight: _mode == 'UP' ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
            ))),
        ]),
      ),
      const SizedBox(height: 16),
      
      // Quick preset buttons
      if (_mode == 'DOWN') ...[
        Text('Quick Presets', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
          ...[25, 45, 60, 90, 120, 180].map((m) => GestureDetector(
            onTap: () => setState(() => _f = m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _f == m ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _f == m ? AppColors.primary : AppColors.stroke),
              ),
              child: Text(_fmtDuration(m), style: TextStyle(fontSize: 11, color: _f == m ? AppColors.primaryLight : AppColors.textSecondary, fontWeight: _f == m ? FontWeight.w700 : FontWeight.w400)),
            ),
          )),
        ]),
        const SizedBox(height: 14),
      ],
      if (_mode == 'DOWN')
        Row(children: [
          Expanded(child: _Wheel(label: '🎯 Focus',       val: _f, min: 5,  max: 600, onChange: (v) => setState(() => _f = v))),
          Expanded(child: _Wheel(label: '☕ Short Break', val: _s, min: 1,  max: 60,  onChange: (v) => setState(() => _s = v))),
          Expanded(child: _Wheel(label: '🌿 Long Break',  val: _l, min: 5,  max: 120, onChange: (v) => setState(() => _l = v))),
        ])
      else
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text('Untimed mode will count up infinitely until you pause or stop the timer. Great for open-ended study sessions!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => widget.onSave(_f,_s,_l,_mode), child: Text(_mode == 'DOWN' ? 'Set: ${_fmtDuration(_f)} · ${_fmtDuration(_s)} · ${_fmtDuration(_l)}' : 'Set Untimed Mode'))),
      const SizedBox(height: 8),
    ]));
}

class _Wheel extends StatefulWidget {
  final String label; final int val, min, max; final ValueChanged<int> onChange;
  const _Wheel({required this.label, required this.val, required this.min, required this.max, required this.onChange});
  @override State<_Wheel> createState() => _WheelState();
}
class _WheelState extends State<_Wheel> {
  late FixedExtentScrollController _ctrl;
  late int _sel;
  @override void initState() { super.initState(); _sel = widget.val; _ctrl = FixedExtentScrollController(initialItem: widget.val - widget.min); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(widget.label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
    const SizedBox(height: 6),
    SizedBox(height: 130, child: Stack(alignment: Alignment.center, children: [
      Container(height: 40, margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)))),
      ListWheelScrollView.useDelegate(
        controller: _ctrl, itemExtent: 40, perspective: 0.004, diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) { setState(() => _sel = i + widget.min); widget.onChange(_sel); HapticFeedback.selectionClick(); },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.max - widget.min + 1,
          builder: (ctx, i) { final m = i + widget.min; final s = m == _sel;
            return Center(child: Text('$m min', style: TextStyle(fontSize: s?18:13, fontWeight: s?FontWeight.w700:FontWeight.w400, color: s?Colors.white:AppColors.textMuted)));
          })),
    ])),
  ]);
}

// ── Sound sheet (Tabs, Qur'an, and Ambient) ───────────────────────────────────
class _SoundSheet extends StatefulWidget {
  final Room room; final bool isRunning;
  final ValueChanged<String?> onAmbient;
  final ValueChanged<String> onFocusAlert, onBreakAlert;
  final ValueChanged<bool> onSyncToggle;
  final String? selectedAmbient;
  final String roomId;
  const _SoundSheet({required this.room, required this.isRunning, required this.onAmbient, required this.onFocusAlert, required this.onBreakAlert, required this.onSyncToggle, this.selectedAmbient, required this.roomId});
  @override State<_SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<_SoundSheet> {
  late String? _amb; late String _fA, _bA;
  late bool _syncSounds;
  final _snd = SoundService();
  
  @override
  void initState() { 
    super.initState(); 
    _amb = widget.selectedAmbient ?? widget.room.selectedAmbient; 
    _fA = widget.room.focusAlertSound ?? 'airhorn'; 
    _bA = widget.room.breakAlertSound ?? 'bell'; 
    _syncSounds = widget.room.syncTimerSounds;
  }

  void _previewAmbient(String? key) {
    if (key == null) { _snd.stopAmbient(); return; }
    _snd.playAmbient(key);
  }

  @override
  void dispose() {
    if (!widget.isRunning) {
      _snd.stopAmbient(); // stop preview on close if timer not running
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.of(context).size.height * 0.85,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyle.sheetRadius))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('🎵 Sounds', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white))),
        Text('Tap to select', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
        IconButton(icon: Icon(Icons.close, color: AppColors.textMuted), onPressed: () => Navigator.pop(context)),
      ]),
      const SizedBox(height: 12),
      Expanded(
        child: _buildStandardSounds(),
      ),
    ]),
  );

  Widget _buildStandardSounds() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Sound Sync Toggle ──
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: AppStyle.cardDecoration(),
          child: Row(children: [
            Icon(
              _syncSounds ? Icons.sync_rounded : Icons.sync_disabled_rounded,
              color: _syncSounds ? AppColors.primaryLight : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Sync Timer Sounds',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                _syncSounds
                  ? 'Alert sounds play for everyone in this room'
                  : 'Each user hears their own alert sounds',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ])),
            Switch(
              value: _syncSounds,
              onChanged: (v) {
                setState(() => _syncSounds = v);
                widget.onSyncToggle(v);
              },
            ),
          ]),
        ),
        Text('🌊 Ambient (while focusing)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _SC(emoji: '🔇', label: 'Off', selected: _amb == null, onTap: () { setState(() => _amb = null); widget.onAmbient(null); _previewAmbient(null); }),
          ...SoundService.ambientSounds.entries.map((e) => _SC(emoji: e.value['emoji']!, label: e.value['label']!, selected: _amb == e.key,
            onTap: () { setState(() => _amb = e.key); widget.onAmbient(e.key); _previewAmbient(e.key); })),
        ]),
        const SizedBox(height: 18),
        Text('🏁 When Focus Ends', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: SoundService.alertSounds.entries.map((e) => _SC(emoji: e.value['emoji']!, label: e.value['label']!, selected: _fA == e.key, onTap: () { setState(() => _fA = e.key); widget.onFocusAlert(e.key); })).toList()),
        const SizedBox(height: 18),
        Text('🎯 When Break Ends', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: SoundService.alertSounds.entries.map((e) => _SC(emoji: e.value['emoji']!, label: e.value['label']!, selected: _bA == e.key, onTap: () { setState(() => _bA = e.key); widget.onBreakAlert(e.key); })).toList()),
      ])
    );
  }
}


class _SC extends StatelessWidget {
  final String emoji, label; final bool selected; final VoidCallback onTap;
  const _SC({required this.emoji, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? AppColors.primary : AppColors.stroke, width: selected ? 1.5 : 1)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: selected ? AppColors.primaryLight : AppColors.textSecondary, fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
    ])));
}

// ── Add task sheet ────────────────────────────────────────────────────────────
class _AddTaskSheet extends StatefulWidget {
  final Function(String, String, int) onAdd;
  const _AddTaskSheet({required this.onAdd});
  @override State<_AddTaskSheet> createState() => _AddTaskSheetState();
}
class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _t = TextEditingController(); final _d = TextEditingController();
  int _min = 25;
  bool _showWheel = false;
  @override void dispose() { _t.dispose(); _d.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📝 Add Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 14),
        TextField(controller: _t, style: const TextStyle(color: Colors.white), autofocus: true, decoration: const InputDecoration(labelText: 'Task Title')),
        const SizedBox(height: 10),
        TextField(controller: _d, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Description (optional)')),
        const SizedBox(height: 24),
        Text('Focus duration', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ...[15, 25, 30, 45, 50, 60, 90].map((m) => ChoiceChip(
            label: Text('${m}m'), selected: !_showWheel && _min == m, selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: (!_showWheel && _min == m) ? Colors.white : AppColors.textSecondary),
            backgroundColor: AppColors.surfaceLight, onSelected: (_) => setState(() { _min = m; _showWheel = false; }))),
          ChoiceChip(
            label: const Text('Custom...'), selected: _showWheel, selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: _showWheel ? Colors.white : AppColors.textSecondary),
            backgroundColor: AppColors.surfaceLight, onSelected: (_) => setState(() => _showWheel = true)),
        ]),
        if (_showWheel) ...[
          const SizedBox(height: 24),
          _Wheel(
            label: 'Custom Duration (max 5 hours)',
            val: _min,
            min: 5,
            max: 300,
            onChange: (v) => setState(() => _min = v),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { if (_t.text.trim().isEmpty) return; widget.onAdd(_t.text.trim(), _d.text.trim(), _min); }, child: const Text('Add Task'))),
        const SizedBox(height: 8),
      ])));
}

// ── Edit task sheet ───────────────────────────────────────────────────────────
class _EditTaskSheet extends StatefulWidget {
  final Task task;
  final Future<void> Function(String, String, int, int) onSave; // title, desc, targetMin, elapsedSec
  const _EditTaskSheet({required this.task, required this.onSave});
  @override State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  late TextEditingController _t, _d;
  late int _targetMin, _elapsedMin;
  bool _showTargetWheel = false;
  bool _showElapsedWheel = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _t = TextEditingController(text: widget.task.title);
    _d = TextEditingController(text: widget.task.description);
    _targetMin = (widget.task.targetTimeSec ~/ 60).clamp(5, 300);
    _elapsedMin = (widget.task.elapsedTimeSec ~/ 60).clamp(0, _targetMin);
  }

  @override
  void dispose() { _t.dispose(); _d.dispose(); super.dispose(); }

  String _fmt(int min) {
    if (min < 60) return '${min}m';
    final h = min ~/ 60; final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✏️ Edit Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 14),
        TextField(controller: _t, style: const TextStyle(color: Colors.white), autofocus: true,
          decoration: const InputDecoration(labelText: 'Task Title')),
        const SizedBox(height: 10),
        TextField(controller: _d, style: const TextStyle(color: Colors.white), maxLines: 2,
          decoration: const InputDecoration(labelText: 'Description (optional)')),
        const SizedBox(height: 18),
        // Target & elapsed row
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🎯 Target Time', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() { _showTargetWheel = !_showTargetWheel; _showElapsedWheel = false; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _showTargetWheel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _showTargetWheel ? AppColors.primary : AppColors.stroke),
                ),
                child: Row(children: [
                  Text(_fmt(_targetMin), style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  Icon(Icons.tune_rounded, size: 14, color: AppColors.textMuted),
                ]),
              ),
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('⏱ Elapsed ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() { _showElapsedWheel = !_showElapsedWheel; _showTargetWheel = false; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _showElapsedWheel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _showElapsedWheel ? AppColors.primary : AppColors.stroke),
                ),
                child: Row(children: [
                  Text(_fmt(_elapsedMin), style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  Icon(Icons.tune_rounded, size: 14, color: AppColors.textMuted),
                ]),
              ),
            ),
          ])),
        ]),
        if (_showTargetWheel) ...[
          const SizedBox(height: 14),
          _Wheel(label: 'Target (minutes)', val: _targetMin, min: 5, max: 300,
            onChange: (v) => setState(() { _targetMin = v; if (_elapsedMin > _targetMin) _elapsedMin = _targetMin; })),
        ],
        if (_showElapsedWheel) ...[
          const SizedBox(height: 14),
          _Wheel(label: 'Elapsed (minutes)', val: _elapsedMin.clamp(0, _targetMin), min: 0, max: _targetMin,
            onChange: (v) => setState(() => _elapsedMin = v)),
        ],
        const SizedBox(height: 22),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _saving ? null : () async {
            if (_t.text.trim().isEmpty) return;
            setState(() => _saving = true);
            await widget.onSave(_t.text.trim(), _d.text.trim(), _targetMin, _elapsedMin * 60);
          },
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Changes'),
        )),
        const SizedBox(height: 8),
      ])),
    ),
  );
}

// ── _FacePreview — tiny thumbnail of each timer face style ───────────────────
class _FacePreview extends StatelessWidget {
  final TimerFace face;
  final Color color;
  const _FacePreview({required this.face, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56, height: 56,
      child: CustomPaint(
        painter: _FacePreviewPainter(face: face, color: color),
      ),
    );
  }
}

class _FacePreviewPainter extends CustomPainter {
  final TimerFace face;
  final Color color;
  const _FacePreviewPainter({required this.face, required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 3;
    const prog = 0.65; // 65% filled for preview

    switch (face) {
      case TimerFace.ring:
        // Background ring
        canvas.drawCircle(c, r, Paint()..color = AppColors.timerRingBg ..style = PaintingStyle.stroke ..strokeWidth = 7);
        // Progress arc
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * prog, false,
            Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = 7 ..strokeCap = StrokeCap.round);
        // Center dot
        canvas.drawCircle(c, 4, Paint()..color = color.withValues(alpha: 0.8));
        break;

      case TimerFace.arcs:
        const n = 20; const gap = 0.08;
        final filled = (prog * n).round();
        for (int i = 0; i < n; i++) {
          final a = -pi / 2 + i * (2 * pi / n);
          canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, 2 * pi / n - gap, false,
              Paint()..style = PaintingStyle.stroke ..strokeWidth = i < filled ? 5.5 : 3.5
                     ..strokeCap = StrokeCap.round ..color = i < filled ? color : AppColors.timerRingBg);
        }
        break;

      case TimerFace.dots:
        const n = 16;
        final filled = (prog * n).round();
        for (int i = 0; i < n; i++) {
          final a = -pi / 2 + i * (2 * pi / n);
          final p = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
          canvas.drawCircle(p, i < filled ? 4 : 2.2,
              Paint()..color = i < filled ? color : AppColors.timerRingBg);
        }
        break;

      case TimerFace.minimal:
        canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.12) ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * prog, false,
            Paint()..color = color.withValues(alpha: 0.7) ..style = PaintingStyle.stroke ..strokeWidth = 1.8 ..strokeCap = StrokeCap.round);
        canvas.drawCircle(c, r * 0.55, Paint()..color = color.withValues(alpha: 0.1));
        // Short time text
        _drawText(canvas, '25:00', c, color, 8);
        break;

      case TimerFace.neon:
        // outer glow
        canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.05)
            ..style = PaintingStyle.stroke ..strokeWidth = 10
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        // outer ring
        canvas.drawCircle(c, r + 1, Paint()..color = color.withValues(alpha: 0.15) ..style = PaintingStyle.stroke ..strokeWidth = 1);
        // progress
        canvas.drawArc(Rect.fromCircle(center: c, radius: r - 5), -pi / 2, 2 * pi * prog, false,
            Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = 5 ..strokeCap = StrokeCap.round
                   ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawArc(Rect.fromCircle(center: c, radius: r - 5), -pi / 2, 2 * pi * prog, false,
            Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = 4 ..strokeCap = StrokeCap.round);
        break;

      case TimerFace.analog:
        // Dial face
        canvas.drawCircle(c, r, Paint()..color = AppColors.surface);
        canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.25) ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
        // Tick marks
        for (int i = 0; i < 12; i++) {
          final a = -pi / 2 + i * (2 * pi / 12);
          final inner = r - 8; final outer = r - 2;
          canvas.drawLine(Offset(c.dx + inner * cos(a), c.dy + inner * sin(a)),
              Offset(c.dx + outer * cos(a), c.dy + outer * sin(a)),
              Paint()..color = color.withValues(alpha: 0.6) ..strokeWidth = 1.5);
        }
        // Minute hand (pointing at ~9 o'clock = 75% around)
        final minA = -pi / 2 + 2 * pi * 0.75;
        canvas.drawLine(c, Offset(c.dx + (r * 0.65) * cos(minA), c.dy + (r * 0.65) * sin(minA)),
            Paint()..color = color ..strokeWidth = 2.5 ..strokeCap = StrokeCap.round);
        // Second hand
        final secA = -pi / 2 + 2 * pi * 0.33;
        canvas.drawLine(c, Offset(c.dx + (r * 0.72) * cos(secA), c.dy + (r * 0.72) * sin(secA)),
            Paint()..color = AppColors.green ..strokeWidth = 1.2 ..strokeCap = StrokeCap.round);
        canvas.drawCircle(c, 3.5, Paint()..color = color);
        canvas.drawCircle(c, 1.5, Paint()..color = Colors.white);
        break;

      case TimerFace.digital:
        // LCD background
        final rr = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: s.width - 2, height: s.height - 8), const Radius.circular(6));
        canvas.drawRRect(rr, Paint()..color = Color(0xFF0A0A14));
        canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: 0.25) ..style = PaintingStyle.stroke ..strokeWidth = 1.2);
        // Digit text
        _drawText(canvas, '25:00', c - const Offset(0, 4), color, 12, bold: true);
        // Mini progress bar
        final barY = c.dy + 14;
        final barL = s.width - 18;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - barL / 2, barY, barL, 3), const Radius.circular(2)),
            Paint()..color = AppColors.timerRingBg);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - barL / 2, barY, barL * prog, 3), const Radius.circular(2)),
            Paint()..color = color);
        break;

      case TimerFace.glowNeo:
        // Triple rings with outer glow
        canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.08)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
        canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.12) ..style = PaintingStyle.stroke ..strokeWidth = 1);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r - 5), -pi / 2, 2 * pi * prog, false,
            Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = 5 ..strokeCap = StrokeCap.round);
        canvas.drawCircle(c, r * 0.5, Paint()..color = color.withValues(alpha: 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawArc(Rect.fromCircle(center: c, radius: r - 10), -pi / 2, 2 * pi * (1 - prog), false,
            Paint()..color = color.withValues(alpha: 0.3) ..style = PaintingStyle.stroke ..strokeWidth = 2);
        _drawText(canvas, '25:00', c, color, 8);
        break;

      case TimerFace.celestial:
        canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.05) ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(c, r * 0.8, Paint()..color = color.withValues(alpha: 0.3) ..style = PaintingStyle.stroke ..strokeWidth = 1);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.8), -pi / 2, 2 * pi * prog, false,
            Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = 2 ..strokeCap = StrokeCap.round);
        for (int i=0; i < 8; i++) {
            final a = i * pi / 4;
            canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, pi/8, false, Paint()..color = color.withValues(alpha: 0.4) ..style = PaintingStyle.stroke ..strokeWidth = 1);
        }
        _drawText(canvas, '25:00', c, color, 7);
        break;

      case TimerFace.ambientFlow:
        canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.15) ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), pi - pi * prog, 2 * pi * prog, false, Paint()..color = color.withValues(alpha: 0.4));
        _drawText(canvas, '25:00', c, color, 9, bold: true);
        break;
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color, double size, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: size,
          fontFamily: 'monospace', fontWeight: bold ? FontWeight.w900 : FontWeight.w400)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_FacePreviewPainter o) => o.face != face || o.color != color;
}

