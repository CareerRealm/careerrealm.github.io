import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';

class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final RoomService _roomService = RoomService();

  AppUser? _user;
  String? _currentRoomId;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<AppUser?>? _userSub; // Issue 5/9 — live Firestore sync

  AppUser? get user          => _user;
  String? get currentRoomId  => _currentRoomId;
  bool   get isLoading       => _isLoading;
  String? get error          => _error;
  bool   get isLoggedIn      => _user != null;
  bool   get isGuest         => _user?.isGuest ?? false;
  bool   get isNewUser       => _authService.isNewUser;
  String? _welcomeMessage;
  String? get welcomeMessage => _welcomeMessage;
  void clearWelcome() { _welcomeMessage = null; }

  AppProvider() {
    WidgetsBinding.instance.addObserver(this);
    _cleanupZombies();
  }

  Future<void> _cleanupZombies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRoom = prefs.getString('last_room_id');
      final lastName = prefs.getString('last_user_name');
      if (lastRoom != null && lastName != null) {
        // The app was killed improperly before. Clear them from room silently.
        // Always clear prefs FIRST so we don't get stuck in a retry loop
        await prefs.remove('last_room_id');
        await prefs.remove('last_user_name');
        await _roomService.leaveRoom(lastRoom, lastName, isSilent: true);
      }
    } catch (e) {
      // Firestore may be unavailable — don't block app startup
    }
  }

  void setUser(AppUser? u) {
    _user = u;
    notifyListeners();
    // Start live Firestore listener for real-time stat updates (Issues 5,9)
    if (u != null && !u.isGuest) {
      _startUserStream(u.uid);
    } else {
      _userSub?.cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      if (_user != null && _currentRoomId != null) {
        _roomService.leaveRoom(_currentRoomId!, _user!.displayName, isSilent: true);
      }
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    if (_user != null && _currentRoomId != null) {
      await _roomService.leaveRoom(_currentRoomId!, _user!.displayName, isSilent: true);
    }
    return AppExitResponse.exit;
  }

  /// Keep local user in sync with Firestore in real-time
  void _startUserStream(String uid) {
    _userSub?.cancel();
    _userSub = _authService.userStream(uid).listen((u) {
      if (u != null) {
        _user = u;
        notifyListeners();
      }
    });
  }

  void setCurrentRoom(String? id) async {
    _currentRoomId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (id != null && _user != null && !_user!.isGuest) {
      await prefs.setString('last_room_id', id);
      await prefs.setString('last_user_name', _user!.displayName);
    } else {
      await prefs.remove('last_room_id');
      await prefs.remove('last_user_name');
    }
  }

  void setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void setError(String? e) { _error = e; notifyListeners(); }

  // ── Auth methods ──────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    setLoading(true); setError(null);
    try {
      final u = await _authService.signInWithGoogle();
      setUser(u);
      if (u != null) {
        _welcomeMessage = _authService.isNewUser
          ? 'Welcome to Career Realm, ${u.displayName}! 🎉'
          : 'Welcome back, ${u.displayName}! 👋';
      }
      return u != null;
    } catch (e) { setError(e.toString()); return false; }
    finally { setLoading(false); }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    setLoading(true); setError(null);
    try {
      final u = await _authService.signInWithEmail(email, password);
      setUser(u);
      if (u != null) _welcomeMessage = 'Welcome back, ${u.displayName}! 👋';
      return u != null;
    } catch (e) { setError(e.toString()); return false; }
    finally { setLoading(false); }
  }

  Future<bool> createAccount(String name, String email, String password) async {
    setLoading(true); setError(null);
    try {
      final u = await _authService.createAccountWithEmail(name, email, password);
      setUser(u);
      if (u != null) _welcomeMessage = 'Welcome to Career Realm, ${u.displayName}! 🎉';
      return u != null;
    } catch (e) { setError(e.toString()); return false; }
    finally { setLoading(false); }
  }

  Future<bool> continueAsGuest(String name) async {
    setLoading(true); setError(null);
    try {
      final u = await _authService.continueAsGuest(name);
      setUser(u);
      return u != null;
    } catch (e) { setError(e.toString()); return false; }
    finally { setLoading(false); }
  }

  Future<void> signOut() async {
    _userSub?.cancel();
    await _authService.signOut();
    _user = null;
    _currentRoomId = null;
    notifyListeners();
  }

  // ── Incremental focus time (Issues 5, 7, 9) ───────────────────────────────
  Future<void> recordFocusTime(int seconds, {bool countSession = false, bool isBreak = false}) async {
    if (_user == null || _user!.isGuest || seconds <= 0) return;
    await _authService.recordFocusTime(_user!.uid, seconds, countSession: countSession, isBreak: isBreak);
    // _startUserStream will automatically update _user via Firestore listener
  }

  Future<void> setDailyTarget(int minutes) async {
    if (_user == null || _user!.isGuest) return;
    await _authService.setDailyTarget(_user!.uid, minutes);
  }

  Future<bool> updateAvatar(String url) async {
    if (_user == null || _user!.isGuest) return false;
    final success = await _authService.updateProfilePhotoUrl(_user!.uid, url);
    if (success) {
      _user = AppUser(
        uid: _user!.uid, displayName: _user!.displayName,
        email: _user!.email, isPremium: _user!.isPremium,
        focusTimeSec: _user!.focusTimeSec, sessionsCompleted: _user!.sessionsCompleted,
        xp: _user!.xp, streak: _user!.streak, isGuest: _user!.isGuest,
        lastSeen: _user!.lastSeen,
        dailyTargetMin: _user!.dailyTargetMin, todayFocusSec: _user!.todayFocusSec,
        photoUrl: url,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  void refreshUser() async {
    if (_user == null || _user!.isGuest) return;
    final u = await _authService.fetchUser(_user!.uid);
    if (u != null) setUser(u);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userSub?.cancel();
    super.dispose();
  }
}
