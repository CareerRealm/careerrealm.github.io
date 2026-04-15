import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'harmoni_theme_index';
  HarmoniThemeData _theme = HarmoniThemeData.purple;
  
  // Also manage other app-wide visual/behavioral settings
  TimerFace _timerFace = TimerFace.ring;
  AppLook _look = AppLook.classic;
  bool _autoStartBreaks = true;
  bool _autoStartFocus = false;
  bool _showRank = true;
  bool _strictFocusMode = false;
  bool _notificationsEnabled = true;

  HarmoniThemeData get theme => _theme;
  TimerFace get timerFace => _timerFace;
  AppLook get look => _look;
  bool get autoStartBreaks => _autoStartBreaks;
  bool get autoStartFocus => _autoStartFocus;
  bool get showRank => _showRank;
  bool get strictFocusMode => _strictFocusMode;
  bool get notificationsEnabled => _notificationsEnabled;

  ThemeProvider() {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Load theme
    final i = (prefs.getInt(_key) ?? 0).clamp(0, HarmoniThemeData.all.length - 1);
    _theme = HarmoniThemeData.all[i];
    AppColors.applyTheme(_theme);

    // Load other settings
    _timerFace = TimerFaceExt.fromIndex(prefs.getInt('timer_face_index') ?? 0);
    _look = AppLookExt.fromIndex(prefs.getInt('app_look_index') ?? 0);
    AppStyle.applyLook(_look);
    _autoStartBreaks = prefs.getBool('auto_start_breaks') ?? true;
    _autoStartFocus = prefs.getBool('auto_start_focus') ?? false;
    _showRank = prefs.getBool('show_rank') ?? true;
    _strictFocusMode = prefs.getBool('strict_focus_mode') ?? false;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    notifyListeners();
  }

  void setTheme(HarmoniThemeData t) async {
    _theme = t;
    AppColors.applyTheme(t);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, HarmoniThemeData.all.indexOf(t));
  }

  void setTimerFace(TimerFace f) async {
    _timerFace = f;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timer_face_index', TimerFace.values.indexOf(f));
  }

  void setLook(AppLook l) async {
    _look = l;
    AppStyle.applyLook(l);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_look_index', AppLook.values.indexOf(l));
  }

  void toggleAutoStartBreaks() async {
    _autoStartBreaks = !_autoStartBreaks;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start_breaks', _autoStartBreaks);
  }

  void toggleAutoStartFocus() async {
    _autoStartFocus = !_autoStartFocus;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start_focus', _autoStartFocus);
  }

  void toggleShowRank() async {
    _showRank = !_showRank;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_rank', _showRank);
  }

  void toggleStrictFocusMode() async {
    _strictFocusMode = !_strictFocusMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('strict_focus_mode', _strictFocusMode);
  }

  void toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
  }
}
