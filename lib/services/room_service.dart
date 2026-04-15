import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const uuid = Uuid();

  // ── Offline State ──────────────────────────────────────────────────────────
  static final Room _initialOfflineRoom = Room(
    id: 'OFFLINE',
    createdBy: 'You',
    timerMode: 'DOWN',
    timerDuration: 25 * 60 * 1000,
    shortBreakDuration: 5 * 60 * 1000,
    longBreakDuration: 15 * 60 * 1000,
    pomodoroEnabled: false,
    pomodoroRound: 0,
    currentPhase: PomodoroPhase.focus,
    isPaused: true,
    timerStartTime: null,
    pausedElapsedMs: 0,
    timerCompleted: false,
    participants: ['You'],
    participantData: {'You': {'rank': 'Offline', 'photoUrl': ''}},
  );

  static Room _currentOfflineRoom = _initialOfflineRoom;
  static final _offlineRoomController = StreamController<Room?>.broadcast()..add(_currentOfflineRoom);
  
  static final List<Task> _offlineTasks = [];
  static final _offlineTasksController = StreamController<List<Task>>.broadcast()..add(_offlineTasks);
  
  static final List<ChatMessage> _offlineChats = [];
  static final _offlineChatController = StreamController<List<ChatMessage>>.broadcast()..add(_offlineChats);

  static void _updateOffline(Room Function(Room) update) {
    _currentOfflineRoom = update(_currentOfflineRoom);
    _offlineRoomController.add(_currentOfflineRoom);
  }

  static void _ensureOfflineEmits() {
    _offlineRoomController.add(_currentOfflineRoom);
    _offlineTasksController.add(_offlineTasks);
    _offlineChatController.add(_offlineChats);
  }

  DocumentReference    _roomRef(String id) => _db.collection('rooms').doc(id);
  CollectionReference  _chatRef(String id) => _roomRef(id).collection('chat');
  CollectionReference _tasksRef(String id) => _roomRef(id).collection('tasks');

  // ── Create / Join / Leave ─────────────────────────────────────────────────
  Future<String> createRoom(String userName, {int focusMinutes = 25}) async {
    final id = uuid.v4().substring(0, 6).toUpperCase();
    final room = Room(id: id, createdBy: userName, timerDuration: focusMinutes * 60 * 1000);
    await _roomRef(id).set(room.toMap(userName));
    await _sendSystem(id, '$userName started a room 🚀');
    return id;
  }

  Future<bool> roomExists(String roomId) async {
    if (roomId == 'OFFLINE') return true;
    return (await _roomRef(roomId.toUpperCase()).get()).exists;
  }

  Future<void> joinRoom(String roomId, String userName,
      {String? rankLabel, String? photoUrl, bool isSilent = false}) async {
    if (roomId == 'OFFLINE') {
      _ensureOfflineEmits();
      return;
    }
    try {
      final doc  = await _roomRef(roomId).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      
      await _roomRef(roomId).update({
        if (!participants.contains(userName)) 'participants': FieldValue.arrayUnion([userName]),
        'participantData.$userName': {
          'rank': rankLabel ?? '',
          'photoUrl': photoUrl ?? '',
        },
      });

      if (!participants.contains(userName) && !isSilent) {
        await _sendSystem(roomId, '$userName joined the room 👋');
      }
    } catch (e) {
      // Room may have been deleted between check and update — silently ignore
    }
  }

  Future<void> leaveRoom(String roomId, String userName, {bool isSilent = false}) async {
    if (roomId == 'OFFLINE') return;
    try {
      final doc = await _roomRef(roomId).get();
      if (!doc.exists) return; // Room was already deleted — nothing to do
      await _roomRef(roomId).update({'participants': FieldValue.arrayRemove([userName])});
      if (!isSilent) await _sendSystem(roomId, '$userName left the room 🚪');
    } catch (e) {
      // Room may have been deleted — silently ignore
    }
  }

  /// Kick a member from the room (creator-only action)
  Future<void> kickMember(String roomId, String userName) async {
    if (roomId == 'OFFLINE') return;
    try {
      await _roomRef(roomId).update({
        'participants': FieldValue.arrayRemove([userName]),
      });
      await _sendSystem(roomId, '$userName was removed from the room 🚫');
    } catch (e) {
      // Silently ignore
    }
  }

  Future<void> updateUserMetadata(String roomId, String userName, String? rankLabel, String? photoUrl) async {
    if (roomId == 'OFFLINE') return;
    await _roomRef(roomId).update({
      'participantData.$userName': {
        'rank': rankLabel ?? '',
        'photoUrl': photoUrl ?? '',
      },
    });
  }

  Stream<Room?> roomStream(String roomId) {
    if (roomId == 'OFFLINE') {
      _ensureOfflineEmits();
      return _offlineRoomController.stream;
    }
    return _roomRef(roomId).snapshots().map((s) {
      if (!s.exists) return null;
      try {
        return Room.fromFirestore(s.id, s.data() as Map<String, dynamic>);
      } catch (e) {
        // Malformed document — return null instead of crashing the stream
        return null;
      }
    });
  }

  // ── Timer Controls ────────────────────────────────────────────────────────
  Future<void> startTimer(String id) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(timerStartTime: DateTime.now().millisecondsSinceEpoch, pausedElapsedMs: 0, isPaused: false, timerCompleted: false));
      return;
    }
    await _roomRef(id).update({
        'timerStartTime': DateTime.now().millisecondsSinceEpoch,
        'pausedElapsedMs': 0,
        'isPaused': false, 'timerCompleted': false,
      });
  }

  Future<void> pauseTimer(String id, int elapsedMs) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(isPaused: true, pausedElapsedMs: elapsedMs));
      return;
    }
    await _roomRef(id).update({
        'isPaused': true,
        'pausedElapsedMs': elapsedMs,
      });
  }

  Future<void> resumeTimer(String id, int elapsedMs) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(timerStartTime: DateTime.now().millisecondsSinceEpoch - elapsedMs, pausedElapsedMs: 0, isPaused: false));
      return;
    }
    await _roomRef(id).update({
        'timerStartTime': DateTime.now().millisecondsSinceEpoch - elapsedMs,
        'pausedElapsedMs': 0,
        'isPaused': false,
      });
  }

  Future<void> resetTimer(String id) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(clearTimerStartTime: true, isPaused: true, timerCompleted: false, pausedElapsedMs: 0));
      return;
    }
    await _roomRef(id).update({
        'timerStartTime': null, 'isPaused': true, 'timerCompleted': false, 'pausedElapsedMs': 0,
      });
  }

  Future<void> completeTimer(String id) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(timerCompleted: true, isPaused: true));
      return;
    }
    await _roomRef(id).update({'timerCompleted': true, 'isPaused': true});
  }

  Future<void> setTimerMode(String id, String mode) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(timerMode: mode));
      return;
    }
    await _roomRef(id).update({'timerMode': mode});
  }

  Future<void> setFocusDuration(String id, int ms) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(timerDuration: ms, clearTimerStartTime: true, isPaused: true, timerCompleted: false, pausedElapsedMs: 0));
      return;
    }
    await _roomRef(id).update({
        'timerDuration': ms, 'timerStartTime': null, 'isPaused': true, 'timerCompleted': false, 'pausedElapsedMs': 0,
      });
  }

  Future<void> setBreakDurations(String id, int shortMs, int longMs) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(shortBreakDuration: shortMs, longBreakDuration: longMs));
      return;
    }
    await _roomRef(id).update({'shortBreakDuration': shortMs, 'longBreakDuration': longMs});
  }

  Future<void> setPomodoroEnabled(String id, bool v) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(pomodoroEnabled: v));
      return;
    }
    await _roomRef(id).update({'pomodoroEnabled': v});
  }

  Future<void> advancePomodoroPhase(String id, Room current) async {
    int nextRound = current.pomodoroRound;
    PomodoroPhase nextPhase;
    if (current.currentPhase == PomodoroPhase.focus) {
      nextRound++;
      nextPhase = (nextRound % 4 == 0) ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
    } else {
      nextPhase = PomodoroPhase.focus;
    }
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(currentPhase: nextPhase, pomodoroRound: nextRound, clearTimerStartTime: true, isPaused: true, timerCompleted: false, pausedElapsedMs: 0));
      return;
    }
    await _roomRef(id).update({
      'currentPhase': nextPhase.name, 'pomodoroRound': nextRound,
      'timerStartTime': null, 'isPaused': true, 'timerCompleted': false, 'pausedElapsedMs': 0,
    });
  }

  Future<void> skipPhase(String id, Room current) => advancePomodoroPhase(id, current);

  // ── Sounds ────────────────────────────────────────────────────────────────
  Future<void> setAmbientSound(String id, String? key) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(selectedAmbient: key, clearSelectedAmbient: key == null));
      return;
    }
    await _roomRef(id).update({'selectedAmbient': key});
  }


  Future<void> setFocusAlert(String id, String key) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(focusAlertSound: key));
      return;
    }
    await _roomRef(id).update({'focusAlertSound': key});
  }

  Future<void> setBreakAlert(String id, String key) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(breakAlertSound: key));
      return;
    }
    await _roomRef(id).update({'breakAlertSound': key});
  }

  Future<void> setSyncTimerSounds(String id, bool sync) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) => r.copyWith(syncTimerSounds: sync));
      return;
    }
    await _roomRef(id).update({'syncTimerSounds': sync});
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────
  Stream<List<Task>> tasksStream(String id) {
    if (id == 'OFFLINE') return _offlineTasksController.stream;
    return _tasksRef(id)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map((d) => Task.fromFirestore(d.id, d.data() as Map<String, dynamic>)).toList());
  }

  Future<void> addTask(String id, String title, String desc, int secTarget, String by) async {
    if (id == 'OFFLINE') {
      _offlineTasks.add(Task(id: uuid.v4(), title: title, description: desc, targetTimeSec: secTarget, createdBy: by, completed: false, elapsedTimeSec: 0));
      _offlineTasksController.add(_offlineTasks);
      return;
    }
    await _tasksRef(id).add({'title': title, 'description': desc, 'completed': false,
          'targetTimeSec': secTarget, 'elapsedTimeSec': 0, 'createdBy': by,
          'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> toggleTaskComplete(String id, String taskId, bool v) async {
    if (id == 'OFFLINE') {
      final i = _offlineTasks.indexWhere((t) => t.id == taskId);
      if (i >= 0) {
        _offlineTasks[i] = Task(id: _offlineTasks[i].id, title: _offlineTasks[i].title, description: _offlineTasks[i].description, completed: v, targetTimeSec: _offlineTasks[i].targetTimeSec, elapsedTimeSec: _offlineTasks[i].elapsedTimeSec, createdBy: _offlineTasks[i].createdBy);
        _offlineTasksController.add(_offlineTasks);
      }
      return;
    }
    await _tasksRef(id).doc(taskId).update({'completed': v});
  }

  Future<void> deleteTask(String id, String taskId) async {
    if (id == 'OFFLINE') {
      _offlineTasks.removeWhere((t) => t.id == taskId);
      _offlineTasksController.add(_offlineTasks);
      _updateOffline((r) {
        final newTasks = List<String>.from(r.selectedTaskIds)..remove(taskId);
        return r.copyWith(selectedTaskIds: newTasks);
      });
      return;
    }
    await _roomRef(id).update({'selectedTaskIds': FieldValue.arrayRemove([taskId])});
    await _tasksRef(id).doc(taskId).delete();
  }

  Future<void> updateTask(String id, String taskId,
      {String? title, String? description, int? targetTimeSec, int? elapsedTimeSec}) async {
    if (id == 'OFFLINE') {
      final i = _offlineTasks.indexWhere((t) => t.id == taskId);
      if (i >= 0) {
        final old = _offlineTasks[i];
        _offlineTasks[i] = Task(
          id: old.id,
          title: title ?? old.title,
          description: description ?? old.description,
          completed: old.completed,
          targetTimeSec: targetTimeSec ?? old.targetTimeSec,
          elapsedTimeSec: elapsedTimeSec ?? old.elapsedTimeSec,
          createdBy: old.createdBy,
        );
        _offlineTasksController.add(_offlineTasks);
      }
      return;
    }
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (targetTimeSec != null) updates['targetTimeSec'] = targetTimeSec;
    if (elapsedTimeSec != null) updates['elapsedTimeSec'] = elapsedTimeSec;
    if (updates.isNotEmpty) {
      try { await _tasksRef(id).doc(taskId).update(updates); } catch (_) {}
    }
  }

  Future<void> toggleTaskSelected(String id, String taskId, bool selected) async {
    if (id == 'OFFLINE') {
      _updateOffline((r) {
        final newTasks = List<String>.from(r.selectedTaskIds);
        if (selected) { newTasks.add(taskId); } else { newTasks.remove(taskId); }
        return r.copyWith(selectedTaskIds: newTasks);
      });
      return;
    }
    await _roomRef(id).update({
        'selectedTaskIds': selected
            ? FieldValue.arrayUnion([taskId])
            : FieldValue.arrayRemove([taskId]),
      });
  }

  Future<void> updateTaskElapsed(String id, String taskId, int totalSec) async {
    if (id == 'OFFLINE') {
      final i = _offlineTasks.indexWhere((t) => t.id == taskId);
      if (i >= 0) {
        _offlineTasks[i] = Task(id: _offlineTasks[i].id, title: _offlineTasks[i].title, description: _offlineTasks[i].description, completed: _offlineTasks[i].completed, targetTimeSec: _offlineTasks[i].targetTimeSec, elapsedTimeSec: totalSec, createdBy: _offlineTasks[i].createdBy);
        _offlineTasksController.add(_offlineTasks);
      }
      return;
    }
    try {
      await _tasksRef(id).doc(taskId).update({'elapsedTimeSec': totalSec});
    } catch (e) {
      // Ignore errors (e.g. if task was deleted by another user while we were syncing)
    }
  }

  // ── Chat ──────────────────────────────────────────────────────────────────
  Stream<List<ChatMessage>> chatStream(String id) {
    if (id == 'OFFLINE') return _offlineChatController.stream;
    return _chatRef(id)
      .orderBy('sentAt', descending: false)
      .limitToLast(100)
      .snapshots()
      .map((s) => s.docs.map((d) => ChatMessage.fromFirestore(d.id, d.data() as Map<String, dynamic>)).toList());
  }

  Future<void> sendMessage(String roomId, String sender, String text,
      {String? senderPhotoUrl}) async {
    if (roomId == 'OFFLINE') {
      _offlineChats.add(ChatMessage(id: uuid.v4(), sender: sender, text: text, sentAt: DateTime.now(), isSystem: false, reactions: {}, seenBy: [sender], senderPhotoUrl: senderPhotoUrl));
      _offlineChatController.add(_offlineChats);
      return;
    }
    await _chatRef(roomId).add({
        'sender': sender,
        'text': text.trim(),
        'sentAt': FieldValue.serverTimestamp(),
        'isSystem': false,
        'reactions': {},
        'seenBy': [sender],
        if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
      });
  }

  /// Mark all recent messages as seen by [userName]
  Future<void> markMessagesSeen(String roomId, String userName) async {
    if (roomId == 'OFFLINE') {
      bool changed = false;
      for (int i=0; i<_offlineChats.length; i++) {
        if (!_offlineChats[i].seenBy.contains(userName)) {
          final newSeen = List<String>.from(_offlineChats[i].seenBy)..add(userName);
          _offlineChats[i] = ChatMessage(id: _offlineChats[i].id, sender: _offlineChats[i].sender, senderPhotoUrl: _offlineChats[i].senderPhotoUrl, text: _offlineChats[i].text, sentAt: _offlineChats[i].sentAt, isSystem: _offlineChats[i].isSystem, reactions: _offlineChats[i].reactions, seenBy: newSeen);
          changed = true;
        }
      }
      if (changed) _offlineChatController.add(_offlineChats);
      return;
    }
    final snap = await _chatRef(roomId)
        .orderBy('sentAt', descending: true)
        .limit(30)
        .get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      final seen = List<String>.from((d.data() as Map)['seenBy'] ?? []);
      if (!seen.contains(userName)) {
        batch.update(d.reference, {'seenBy': FieldValue.arrayUnion([userName])});
      }
    }
    await batch.commit();
  }

  Future<void> toggleReaction(String roomId, String msgId, String emoji, String userName) async {
    if (roomId == 'OFFLINE') {
      final i = _offlineChats.indexWhere((m) => m.id == msgId);
      if (i >= 0) {
        final r = Map<String, List<String>>.from(_offlineChats[i].reactions);
        final list = List<String>.from(r[emoji] ?? []);
        if (list.contains(userName)) { list.remove(userName); } else { list.add(userName); }
        if (list.isEmpty) { r.remove(emoji); } else { r[emoji] = list; }
        _offlineChats[i] = ChatMessage(id: _offlineChats[i].id, sender: _offlineChats[i].sender, senderPhotoUrl: _offlineChats[i].senderPhotoUrl, text: _offlineChats[i].text, sentAt: _offlineChats[i].sentAt, isSystem: _offlineChats[i].isSystem, reactions: r, seenBy: _offlineChats[i].seenBy);
        _offlineChatController.add(_offlineChats);
      }
      return;
    }
    final ref = _chatRef(roomId).doc(msgId);
    final doc = await ref.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final raw = Map<String, dynamic>.from(data['reactions'] ?? {});
    final users = List<String>.from(raw[emoji] ?? []);
    if (users.contains(userName)) {
      users.remove(userName);
    } else {
      users.add(userName);
    }
    if (users.isEmpty) {
      raw.remove(emoji);
    } else {
      raw[emoji] = users;
    }
    await ref.update({'reactions': raw});
  }

  /// Edit an existing chat message (only the sender can edit)
  Future<void> editMessage(String roomId, String msgId, String newText) async {
    if (roomId == 'OFFLINE') {
      final i = _offlineChats.indexWhere((m) => m.id == msgId);
      if (i >= 0) {
        final m = _offlineChats[i];
        _offlineChats[i] = ChatMessage(id: m.id, sender: m.sender, senderPhotoUrl: m.senderPhotoUrl, text: newText, sentAt: m.sentAt, isSystem: m.isSystem, isEdited: true, reactions: m.reactions, seenBy: m.seenBy);
        _offlineChatController.add(_offlineChats);
      }
      return;
    }
    await _chatRef(roomId).doc(msgId).update({'text': newText.trim(), 'isEdited': true});
  }

  /// Delete an existing chat message
  Future<void> deleteMessage(String roomId, String msgId) async {
    if (roomId == 'OFFLINE') {
      _offlineChats.removeWhere((m) => m.id == msgId);
      _offlineChatController.add(_offlineChats);
      return;
    }
    await _chatRef(roomId).doc(msgId).delete();
  }

  /// Clean only system messages (join/left) older than 24 hours — user messages are NEVER deleted
  Future<void> cleanOldSystemMessages(String roomId) async {
    if (roomId == 'OFFLINE') return;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final snap = await _chatRef(roomId)
        .where('isSystem', isEqualTo: true)
        .where('sentAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _sendSystem(String roomId, String text) async {
    if (roomId == 'OFFLINE') return;
    await _chatRef(roomId).add({'sender': 'System', 'text': text,
          'sentAt': FieldValue.serverTimestamp(), 'isSystem': true, 'reactions': {}});
  }
}
