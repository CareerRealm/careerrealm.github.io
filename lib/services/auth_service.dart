
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web client ID (client_type: 3) from google-services.json.
    // Required so Android receives an idToken for Firebase credential exchange.
    serverClientId: '1028280226620-g652vkrgnkbmqbl5jnja8i3knopmd6sg.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool _isNewUser = false;
  bool get isNewUser => _isNewUser;

  Future<AppUser?> signInWithGoogle() async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        // Desktop / Web: use FirebaseAuth signInWithPopup
        final googleProvider = GoogleAuthProvider();
        
        // Add required scopes if necessary, but default scopes usually suffice
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        final result = await _auth.signInWithPopup(googleProvider);
        _isNewUser = result.additionalUserInfo?.isNewUser ?? false;
        return await _syncUser(result.user, isGuest: false);
      }
      // Android / iOS: use native GoogleSignIn
      final gUser = await _googleSignIn.signIn();
      if (gUser == null) return null;
      final gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      final result = await _auth.signInWithCredential(credential);
      _isNewUser = result.additionalUserInfo?.isNewUser ?? false;
      return await _syncUser(result.user, isGuest: false);
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e);
    } catch (e) { rethrow; }
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      _isNewUser = false;
      return await _syncUser(result.user, isGuest: false);
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<AppUser?> createAccountWithEmail(
      String displayName, String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await result.user?.updateDisplayName(displayName.trim());
      _isNewUser = true;
      return await _syncUser(result.user, isGuest: false, overrideName: displayName.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<AppUser?> continueAsGuest(String guestName) async {
    final name = guestName.trim().isEmpty
        ? 'Guest${const Uuid().v4().substring(0, 4).toUpperCase()}'
        : guestName.trim();
    try {
      final result = await _auth.signInAnonymously();
      return await _syncUser(result.user, isGuest: true, overrideName: name);
    } catch (_) {
      // Anonymous auth not enabled — local guest fallback
      return AppUser(
          uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          displayName: name,
          isGuest: true);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {} // Ignore unsupported errors on Windows
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String uid, String newName) async {
    await _db.collection('users').doc(uid).update({'displayName': newName.trim()});
    await _auth.currentUser?.updateDisplayName(newName.trim());
  }

  /// Update profile photo URL directly
  Future<bool> updateProfilePhotoUrl(String uid, String url) async {
    try {
      await _db.collection('users').doc(uid).update({'photoUrl': url});
      return true;
    } catch (e) {
      debugPrint('Avatar update error: $e');
      return false;
    }
  }

  Future<void> setDailyTarget(String uid, int minutes) async {
    await _db.collection('users').doc(uid).update({'dailyTargetMin': minutes});
  }

  // ── Incremental focus recording (Issues 5, 7, 9) ─────────────────────────
  Future<void> recordFocusTime(String uid, int durationSec,
      {bool countSession = false, bool isBreak = false}) async {
    if (durationSec <= 0) return;
    final minutes = (durationSec / 60).round();
    final xpEarned = minutes; // Base global XP
    final axpEarned = isBreak ? 0 : minutes; // Career Academic XP
    final hpDelta = isBreak ? 15 : -10; // Breaks heal 15 HP, Focus drains 10 HP.

    // Determine if today's focus should reset
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final lastDate = (data['lastFocusDate'] as String?) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final sameDay = lastDate == today;

    // Increment daily history
    final historyPath = 'history.$today';

    // ── Streak logic ──────────────────────────────────────────────────────
    int? newStreak;
    if (!sameDay) {
      // Check if yesterday was the last focus day → continue streak
      final yesterday = DateTime.now().subtract(const Duration(days: 1))
                            .toIso8601String().substring(0, 10);
      final currentStreak = (data['streak'] ?? 0) as int;
      if (lastDate == yesterday) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1; // reset — gap of >1 day
      }
    }
    
    // Calculate HP bounds (max 100, min 0)
    final currentHp = (data['hp'] ?? 100) as int;
    int newHp = currentHp + hpDelta;
    if (newHp > 100) newHp = 100;
    if (newHp < 0) newHp = 0;

    await _db.collection('users').doc(uid).update({
      'focusTimeSec':  FieldValue.increment(isBreak ? 0 : durationSec),
      'xp':            FieldValue.increment(xpEarned),
      'axp':           FieldValue.increment(axpEarned),
      'hp':            newHp,
      'lastFocusDate': today,
      // Reset today's counter if it's a new day
      'todayFocusSec': sameDay ? FieldValue.increment(durationSec) : durationSec,
      historyPath:     FieldValue.increment(durationSec),
      if (newStreak != null) 'streak': newStreak,
      if (countSession) 'sessionsCompleted': FieldValue.increment(1),
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // ── Internal ──────────────────────────────────────────────────────────────
  /// Convert Firebase error codes to user-friendly messages
  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
      case 'user-not-found':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'operation-not-allowed':
        return 'Sign-in method not enabled. Contact support.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Sign-in was cancelled.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  Future<AppUser?> fetchUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('fetchUser error: $e');
      return null;
    }
  }

  Stream<AppUser?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((s) {
      if (!s.exists) return null;
      return AppUser.fromFirestore(s.data()!);
    });
  }

  // ── Internal ──────────────────────────────────────────────────────────────
  Future<AppUser?> resyncUser(User fbUser) {
    return _syncUser(fbUser, isGuest: fbUser.isAnonymous);
  }

  Future<AppUser?> _syncUser(User? user,
      {bool isGuest = false, String? overrideName}) async {
    if (user == null) return null;
    
    try {
      final existing = await _db.collection('users').doc(user.uid).get();
      final ex = existing.data() ?? {};
      
      final displayName = overrideName ?? 
                          (ex['displayName'] as String?) ?? 
                          user.displayName ?? 
                          user.email?.split('@').first ?? 
                          'User';
                          
      final profile = AppUser(
        uid: user.uid,
        displayName: displayName,
        email: user.email,
        isGuest: isGuest,
        focusTimeSec: (ex['focusTimeSec'] ?? 0).toInt(),
        sessionsCompleted: (ex['sessionsCompleted'] ?? 0).toInt(),
        xp: (ex['xp'] ?? 0).toInt(),
        axp: (ex['axp'] ?? 0).toInt(),
        pxp: (ex['pxp'] ?? 0).toInt(),
        hp: (ex['hp'] ?? 100).toInt(),
        streak: (ex['streak'] ?? 0).toInt(),
        dailyTargetMin: (ex['dailyTargetMin'] ?? 60).toInt(),
        todayFocusSec: (ex['todayFocusSec'] ?? 0).toInt(),
        photoUrl: ex['photoUrl'] as String?,
      );
      await _db.collection('users').doc(user.uid).set(profile.toMap(), SetOptions(merge: true));
      return profile;
    } catch (e) {
      debugPrint('_syncUser error: $e');
      final fallbackName = overrideName ?? user.displayName ?? user.email?.split('@').first ?? 'User';
      return AppUser(uid: user.uid, displayName: fallbackName, isGuest: isGuest);
    }
  }
}
