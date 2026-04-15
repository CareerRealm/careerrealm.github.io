import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_background.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    AppStyle.applyLook(tp.look);
    return Scaffold(
      appBar: AppBar(
        title: Text('Appearance', style: AppStyle.pageTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: ThemeBackground(
        style: tp.theme.bg,
        child: Container(
          key: ValueKey('${tp.theme.name}_${tp.look.name}'),
          decoration: BoxDecoration(gradient: AppColors.bgGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LookSection(),
                  const SizedBox(height: 24),
                  _ThemeSection(),
                  const SizedBox(height: 24),
                  _TimerFaceSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LookSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final currentLook = tp.look;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text('🖌️ App Look', style: AppStyle.heading),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text('Changes the entire app visual style', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ),
        ...AppLook.values.map((look) {
          final sel = currentLook == look;
          return GestureDetector(
            onTap: () => tp.setLook(look),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppStyle.chipRadius),
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.stroke, 
                  width: sel ? 2 : 1,
                ),
                boxShadow: sel ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 12)] : null,
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.primaryGradient : null,
                    color: sel ? null : AppColors.card,
                    borderRadius: BorderRadius.circular(look == AppLook.brutalist ? 0 : look == AppLook.retro ? 4 : 12),
                    border: Border.all(color: sel ? Colors.transparent : AppColors.stroke),
                  ),
                  child: Center(child: Text(look.emoji, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(look.label, style: TextStyle(
                    fontSize: 14, fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                    color: sel ? AppColors.primaryLight : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(look.description, style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
                ])),
                if (sel) Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('🎨 App Theme',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3)),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: HarmoniThemeData.all.map((t) {
            final selected = t.name == tp.theme.name;
            return GestureDetector(
              onTap: () => tp.setTheme(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: t.bgGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? t.primary : AppColors.stroke,
                      width: selected ? 2 : 1),
                  boxShadow: selected
                      ? [BoxShadow(color: t.primary.withValues(alpha: 0.4), blurRadius: 12)]
                      : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(t.name.split(' ').first,
                      style: TextStyle(
                          fontSize: 10,
                          color: selected ? t.primaryLight : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
                      textAlign: TextAlign.center),
                  if (selected)
                    Container(
                        width: 14,
                        height: 2,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                            color: t.primary, borderRadius: BorderRadius.circular(2))),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _TimerFaceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⏱ Timer Face',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Choose how the timer ring looks in your room',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 14),
        Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TimerFace.values.map((f) {
              final sel = tp.timerFace == f;
              return GestureDetector(
                onTap: () => tp.setTimerFace(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: sel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AppColors.primary : AppColors.stroke, width: sel ? 1.5 : 1)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(f.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(f.label,
                        style: TextStyle(
                            fontSize: 10,
                            color: sel ? AppColors.primaryLight : AppColors.textSecondary,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                  ]),
                ),
              );
            }).toList()),
      ]),
    );
  }
}
