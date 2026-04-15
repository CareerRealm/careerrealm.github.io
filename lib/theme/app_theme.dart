import 'package:flutter/material.dart';

ImageProvider getAvatarProvider(String? url) {
  if (url == null || url.isEmpty) return const AssetImage('assets/images/anonymous.png');
  return url.startsWith('http') ? NetworkImage(url) as ImageProvider : AssetImage(url);
}

// ─────────────────────────────────────────────────────────────────────────────
// Background style enum — controls animated overlay
// ─────────────────────────────────────────────────────────────────────────────
enum ThemeBg { solid, clouds, forest, aurora, petals, rain, stars, fireflies }

// ─────────────────────────────────────────────────────────────────────────────
// Timer face style
// ─────────────────────────────────────────────────────────────────────────────
enum TimerFace { ring, arcs, dots, minimal, neon, analog, digital, glowNeo, celestial, ambientFlow }

extension TimerFaceExt on TimerFace {
  String get label {
    switch (this) {
      case TimerFace.ring:    return 'Classic Ring';
      case TimerFace.arcs:    return 'Arc Segments';
      case TimerFace.dots:    return 'Dot Circle';
      case TimerFace.minimal: return 'Minimal';
      case TimerFace.neon:    return 'Neon';
      case TimerFace.analog:  return 'Analog Clock';
      case TimerFace.digital: return 'Digital LCD';
      case TimerFace.glowNeo: return 'Glow Neo';
      case TimerFace.celestial: return 'Celestial';
      case TimerFace.ambientFlow: return 'Ambient Flow';
    }
  }
  String get emoji {
    switch (this) {
      case TimerFace.ring:    return '🔵';
      case TimerFace.arcs:    return '⚡';
      case TimerFace.dots:    return '⭕';
      case TimerFace.minimal: return '◯';
      case TimerFace.neon:    return '💫';
      case TimerFace.analog:  return '🕐';
      case TimerFace.digital: return '🔢';
      case TimerFace.glowNeo: return '🌟';
      case TimerFace.celestial: return '🌌';
      case TimerFace.ambientFlow: return '🌊';
    }
  }
  static TimerFace fromIndex(int i) => TimerFace.values[i.clamp(0, TimerFace.values.length - 1)];
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme palette descriptor — 10 themes
// ─────────────────────────────────────────────────────────────────────────────
class HarmoniThemeData {
  final String name;
  final String emoji;
  final Color primary;
  final Color primaryLight;
  final ThemeBg bg;
  final Brightness brightness;

