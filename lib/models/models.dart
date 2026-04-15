import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 15-rank system — cosmic journey from earth to legend
// Lowest first, highest last
// ─────────────────────────────────────────────────────────────────────────────
class RankSystem {
  static const List<Map<String, dynamic>> ranks = [
    {'emoji': '🌱', 'title': 'Seedling',      'minXp': 0,       'zone': 'Earth',   'zoneColor': 0xFF4ADE80, 'sub': 'Just getting started'},
    {'emoji': '🌿', 'title': 'Sprout',         'minXp': 100,     'zone': 'Earth',   'zoneColor': 0xFF22C55E, 'sub': 'Building momentum'},
    {'emoji': '🍃', 'title': 'Budding',        'minXp': 280,     'zone': 'Earth',   'zoneColor': 0xFF16A34A, 'sub': 'Growing steadily'},
    {'emoji': '☁️', 'title': 'Drifter',        'minXp': 600,     'zone': 'Sky',     'zoneColor': 0xFF60A5FA, 'sub': 'Rising through clouds'},
    {'emoji': '⭐', 'title': 'Apprentice',     'minXp': 1200,    'zone': 'Sky',     'zoneColor': 0xFFFBBF24, 'sub': 'Finding your rhythm'},
    {'emoji': '🔦', 'title': 'Explorer',       'minXp': 2200,    'zone': 'Sky',     'zoneColor': 0xFFF59E0B, 'sub': 'Exploring focus'},
    {'emoji': '🔥', 'title': 'Focused',        'minXp': 3800,    'zone': 'Stratosphere', 'zoneColor': 0xFFEF4444, 'sub': 'Fire burns within'},
    {'emoji': '💡', 'title': 'Thinker',        'minXp': 6200,    'zone': 'Stratosphere', 'zoneColor': 0xFF3B82F6, 'sub': 'Ideas flow freely'},
    {'emoji': '⚡', 'title': 'Surge',          'minXp': 10000,   'zone': 'Stratosphere', 'zoneColor': 0xFF6366F1, 'sub': 'Electric productivity'},
    {'emoji': '🪐', 'title': 'Orbital',        'minXp': 16000,   'zone': 'Space',   'zoneColor': 0xFF8B5CF6, 'sub': 'Beyond atmosphere'},
    {'emoji': '🌊', 'title': 'Flow State',     'minXp': 25000,   'zone': 'Space',   'zoneColor': 0xFF06B6D4, 'sub': 'In the infinite zone'},
    {'emoji': '💎', 'title': 'Crystal Mind',   'minXp': 40000,   'zone': 'Space',   'zoneColor': 0xFF7C3AED, 'sub': 'Diamond clarity'},
    {'emoji': '🚀', 'title': 'Achiever',       'minXp': 65000,   'zone': 'Stars',   'zoneColor': 0xFFDB2777, 'sub': 'Shooting for the stars'},
    {'emoji': '🏆', 'title': 'Grand Master',   'minXp': 100000,  'zone': 'Stars',   'zoneColor': 0xFFF97316, 'sub': 'Among the immortals'},
    {'emoji': '👑', 'title': 'Legend',         'minXp': 150000,  'zone': 'Stars',   'zoneColor': 0xFFFFD700, 'sub': 'Eternal glory'},
    {'emoji': '🌌', 'title': 'Galaxy Mind',    'minXp': 225000,  'zone': 'Cosmos',  'zoneColor': 0xFFD946EF, 'sub': 'Brain the size of a galaxy'},
    {'emoji': '🌀', 'title': 'Black Hole',     'minXp': 320000,  'zone': 'Cosmos',  'zoneColor': 0xFF4C1D95, 'sub': 'Absorbing all knowledge'},
    {'emoji': '🔮', 'title': 'Oracle',         'minXp': 450000,  'zone': 'Cosmos',  'zoneColor': 0xFF86198F, 'sub': 'Seeing through time'},
    {'emoji': '👁️', 'title': 'Omniscient',   'minXp': 650000,  'zone': 'Multiverse','zoneColor': 0xFF9D174D, 'sub': 'Knowing all things'},
    {'emoji': '♾️', 'title': 'Infinity',      'minXp': 1000000, 'zone': 'Multiverse','zoneColor': 0xFFF3F4F6, 'sub': 'Beyond comprehension'},
  ];

