import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_app_check/firebase_app_check.dart'; // Enable when production keys are ready
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:window_manager/window_manager.dart';

import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/room_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow portrait + landscape rotation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // MUST await Firebase before runApp — otherwise FirebaseAuth.instance
  // is not ready when _checkAuth() fires, causing a grey screen hang.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /* =========================================================================
     [SECURITY: FIREBASE APP CHECK]
     Prevents unauthorized API calls, bots, and emulated traffic.
     Register your Android Play Integrity & iOS DeviceCheck keys in Firebase Console first!
  ========================================================================= */
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.playIntegrity,
  //   appleProvider: AppleProvider.deviceCheck,
  //   webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_V3_SITE_KEY'),
  // );

  // Initialize notification channels (makes app appear in Android sound settings)
  await NotificationService().init();

  // ── Windows: normal window ────────────────────────────
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();
    final winOpts = WindowOptions(
        size: const Size(1024, 768),
        minimumSize: const Size(400, 600),
        center: true,
        titleBarStyle: TitleBarStyle.normal,
        title: 'Career Realm',
        backgroundColor: AppColors.background,
      );
    await windowManager.waitUntilReadyToShow(
      winOpts,
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
    // Intercept the OS close button so we can cleanly leave the room
    // before the process exits. Without preventClose the window just
    // dies and didRequestAppExit never fires on Windows.
    await windowManager.setPreventClose(true);
  }

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const CareerRealmApp(),
      ),
    ),
  );
}


class CareerRealmApp extends StatefulWidget {
  const CareerRealmApp({super.key});
  @override
  State<CareerRealmApp> createState() => _CareerRealmAppState();
}

class _CareerRealmAppState extends State<CareerRealmApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  /// Called when the user clicks the OS close (X) button on Windows.
  /// We await leaveRoom so Firestore is updated before the window is destroyed.
  @override
  Future<void> onWindowClose() async {
    // Let AppProvider do the cleanup (leaveRoom + prefs clearing).
    final provider = context.read<AppProvider>();
    final user = provider.user;
    final roomId = provider.currentRoomId;
    if (user != null && roomId != null) {
      final rs = RoomService();
      await rs.leaveRoom(roomId, user.displayName, isSilent: true);
    }
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    // Keep AppColors and AppStyle in sync with the active settings.
    AppColors.applyTheme(themeProvider.theme);
    AppStyle.applyLook(themeProvider.look);

    return MaterialApp(
      // No ValueKey here — using a ValueKey would destroy the entire Navigator
      // stack every time the theme changes (kicking users out of Settings etc.).
      // Theme updates are propagated by ThemeBackground watching ThemeProvider.
      title: 'Career Realm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildFrom(themeProvider.theme),
      home: const _AuthGate(),
    );
  }
}

/// Bootstraps auth state — shows icon immediately so the 1-second wait feels instant
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _checked   = false;
  late AnimationController _fadeCtrl;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade     = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    _checkAuth();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  void _checkAuth() {
    FirebaseAuth.instance.authStateChanges().listen((fbUser) async {
      if (fbUser != null) {
        var user = await _authService.fetchUser(fbUser.uid);
        // If the Firebase user exists (e.g. persistent anonymous session) but the
        // Firestore user document is missing, recreate it instead of logging them out.
        if (user == null && mounted) {
           user = await _authService.resyncUser(fbUser);
        }
        if (user != null && mounted) {
          context.read<AppProvider>().setUser(user);
        } else if (mounted) {
           context.read<AppProvider>().setUser(null);
        }
      } else if (mounted) {
         context.read<AppProvider>().setUser(null);
      }
      if (mounted && !_checked) {
        setState(() => _checked = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClipOval(
                child: Image.asset('assets/images/Career Realm.png', width: 90, height: 90, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              const Text('Career Realm',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              Text('Gamified Focus & Validated Experience ✨',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Poppins')),
              const SizedBox(height: 32),
              SizedBox(width: 28, height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
            ]),
          ),
        ),
      );
    }

    final provider = context.watch<AppProvider>();
    if (provider.isLoggedIn) {
      // Show welcome message once after login
      final msg = provider.welcomeMessage;
      if (msg != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.clearWelcome();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.transparent, elevation: 0,
              duration: const Duration(seconds: 3),
              content: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.9), AppColors.primary]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20)],
                ),
                child: Row(children: [
                  const Text('👋', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                ]),
              ),
            ));
          }
        });
      }
      return const HomeScreen();
    }
    return const AuthScreen();
  }
}