  const HarmoniThemeData({
    required this.name,
    required this.emoji,
    required this.primary,
    required this.primaryLight,
    this.bg = ThemeBg.solid,
    this.brightness = Brightness.dark,
  });

  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get bgGradient => LinearGradient(
        colors: [
          AppColors.background,
          Color.lerp(AppColors.background, primary, 0.2)!,
          AppColors.background,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ── 10 built-in themes ───────────────────────────────────────────────────
  static const purple = HarmoniThemeData(
    name: 'Purple Night', emoji: '💜',
    primary: Color(0xFF7C3AED), primaryLight: Color(0xFFA78BFA),
    bg: ThemeBg.stars,
  );
  static const ocean = HarmoniThemeData(
    name: 'Ocean Blue', emoji: '🌊',
    primary: Color(0xFF0284C7), primaryLight: Color(0xFF38BDF8),
    bg: ThemeBg.solid,
  );
  static const forest = HarmoniThemeData(
    name: 'Deep Forest', emoji: '🌲',
    primary: Color(0xFF15803D), primaryLight: Color(0xFF4ADE80),
    bg: ThemeBg.forest,
  );
  static const sunset = HarmoniThemeData(
    name: 'Sunset', emoji: '🌅',
    primary: Color(0xFFEA580C), primaryLight: Color(0xFFFBBF24),
    bg: ThemeBg.solid,
  );
  static const sakura = HarmoniThemeData(
    name: 'Sakura Night', emoji: '🌸',
    primary: Color(0xFFDB2777), primaryLight: Color(0xFFF9A8D4),
    bg: ThemeBg.petals,
  );
  static const cloudy = HarmoniThemeData(
    name: 'Cloudy Day', emoji: '⛅',
    primary: Color(0xFF4B7BEC), primaryLight: Color(0xFF74B9FF),
    bg: ThemeBg.clouds,
  );
  static const aurora = HarmoniThemeData(
    name: 'Aurora', emoji: '🌌',
    primary: Color(0xFF047857), primaryLight: Color(0xFF34D399),
    bg: ThemeBg.aurora,
  );
  static const galaxy = HarmoniThemeData(
    name: 'Galaxy', emoji: '🔮',
    primary: Color(0xFF4F46E5), primaryLight: Color(0xFF818CF8),
    bg: ThemeBg.stars,
  );
  static const rain = HarmoniThemeData(
    name: 'Hidden Rain', emoji: '🌧️',
    primary: Color(0xFF0369A1), primaryLight: Color(0xFF7DD3FC),
    bg: ThemeBg.rain,
  );
  static const fireflies = HarmoniThemeData(
    name: 'Fireflies', emoji: '✨',
    primary: Color(0xFFD97706), primaryLight: Color(0xFFFDE68A),
    bg: ThemeBg.fireflies,
  );

  // ── NEW CREATIVE DARK ────────────────────────────────────────────────────
  static const volcano = HarmoniThemeData(
    name: 'Volcano Core', emoji: '🌋',
    primary: Color(0xFFDC2626), primaryLight: Color(0xFFFB923C),
    bg: ThemeBg.solid,
  );
  static const cyberpunk = HarmoniThemeData(
    name: 'Cyber City', emoji: '🏙️',
    primary: Color(0xFF06B6D4), primaryLight: Color(0xFFF43F5E),
    bg: ThemeBg.stars,
  );
  static const matcha = HarmoniThemeData(
    name: 'Midnight Matcha', emoji: '🍵',
    primary: Color(0xFF65A30D), primaryLight: Color(0xFFA3E635),
    bg: ThemeBg.forest,
  );

  // ── NEW LIGHT THEMES ─────────────────────────────────────────────────────
  static const morning = HarmoniThemeData(
    name: 'Morning Dew', emoji: '🌞',
    primary: Color(0xFF0284C7), primaryLight: Color(0xFF38BDF8),
    brightness: Brightness.light,
    bg: ThemeBg.clouds,
  );
  static const peach = HarmoniThemeData(
    name: 'Peach Bliss', emoji: '🍑',
    primary: Color(0xFFE11D48), primaryLight: Color(0xFFFB7185),
    brightness: Brightness.light,
    bg: ThemeBg.petals,
  );
  static const mint = HarmoniThemeData(
    name: 'Fresh Mint', emoji: '🌿',
    primary: Color(0xFF059669), primaryLight: Color(0xFF34D399),
    brightness: Brightness.light,
    bg: ThemeBg.solid,
  );
  static const latte = HarmoniThemeData(
    name: 'Vanilla Latte', emoji: '☕',
    primary: Color(0xFFD97706), primaryLight: Color(0xFFFBBF24),
    brightness: Brightness.light,
    bg: ThemeBg.solid,
  );

  // ── NEW SUPER THEMES ─────────────────────────────────────────────────────
  static const neonVoid = HarmoniThemeData(
    name: 'Neon Void', emoji: '👾',
    primary: Color(0xFF00FFCC), primaryLight: Color(0xFFFF00FF),
    bg: ThemeBg.stars,
  );
  static const arcticWind = HarmoniThemeData(
    name: 'Arctic Wind', emoji: '❄️',
    primary: Color(0xFF0EA5E9), primaryLight: Color(0xFFE0F2FE),
    bg: ThemeBg.clouds,
  );
  static const desertGold = HarmoniThemeData(
    name: 'Desert Gold', emoji: '🏜️',
    primary: Color(0xFFB45309), primaryLight: Color(0xFFFEF3C7),
    bg: ThemeBg.fireflies,
  );

  static const List<HarmoniThemeData> all = [
    // Dark
    purple, ocean, forest, sunset, sakura,
    cloudy, aurora, galaxy, rain, fireflies,
    volcano, cyberpunk, matcha,
    // Light
    morning, peach, mint, latte,
    // Super Themes
    neonVoid, arcticWind, desertGold,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// AppColors — static constants + theme-dynamic getters
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static HarmoniThemeData _active = HarmoniThemeData.ocean;
  static void applyTheme(HarmoniThemeData t) => _active = t;
  static HarmoniThemeData get activeTheme => _active;

  // Dynamic
  static Color get primary          => _active.primary;
  static Color get primaryLight     => _active.primaryLight;
  static LinearGradient get primaryGradient => _active.primaryGradient;
  static LinearGradient get bgGradient      => _active.bgGradient;

  // Dynamic Palette based on Brightness
  static bool get isDark => _active.brightness == Brightness.dark;

  static Color get background   => isDark ? Color(0xFF0D0D1A) : Color(0xFFF3F4F6);
  static Color get surface      => isDark ? Color(0xFF12122A) : Color(0xFFFFFFFF);
  static Color get surfaceLight => isDark ? Color(0xFF1A1A38) : Color(0xFFF9FAFB);
  static Color get card         => isDark ? Color(0xFF181830) : Color(0xFFFFFFFF);
  static Color get stroke       => isDark ? Color(0xFF1E1E3A) : Color(0xFFE5E7EB);
  static Color get strokeBright => isDark ? Color(0xFF2E2E5A) : Color(0xFFD1D5DB);
  static Color get timerRingBg  => isDark ? Color(0xFF1E1E3A) : Color(0xFFE5E7EB);

  static const Color amber  = Color(0xFFFBBF24);
  static const Color green  = Color(0xFF34D399);

  static Color get textPrimary   => isDark ? Color(0xFFFFFFFF) : Color(0xFF111827);
  static Color get textSecondary => isDark ? Color(0xFF9B99CC) : Color(0xFF4B5563);
  static Color get textMuted     => isDark ? Color(0xFF5A5880) : Color(0xFF9CA3AF);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppLook — defines entirely different visual layouts
// ─────────────────────────────────────────────────────────────────────────────
enum AppLook { classic, glass, brutalist, cozy, retro }

extension AppLookExt on AppLook {
  String get label {
    switch (this) {
      case AppLook.classic:   return 'Classic';
      case AppLook.glass:     return 'Glassmorphism';
      case AppLook.brutalist: return 'Brutalist';
      case AppLook.cozy:      return 'Cozy';
      case AppLook.retro:     return 'Retro';
    }
  }
  String get emoji {
    switch (this) {
      case AppLook.classic:   return '🎯';
      case AppLook.glass:     return '🪟';
      case AppLook.brutalist: return '🏗️';
      case AppLook.cozy:      return '☕';
      case AppLook.retro:     return '🕹️';
    }
  }
  String get description {
    switch (this) {
      case AppLook.classic:   return 'Clean dark UI with smooth gradients';
      case AppLook.glass:     return 'Frosted glass cards with transparency';
      case AppLook.brutalist: return 'Bold, sharp edges, high contrast';
      case AppLook.cozy:      return 'Warm, soft rounded, gentle shadows';
      case AppLook.retro:     return 'Pixel-inspired, retro game aesthetic';
    }
  }
  static AppLook fromIndex(int i) => AppLook.values[i.clamp(0, AppLook.values.length - 1)];
}

// ─────────────────────────────────────────────────────────────────────────────
// AppStyle — look-aware styling tokens used across all screens
// ─────────────────────────────────────────────────────────────────────────────
class AppStyle {
  static AppLook _look = AppLook.classic;
  static void applyLook(AppLook l) => _look = l;
  static AppLook get currentLook => _look;

  // ── Border Radius ──────────────────────────────────────────────────────────
  static double get cardRadius {
    switch (_look) {
      case AppLook.classic:   return 20;
      case AppLook.glass:     return 24;
      case AppLook.brutalist: return 0;
      case AppLook.cozy:      return 28;
      case AppLook.retro:     return 4;
    }
  }
  static double get buttonRadius {
    switch (_look) {
      case AppLook.classic:   return 16;
      case AppLook.glass:     return 20;
      case AppLook.brutalist: return 0;
      case AppLook.cozy:      return 24;
      case AppLook.retro:     return 2;
    }
  }
  static double get chipRadius {
    switch (_look) {
      case AppLook.classic:   return 12;
      case AppLook.glass:     return 16;
      case AppLook.brutalist: return 0;
      case AppLook.cozy:      return 20;
      case AppLook.retro:     return 2;
    }
  }
  static double get sheetRadius {
    switch (_look) {
      case AppLook.classic:   return 28;
      case AppLook.glass:     return 32;
      case AppLook.brutalist: return 0;
      case AppLook.cozy:      return 36;
      case AppLook.retro:     return 0;
    }
  }

  // ── Card Decoration ────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({Color? color, Gradient? gradient, bool elevated = false}) {
    final base = color ?? AppColors.card;
    switch (_look) {
      case AppLook.classic:
        return BoxDecoration(
          color: gradient == null ? base : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: AppColors.stroke),
          boxShadow: elevated ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6))] : null,
        );
      case AppLook.glass:
        return BoxDecoration(
          color: (gradient == null ? base : AppColors.card).withValues(alpha: 0.35),
          gradient: gradient != null && gradient is LinearGradient ? LinearGradient(
            colors: gradient.colors.map((c) => c.withValues(alpha: 0.4)).toList(),
            begin: gradient.begin, end: gradient.end,
          ) : null,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 8))],
        );
      case AppLook.brutalist:
        return BoxDecoration(
          color: gradient == null ? base : null,
          gradient: gradient,
          border: Border.all(color: AppColors.textPrimary, width: 2.5),
          boxShadow: [BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.3), offset: const Offset(4, 4))],
        );
      case AppLook.cozy:
        return BoxDecoration(
          color: gradient == null ? base : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: AppColors.stroke.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12),
          ],
        );
      case AppLook.retro:
        return BoxDecoration(
          color: gradient == null ? base : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: AppColors.primaryLight, width: 2),
          boxShadow: [BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.15), offset: const Offset(3, 3))],
        );
    }
  }

  // ── Button Style ───────────────────────────────────────────────────────────
  static ButtonStyle elevatedButtonStyle({Color? bg}) {
    final bgColor = bg ?? AppColors.primary;
    switch (_look) {
      case AppLook.classic:
        return ElevatedButton.styleFrom(
          backgroundColor: bgColor, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
          elevation: 8, shadowColor: bgColor.withValues(alpha: 0.5),
        );
      case AppLook.glass:
        return ElevatedButton.styleFrom(
          backgroundColor: bgColor.withValues(alpha: 0.6), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
          elevation: 0,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        );
      case AppLook.brutalist:
        return ElevatedButton.styleFrom(
          backgroundColor: bgColor, foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
          side: BorderSide(color: AppColors.textPrimary, width: 2.5),
          elevation: 0,
        );
      case AppLook.cozy:
        return ElevatedButton.styleFrom(
          backgroundColor: bgColor, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
          elevation: 4, shadowColor: bgColor.withValues(alpha: 0.3),
        );
      case AppLook.retro:
        return ElevatedButton.styleFrom(
          backgroundColor: bgColor, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
          side: BorderSide(color: AppColors.primaryLight, width: 2),
          elevation: 0,
        );
    }
  }

  // ── Section Title Style ────────────────────────────────────────────────────
  static TextStyle get sectionTitle {
    switch (_look) {
      case AppLook.classic:
        return TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5);
      case AppLook.glass:
        return TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1.0);
      case AppLook.brutalist:
        return TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 2.0, decoration: TextDecoration.underline);
      case AppLook.cozy:
        return TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryLight, letterSpacing: 0.3);
      case AppLook.retro:
        return TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight, letterSpacing: 1.5, fontFamily: 'monospace');
    }
  }

  // ── Page Title Style ───────────────────────────────────────────────────────
  static TextStyle get pageTitle {
    switch (_look) {
      case AppLook.classic:
        return const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white);
      case AppLook.glass:
        return TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9), letterSpacing: 0.5);
      case AppLook.brutalist:
        return const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2);
      case AppLook.cozy:
        return TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
      case AppLook.retro:
        return TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryLight, fontFamily: 'monospace', letterSpacing: 1);
    }
  }

  // ── Heading Style ──────────────────────────────────────────────────────────
  static TextStyle get heading {
    switch (_look) {
      case AppLook.classic:
        return TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
      case AppLook.glass:
        return TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95));
      case AppLook.brutalist:
        return TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1);
      case AppLook.cozy:
        return TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
      case AppLook.retro:
        return TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryLight, fontFamily: 'monospace');
    }
  }

  // ── Chat Bubble Decoration ─────────────────────────────────────────────────
  static BoxDecoration chatBubble({required bool isMe}) {
    switch (_look) {
      case AppLook.classic:
        return BoxDecoration(
          gradient: isMe ? AppColors.primaryGradient : LinearGradient(colors: [AppColors.surfaceLight, AppColors.card]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
        );
      case AppLook.glass:
        return BoxDecoration(
          color: isMe ? AppColors.primary.withValues(alpha: 0.4) : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        );
      case AppLook.brutalist:
        return BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceLight,
          border: Border.all(color: AppColors.textPrimary, width: 2),
        );
      case AppLook.cozy:
        return BoxDecoration(
          color: isMe ? AppColors.primary.withValues(alpha: 0.85) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        );
      case AppLook.retro:
        return BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.primaryLight, width: 1.5),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MaterialApp ThemeData builder
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData buildFrom(HarmoniThemeData t) {
    final isDark = t.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      colorScheme: isDark ? ColorScheme.dark(
        primary: t.primary,
        secondary: t.primaryLight,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ) : ColorScheme.light(
        primary: t.primary,
        secondary: t.primaryLight,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface, elevation: 0,
        titleTextStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.textPrimary),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyle.cardRadius), side: BorderSide(color: AppColors.stroke)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary, foregroundColor: Colors.white,
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyle.buttonRadius), side: const BorderSide(color: Colors.white24, width: 1.5)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 12, shadowColor: t.primary.withValues(alpha: 0.8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.primaryLight,
          side: BorderSide(color: t.primaryLight, width: 1.5),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyle.buttonRadius)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.primaryLight,
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppStyle.chipRadius), borderSide: BorderSide(color: AppColors.stroke)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppStyle.chipRadius), borderSide: BorderSide(color: AppColors.stroke)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppStyle.chipRadius), borderSide: BorderSide(color: t.primary, width: 2)),
        labelStyle: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins'),
        hintStyle: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      textTheme: TextTheme(
        displayLarge:   TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
        headlineLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        titleLarge:     TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        titleMedium:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
        bodyLarge:      TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins'),
        bodyMedium:     TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins'),
        bodySmall:      TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? t.primaryLight : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? t.primary.withValues(alpha: 0.4) : AppColors.surfaceLight),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(gradient: t.primaryGradient, borderRadius: BorderRadius.circular(AppStyle.chipRadius)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13),
      ),
    );
  }

  static ThemeData get dark => buildFrom(AppColors.activeTheme);
}