  static Map<String, dynamic> forXp(int xp) {
    Map<String, dynamic> current = ranks.first;
    for (final r in ranks) {
      if (xp >= (r['minXp'] as int)) current = r;
    }
    return current;
  }

  static String rankLabel(int xp) {
    final r = forXp(xp);
    return '${r['emoji']} ${r['title']}';
  }

  static int? nextRankXp(int xp) {
    for (final r in ranks) {
      if ((r['minXp'] as int) > xp) return r['minXp'] as int;
    }
    return null;
  }

  static double progressToNext(int xp) {
    final current = forXp(xp);
    final currentMin = current['minXp'] as int;
    final nextXp = nextRankXp(xp);
    if (nextXp == null) return 1.0;
    return ((xp - currentMin) / (nextXp - currentMin)).clamp(0.0, 1.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppUser
// ─────────────────────────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String displayName;
  final String? email;
  final bool isPremium;
  final int focusTimeSec;
  final int sessionsCompleted;
  final int xp;
  final int axp;
  final int pxp;
  final int hp;
  final int streak;
  final DateTime? lastSeen;
  final bool isGuest;
  final int dailyTargetMin;
  final int todayFocusSec;
  final List<String> verifiedNodes;
  final List<String> pendingNodes;
  final Map<String, int> history;

  AppUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.isPremium = false,
    this.focusTimeSec = 0,
    this.sessionsCompleted = 0,
    this.xp = 0,
    this.axp = 0,
    this.pxp = 0,
    this.hp = 100,
    this.streak = 0,
    this.lastSeen,
    this.isGuest = false,
    this.dailyTargetMin = 60,
    this.todayFocusSec = 0,
    this.verifiedNodes = const [],
    this.pendingNodes = const [],
    this.photoUrl,
    this.history = const {},
  });

  final String? photoUrl;

  String get rank => RankSystem.rankLabel(xp);

  String get formattedFocusTime {
    final h = focusTimeSec ~/ 3600;
    final m = (focusTimeSec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get formattedTodayFocus {
    final m = todayFocusSec ~/ 60;
    final s = todayFocusSec % 60;
    if (m >= 60) return '${m ~/ 60}h ${m % 60}m';
    return '${m}m ${s}s';
  }

  double get dailyTargetProgress =>
      dailyTargetMin > 0 ? (todayFocusSec / (dailyTargetMin * 60)).clamp(0.0, 1.0) : 0.0;

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? 'User',
      email: data['email'],
      isPremium: data['isPremium'] ?? false,
      focusTimeSec: (data['focusTimeSec'] ?? 0).toInt(),
      sessionsCompleted: (data['sessionsCompleted'] ?? 0).toInt(),
      xp: (data['xp'] ?? 0).toInt(),
      axp: (data['axp'] ?? 0).toInt(),
      pxp: (data['pxp'] ?? 0).toInt(),
      hp: (data['hp'] ?? 100).toInt(),
      streak: (data['streak'] ?? 0).toInt(),
      lastSeen: data['lastSeen'] != null ? (data['lastSeen'] as Timestamp).toDate() : null,
      isGuest: data['isGuest'] ?? false,
      dailyTargetMin: (data['dailyTargetMin'] ?? 60).toInt(),
      todayFocusSec: (data['todayFocusSec'] ?? 0).toInt(),
      verifiedNodes: List<String>.from(data['verifiedNodes'] ?? []),
      pendingNodes: List<String>.from(data['pendingNodes'] ?? []),
      photoUrl: data['photoUrl'] as String?,
      history: (data['history'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ?? {},
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'isPremium': isPremium,
        'focusTimeSec': focusTimeSec,
        'sessionsCompleted': sessionsCompleted,
        'xp': xp,
        'axp': axp,
        'pxp': pxp,
        'hp': hp,
        'streak': streak,
        'lastSeen': FieldValue.serverTimestamp(),
        'isGuest': isGuest,
        'dailyTargetMin': dailyTargetMin,
        'todayFocusSec': todayFocusSec,
        'verifiedNodes': verifiedNodes,
        'pendingNodes': pendingNodes,
        'history': history,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    bool? isPremium,
    int? focusTimeSec,
    int? sessionsCompleted,
    int? xp,
    int? axp,
    int? pxp,
    int? hp,
    int? streak,
    DateTime? lastSeen,
    bool? isGuest,
    int? dailyTargetMin,
    int? todayFocusSec,
    List<String>? verifiedNodes,
    List<String>? pendingNodes,
    String? photoUrl,
    Map<String, int>? history,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      focusTimeSec: focusTimeSec ?? this.focusTimeSec,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      xp: xp ?? this.xp,
      axp: axp ?? this.axp,
      pxp: pxp ?? this.pxp,
      hp: hp ?? this.hp,
      streak: streak ?? this.streak,
      lastSeen: lastSeen ?? this.lastSeen,
      isGuest: isGuest ?? this.isGuest,
      dailyTargetMin: dailyTargetMin ?? this.dailyTargetMin,
      todayFocusSec: todayFocusSec ?? this.todayFocusSec,
      verifiedNodes: verifiedNodes ?? this.verifiedNodes,
      pendingNodes: pendingNodes ?? this.pendingNodes,
      photoUrl: photoUrl ?? this.photoUrl,
      history: history ?? this.history,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pomodoro
// ─────────────────────────────────────────────────────────────────────────────
enum PomodoroPhase { focus, shortBreak, longBreak }

extension PomodoroPhaseExt on PomodoroPhase {
  String get name {
    switch (this) {
      case PomodoroPhase.focus:      return 'focus';
      case PomodoroPhase.shortBreak: return 'shortBreak';
      case PomodoroPhase.longBreak:  return 'longBreak';
    }
  }
  static PomodoroPhase fromString(String s) {
    switch (s) {
      case 'shortBreak': return PomodoroPhase.shortBreak;
      case 'longBreak':  return PomodoroPhase.longBreak;
      default:           return PomodoroPhase.focus;
    }
  }
  String get emoji {
    switch (this) {
      case PomodoroPhase.focus:      return '🎯';
      case PomodoroPhase.shortBreak: return '☕';
      case PomodoroPhase.longBreak:  return '🌿';
    }
  }
  String get label {
    switch (this) {
      case PomodoroPhase.focus:      return 'Focus';
      case PomodoroPhase.shortBreak: return 'Short Break';
      case PomodoroPhase.longBreak:  return 'Long Break';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room
// ─────────────────────────────────────────────────────────────────────────────
class Room {
  final String id;
  final String createdBy;
  final String timerMode;
  final int timerDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final bool pomodoroEnabled;
  final int pomodoroRound;
  final PomodoroPhase currentPhase;
  final bool isPaused;
  final int? timerStartTime;
  final int? pausedElapsedMs; 
  final bool timerCompleted;
  final String? selectedAmbient;
  final String? focusAlertSound;
  final String? breakAlertSound;
  final bool syncTimerSounds; // Support room-wise sound sync setting
  final List<String> selectedTaskIds;
  final List<String> participants;
  /// participantData: displayName → {rank, photoUrl}
  final Map<String, Map<String, dynamic>> participantData;

  Room({
    required this.id,
    required this.createdBy,
    this.timerMode = 'DOWN',
    this.timerDuration = 25 * 60 * 1000,
    this.shortBreakDuration = 5 * 60 * 1000,
    this.longBreakDuration = 15 * 60 * 1000,
    this.pomodoroEnabled = false,
    this.pomodoroRound = 0,
    this.currentPhase = PomodoroPhase.focus,
    this.isPaused = true,
    this.timerStartTime,
    this.pausedElapsedMs = 0,
    this.timerCompleted = false,
    this.selectedAmbient,
    this.focusAlertSound,
    this.breakAlertSound,
    this.syncTimerSounds = true,
    this.selectedTaskIds = const [],
    this.participants = const [],
    this.participantData = const {},
  });

  int get currentDurationMs {
    switch (currentPhase) {
      case PomodoroPhase.focus:      return timerDuration;
      case PomodoroPhase.shortBreak: return shortBreakDuration;
      case PomodoroPhase.longBreak:  return longBreakDuration;
    }
  }

  bool isTaskSelected(String id) => selectedTaskIds.contains(id);

  /// Returns only participants whose heartbeat is fresh (< 3 min old).
  /// Stale entries are users whose app was force-killed without triggering detached.
  List<String> get activeParticipants {
    final now = DateTime.now().millisecondsSinceEpoch;
    const staleMs = 3 * 60 * 1000; // 3 minutes
    return participants.where((name) {
      final data = participantData[name];
      if (data == null) return true; // no heartbeat data yet — assume active
      final lastSeenTs = data['lastSeen'];
      if (lastSeenTs == null) return true; // no heartbeat yet — assume active
      // lastSeen is stored as int (epoch ms)
      if (lastSeenTs is int) return (now - lastSeenTs) < staleMs;
      // Firestore Timestamp
      try {
        final ts = lastSeenTs as dynamic;
        final tsMs = (ts.millisecondsSinceEpoch as int);
        return (now - tsMs) < staleMs;
      } catch (_) {
        return true;
      }
    }).toList();
  }

  factory Room.fromFirestore(String id, Map<String, dynamic> data) {
    // Parse participantData safely — malformed entries could crash the stream
    Map<String, Map<String, dynamic>> safeParticipantData = {};
    try {
      final raw = data['participantData'] as Map<String, dynamic>? ?? {};
      safeParticipantData = raw.map(
        (k, v) => MapEntry(k, v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{}),
      );
    } catch (_) {}

    return Room(
      id: id,
      createdBy: data['createdBy'] ?? '',
      timerMode: data['timerMode'] ?? 'DOWN',
      timerDuration: _safeInt(data['timerDuration'], 25 * 60 * 1000),
      shortBreakDuration: _safeInt(data['shortBreakDuration'], 5 * 60 * 1000),
      longBreakDuration: _safeInt(data['longBreakDuration'], 15 * 60 * 1000),
      pomodoroEnabled: data['pomodoroEnabled'] ?? false,
      pomodoroRound: _safeInt(data['pomodoroRound'], 0),
      currentPhase: PomodoroPhaseExt.fromString(data['currentPhase'] ?? 'focus'),
      isPaused: data['isPaused'] ?? true,
      timerStartTime: data['timerStartTime'] != null ? _safeInt(data['timerStartTime'], 0) : null,
      pausedElapsedMs: _safeInt(data['pausedElapsedMs'], 0),
      timerCompleted: data['timerCompleted'] ?? false,
      selectedAmbient: data['selectedAmbient'],
      focusAlertSound: data['focusAlertSound'],
      breakAlertSound: data['breakAlertSound'],
      syncTimerSounds: data['syncTimerSounds'] ?? true,
      selectedTaskIds: List<String>.from(data['selectedTaskIds'] ?? []),
      participants: List<String>.from(data['participants'] ?? []),
      participantData: safeParticipantData,
    );
  }

  /// Safely convert dynamic to int with a fallback
  static int _safeInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return fallback;
  }

  Map<String, dynamic> toMap(String userName) => {
        'createdBy': createdBy,
        'timerMode': 'DOWN',
        'timerDuration': timerDuration,
        'shortBreakDuration': 5 * 60 * 1000,
        'longBreakDuration': 15 * 60 * 1000,
        'pomodoroEnabled': false,
        'pomodoroRound': 0,
        'currentPhase': 'focus',
        'isPaused': true,
        'timerStartTime': null,
        'timerCompleted': false,
        'selectedAmbient': null,
        'focusAlertSound': 'airhorn',
        'breakAlertSound': 'bell',
        'syncTimerSounds': true,
        'selectedTaskIds': [],
        'participants': [userName],
        'createdAt': FieldValue.serverTimestamp(),
      };

  Room copyWith({
    String? timerMode,
    int? timerDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    bool? pomodoroEnabled,
    int? pomodoroRound,
    PomodoroPhase? currentPhase,
    bool? isPaused,
    int? timerStartTime,
    int? pausedElapsedMs,
    bool? timerCompleted,
    String? selectedAmbient,
    String? focusAlertSound,
    String? breakAlertSound,
    bool? syncTimerSounds,
    List<String>? selectedTaskIds,
    List<String>? participants,
    Map<String, Map<String, dynamic>>? participantData,
    bool clearTimerStartTime = false,
    bool clearSelectedAmbient = false,
  }) {
    return Room(
      id: id,
      createdBy: createdBy,
      timerMode: timerMode ?? this.timerMode,
      timerDuration: timerDuration ?? this.timerDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      pomodoroEnabled: pomodoroEnabled ?? this.pomodoroEnabled,
      pomodoroRound: pomodoroRound ?? this.pomodoroRound,
      currentPhase: currentPhase ?? this.currentPhase,
      isPaused: isPaused ?? this.isPaused,
      timerStartTime: clearTimerStartTime ? null : (timerStartTime ?? this.timerStartTime),
      pausedElapsedMs: pausedElapsedMs ?? this.pausedElapsedMs,
      timerCompleted: timerCompleted ?? this.timerCompleted,
      selectedAmbient: clearSelectedAmbient ? null : (selectedAmbient ?? this.selectedAmbient),
      focusAlertSound: focusAlertSound ?? this.focusAlertSound,
      breakAlertSound: breakAlertSound ?? this.breakAlertSound,
      syncTimerSounds: syncTimerSounds ?? this.syncTimerSounds,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      participants: participants ?? this.participants,
      participantData: participantData ?? this.participantData,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task
// ─────────────────────────────────────────────────────────────────────────────
class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final int targetTimeSec;
  final int elapsedTimeSec;
  final String createdBy;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    this.targetTimeSec = 25 * 60,
    this.elapsedTimeSec = 0,
    this.createdBy = '',
  });

  String get formattedTarget {
    final m = targetTimeSec ~/ 60;
    final s = targetTimeSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String formattedLive(int extraSec) {
    final total = elapsedTimeSec + extraSec;
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      completed: data['completed'] ?? false,
      targetTimeSec: (data['targetTimeSec'] ?? 25 * 60).toInt(),
      elapsedTimeSec: (data['elapsedTimeSec'] ?? 0).toInt(),
      createdBy: data['createdBy'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat message — with emoji reactions (Issue 6)
// ─────────────────────────────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String sender;
  final String? senderPhotoUrl;
  final String text;
  final DateTime sentAt;
  final bool isSystem;
  final bool isEdited;
  final Map<String, List<String>> reactions;
  final List<String> seenBy; // list of displayNames who've read it

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.sentAt,
    this.senderPhotoUrl,
    this.isSystem = false,
    this.isEdited = false,
    this.reactions = const {},
    this.seenBy = const [],
  });

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    final raw = data['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = raw.map((emoji, users) =>
        MapEntry(emoji, List<String>.from(users as List)));
    return ChatMessage(
      id: id,
      sender: data['sender'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      text: data['text'] ?? '',
      sentAt: data['sentAt'] != null ? (data['sentAt'] as Timestamp).toDate() : DateTime.now(),
      isSystem: data['isSystem'] ?? false,
      isEdited: data['isEdited'] ?? false,
      reactions: reactions,
      seenBy: List<String>.from(data['seenBy'] ?? []),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AiResume (Proof-of-Skill Career Gateway)
// ─────────────────────────────────────────────────────────────────────────────
class AiResume {
  final String id;
  final String userId;
  final String title;
  final String summary;
  final List<String> verifiedSkills;
  final DateTime generatedAt;
  final bool isPublic;

  AiResume({
    required this.id,
    required this.userId,
    required this.title,
    required this.summary,
    this.verifiedSkills = const [],
    required this.generatedAt,
    this.isPublic = false,
  });

  factory AiResume.fromFirestore(String id, Map<String, dynamic> data) {
    return AiResume(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'AI Proof of Skill',
      summary: data['summary'] ?? '',
      verifiedSkills: List<String>.from(data['verifiedSkills'] ?? []),
      generatedAt: data['generatedAt'] != null ? (data['generatedAt'] as Timestamp).toDate() : DateTime.now(),
      isPublic: data['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'summary': summary,
        'verifiedSkills': verifiedSkills,
        'generatedAt': FieldValue.serverTimestamp(),
        'isPublic': isPublic,
      };
}
