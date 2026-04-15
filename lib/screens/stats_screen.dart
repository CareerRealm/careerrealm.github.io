import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().user;
    final tp = context.watch<ThemeProvider>();
    AppStyle.applyLook(tp.look);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            _header(context),
            if (user == null || user.isGuest)
              const Expanded(child: Center(child: _GuestBlock()))
            else
              Expanded(child: _body(context, user)),
          ]),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Your Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      );

  Widget _body(BuildContext context, AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(children: [
        _RankHeroCard(user: user),
        const SizedBox(height: 14),
        _statsGrid(user),
        const SizedBox(height: 14),
        _XpBar(user: user),
        const SizedBox(height: 14),
        _GlobalRankCard(user: user),
        const SizedBox(height: 14),
        _DailyTargetCard(user: user),
        const SizedBox(height: 14),
        _StudyHistoryChart(user: user),
        const SizedBox(height: 20),
        const _CosmicJourney(),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _statsGrid(AppUser user) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _StatCard(emoji: '⏱', label: 'Total Focus', value: user.formattedFocusTime,
            colors: const [Color(0xFF6D28D9), Color(0xFF7C3AED)]),
        _StatCard(emoji: '🎯', label: 'Sessions', value: '${user.sessionsCompleted}',
            colors: const [Color(0xFF0F766E), Color(0xFF059669)]),
        _StatCard(emoji: '⚡', label: 'XP Earned', value: '${user.xp}',
            colors: const [Color(0xFFD97706), Color(0xFFF59E0B)]),
        _StatCard(emoji: '🔥', label: 'Day Streak', value: '${user.streak}',
            colors: const [Color(0xFFDC2626), Color(0xFFEF4444)]),
      ],
    );
  }
}

class _GuestBlock extends StatelessWidget {
  const _GuestBlock();
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔒', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text('Sign in to track your progress',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        const SizedBox(height: 6),
        Text('XP • Ranks • Daily Targets • Streaks',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ]);
}

// ────────────────────────────────────────────────────────────────────────────
// Global ranking card
// ────────────────────────────────────────────────────────────────────────────
class _GlobalRankCard extends StatelessWidget {
  final AppUser user;
  const _GlobalRankCard({required this.user});

  Future<Map<String, dynamic>> _fetch() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('xp', descending: true)
          .limit(100)
          .get();
      final docs = snap.docs;
      final idx  = docs.indexWhere((d) => d.id == user.uid);
      final rankStr = idx == -1 ? '>100' : '#${idx + 1}';
      final top = docs.take(5).map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': data['displayName'] ?? 'User',
          'xp': (data['xp'] ?? 0) as int,
          'photoUrl': data['photoUrl'],
        };
      }).toList();
      return {'rank': rankStr, 'total': docs.length, 'top': top};
    } catch (_) {
      return {'rank': '—', 'total': 0, 'top': <Map>[]};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppStyle.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🌍 Global Ranking',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: _fetch(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ));
            }
            final data = snap.data ?? {'rank': '—', 'total': 0, 'top': <Map>[]};
            final rankStr = data['rank'] as String;
            final total   = data['total'] as int;
            final top     = data['top'] as List;
            const medals  = ['🥇', '🥈', '🥉'];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Your rank banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.primary.withValues(alpha: 0.05),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Text('🏆', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Your Global Rank', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text(rankStr, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  ]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${user.xp} XP', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                    if (total > 0)
                      Text('out of $total users', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ]),
                ]),
              ),
              if (top.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Top Players', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...top.asMap().entries.map((e) {
                  final i  = e.key;
                  final u  = e.value as Map;
                  final isMe = u['id'] == user.uid;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isMe ? AppColors.primary.withValues(alpha: 0.4) : AppColors.stroke),
                    ),
                    child: Row(children: [
                      SizedBox(width: 24, child: Text(i < 3 ? medals[i] : '${i + 1}',
                          style: const TextStyle(fontSize: 14))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(u['name'] ?? 'User',
                          style: TextStyle(
                            color: isMe ? AppColors.primaryLight : AppColors.textPrimary,
                            fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ))),
                      Text('${u['xp']} XP', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace')),
                    ]),
                  );
                }),
              ],
            ]);
          },
        ),
      ]),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// rank hero card
// ────────────────────────────────────────────────────────────────────────────
class _RankHeroCard extends StatelessWidget {
  final AppUser user;
  const _RankHeroCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final rank = RankSystem.forXp(user.xp);
    final col = Color(rank['zoneColor'] as int);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [col.withValues(alpha: 0.25), AppColors.card],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppStyle.cardRadius),
        border: Border.all(color: col.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: col.withValues(alpha: 0.18), blurRadius: 24)],
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: col.withValues(alpha: 0.3),
          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) ? getAvatarProvider(user.photoUrl) : null,
          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
              ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white))
              : null,
        ),
        const SizedBox(height: 12),
        Text(user.displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 5),
        // Rank badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: col.withValues(alpha: 0.5)),
          ),
          child: Text(
            '${rank['emoji']} ${rank['title']} · ${rank['zone']}',
            style: TextStyle(color: col, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        const SizedBox(height: 4),
        Text(rank['sub'] as String,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final List<Color> colors;
  const _StatCard({required this.emoji, required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(AppStyle.cardRadius),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// XP progress bar to next rank
// ────────────────────────────────────────────────────────────────────────────
class _XpBar extends StatelessWidget {
  final AppUser user;
  const _XpBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final nextXp  = RankSystem.nextRankXp(user.xp);
    final progress = RankSystem.progressToNext(user.xp);
    final rank = RankSystem.forXp(user.xp);
    final col  = Color(rank['zoneColor'] as int);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppStyle.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('⚡ XP Progress',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const Spacer(),
          Text('${user.xp} XP',
              style: TextStyle(color: col, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 4),
        Text(nextXp != null ? 'Next rank at $nextXp XP · ${nextXp - user.xp} XP to go'
            : '👑 You are at the highest rank!',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v, minHeight: 14,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(col),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${(progress * 100).toInt()}% to next rank',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          if (nextXp != null)
            Text('$nextXp XP',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 14),
        Container(
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
           child: Row(children: [
             Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 16),
             const SizedBox(width: 8),
             Expanded(child: Text("XP is earned linearly: 1 XP for every 1 minute of active focus time. Learn new skills and reach new XP goals to unlock Cosmic ranks.", style: TextStyle(color: AppColors.textSecondary, fontSize: 11))),
           ])
        ),
      ]),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Daily target card (Issue 11)
// ────────────────────────────────────────────────────────────────────────────
class _DailyTargetCard extends StatelessWidget {
  final AppUser user;
  const _DailyTargetCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final done    = user.todayFocusSec ~/ 60;
    final target  = user.dailyTargetMin;
    final progress = user.dailyTargetProgress;
    final achieved = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: achieved
              ? [Color(0xFF065F46), Color(0xFF047857)]
              : [AppColors.card, AppColors.card],
        ),
        borderRadius: BorderRadius.circular(AppStyle.cardRadius),
        border: Border.all(
            color: achieved ? Color(0xFF34D399).withValues(alpha: 0.5) : AppColors.stroke),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(achieved ? '🎉' : '🎯',
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Daily Focus Target',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(achieved
                  ? 'Target achieved today! 🏆'
                  : '${done}m done · ${target}m goal',
                  style: TextStyle(
                      fontSize: 12,
                      color: achieved ? Color(0xFF34D399) : AppColors.textSecondary)),
            ]),
          ),
          // Change target button
          GestureDetector(
            onTap: () => _showTargetPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Text('Edit', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v, minHeight: 12,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(achieved ? Color(0xFF34D399) : AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('Today: ${user.formattedTodayFocus}',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
    );
  }

  void _showTargetPicker(BuildContext context) {
    int selected = context.read<AppProvider>().user?.dailyTargetMin ?? 60;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎯 Daily Focus Target',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [15, 25, 30, 45, 60, 90, 120].map((m) {
              final sel = selected == m;
              return GestureDetector(
                onTap: () => setSt(() => selected = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.stroke, width: sel ? 1.5 : 1),
                  ),
                  child: Text('${m}m',
                      style: TextStyle(color: sel ? AppColors.primaryLight : AppColors.textSecondary,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                ),
              );
            }).toList()),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<AppProvider>().setDailyTarget(selected);
                  Navigator.pop(context);
                },
                child: Text('Set $selected min daily target'),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// COSMIC JOURNEY — visual rank ladder (lowest → highest, top → bottom)
// ────────────────────────────────────────────────────────────────────────────
class _CosmicJourney extends StatelessWidget {
  const _CosmicJourney();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().user;
    final currentXp = user?.xp ?? 0;
    final currentRank = RankSystem.forXp(currentXp);

    // Zone dividers shown above their first rank
    const zoneOrder = ['Earth', 'Sky', 'Stratosphere', 'Space', 'Stars', 'Cosmos', 'Multiverse'];
    final zoneEmojis = {'Earth': '🌍', 'Sky': '🌤️', 'Stratosphere': '🌩️', 'Space': '🪐', 'Stars': '✨', 'Cosmos': '🌌', 'Multiverse': '🌀'};
    final zoneGradients = {
      'Earth':         [Color(0xFF14532D), Color(0xFF15803D)],
      'Sky':           [Color(0xFF1E3A5F), Color(0xFF1D4ED8)],
      'Stratosphere':  [Color(0xFF1E1B4B), Color(0xFF4338CA)],
      'Space':         [Color(0xFF1A0A2E), Color(0xFF6D28D9)],
      'Stars':         [Color(0xFF1F0A0A), Color(0xFFB45309)],
      'Cosmos':        [Color(0xFF2E1065), Color(0xFFC026D3)],
      'Multiverse':    [Color(0xFF000000), Color(0xFF9D174D)],
    };

    // Build rank list lowest→highest (Issue: was reversed before)
    final rankList = List<Map<String, dynamic>>.from(RankSystem.ranks);
    String? lastZone;

    final widgets = <Widget>[];

    for (int i = 0; i < rankList.length; i++) {
      final rank   = rankList[i];
      final zone   = rank['zone'] as String;
      final rankXp = rank['minXp'] as int;
      final color  = Color(rank['zoneColor'] as int);
      final isCurrent  = rank['title'] == currentRank['title'];
      final isUnlocked = currentXp >= rankXp;
      final isLast = i == rankList.length - 1;

      final currentRankIdx = rankList.indexWhere((r) => r['title'] == currentRank['title']);
      final isBlurred = i > currentRankIdx + 3;

      // Zone header when zone changes
      if (zone != lastZone) {
        lastZone = zone;
        final gr = zoneGradients[zone]!;
        Widget headerNode = Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0.0 : 10.0, bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gr),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Text(zoneEmojis[zone] ?? '🌐', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(zone.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.5)),
              const Spacer(),
              ...zoneOrder.take(zoneOrder.indexOf(zone) + 1).map((z) =>
                  Container(width: 6, height: 6, margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), shape: BoxShape.circle))),
            ]),
          ),
        );
        widgets.add(isBlurred 
            ? ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5), child: Opacity(opacity: 0.4, child: headerNode))
            : headerNode);
      }

      Widget rowContent = IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Vertical connector line + dot
          SizedBox(
              width: 40,
              child: Column(children: [
                Container(width: 2, height: i == 0 ? 12 : 0, color: Colors.transparent),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked ? color : AppColors.surfaceLight,
                    border: Border.all(color: isCurrent ? color : AppColors.stroke, width: isCurrent ? 2.5 : 1),
                    boxShadow: isCurrent ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)] : null,
                  ),
                  child: Center(
                    child: Text(rank['emoji'] as String,
                        style: TextStyle(fontSize: 14, color: isUnlocked ? null : Color(0xFF6B7280))),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.stroke)),
              ]),
            ),
            const SizedBox(width: 10),
            // Rank card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrent ? color.withValues(alpha: 0.15) : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isCurrent ? color : AppColors.stroke, width: isCurrent ? 1.5 : 1),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(rank['title'] as String,
                            style: TextStyle(
                                color: isCurrent ? Colors.white : isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13)),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                            child: Text('YOU', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                      Text(rankXp == 0 ? 'Starting rank' : '$rankXp XP',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      if (isCurrent) ...[
                        const SizedBox(height: 4),
                        Text('"${rank['sub']}"',
                            style: TextStyle(fontSize: 10, color: color, fontStyle: FontStyle.italic)),
                      ],
                    ]),
                  ),
                  // Status icon
                  if (isCurrent)
                    _SparkleIcon(color: color)
                  else if (isUnlocked)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18)
                  else
                    Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 16),
                ]),
              ),
            ),
          ]),
      );
      widgets.add(isBlurred 
          ? ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5), child: Opacity(opacity: 0.4, child: rowContent))
          : rowContent);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('✨ Rank Journey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const Spacer(),
          Text('1 XP = 1 min focus', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('✨ The XP System', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Your progression is powered by Focus!\n\n'
                  '• Every 1 minute of successful focusing grants you 1 XP.\n'
                  '• Reaching new XP thresholds ranks you up automatically, evolving your cosmic avatar and demonstrating your focus history.\n'
                  '• Maximize Pomodoro sessions and use "Deep Focus" to rack up XP accurately over time!',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Understood', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            child: Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
          ),
        ]),
        const SizedBox(height: 16),
        ...widgets,
      ]),
    );
  }
}

/// Animated sparkle/star icon for the current rank
class _SparkleIcon extends StatefulWidget {
  final Color color;
  const _SparkleIcon({required this.color});
  @override
  State<_SparkleIcon> createState() => _SparkleIconState();
}

class _SparkleIconState extends State<_SparkleIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _scale = Tween(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: Icon(Icons.stars_rounded, color: widget.color, size: 22),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Study History Chart (Week / Month / All-Time)
// ────────────────────────────────────────────────────────────────────────────
class _StudyHistoryChart extends StatefulWidget {
  final AppUser user;
  const _StudyHistoryChart({required this.user});
  @override State<_StudyHistoryChart> createState() => _StudyHistoryChartState();
}

class _StudyHistoryChartState extends State<_StudyHistoryChart> {
  int _tab = 0; // 0=Week, 1=Month, 2=All Time

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppStyle.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊 Study History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),
          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _tb(0, 'Week'),
              _tb(1, 'Month'),
              _tb(2, 'All Time'),
            ]),
          ),
          const SizedBox(height: 24),
          _buildChart(),
        ],
      ),
    );
  }

  Widget _tb(int id, String txt) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _tab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _tab == id ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(txt, style: TextStyle(
          color: _tab == id ? AppColors.primaryLight : AppColors.textSecondary,
          fontSize: 12, fontWeight: _tab == id ? FontWeight.w700 : FontWeight.w500
        )),
      ),
    ),
  );

  Widget _buildChart() {
    final now = DateTime.now();
    final List<String> labels = [];
    final List<int> values = [];
    int maxVal = 1;

    if (_tab == 0) {
      // ── WEEK: 7 days starting from Saturday ──────────────────────────────
      // Dart weekday: Mon=1 .. Sat=6, Sun=7
      // Days since last Saturday: Sat→0, Sun→1, Mon→2 … Fri→6
      final daysSinceSat = (now.weekday % 7 + 1) % 7; // Sat=0,Sun=1,Mon=2…
      final weekStart = now.subtract(Duration(days: daysSinceSat));
      const dayLabels = ['Sa', 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr'];
      for (int i = 0; i < 7; i++) {
        final d = weekStart.add(Duration(days: i));
        final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        labels.add(dayLabels[i]);
        final min = (widget.user.history[key] ?? 0) ~/ 60;
        values.add(min);
        if (min > maxVal) maxVal = min;
      }

    } else if (_tab == 1) {
      // ── MONTH: calendar weeks of the current month (Up to 5) ──────────────
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final numWeeks = (daysInMonth / 7).ceil();
      for (int w = 0; w < numWeeks; w++) {
        final dayFrom = w * 7 + 1;
        final dayTo   = (w == numWeeks - 1) ? daysInMonth : dayFrom + 6;
        int sum = 0;
        for (int d = dayFrom; d <= dayTo; d++) {
          final date = DateTime(now.year, now.month, d);
          final key  = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
          sum += (widget.user.history[key] ?? 0) ~/ 60;
        }
        labels.add('W${w + 1}');
        values.add(sum);
        if (sum > maxVal) maxVal = sum;
      }

    } else {
      // ── ALL TIME: Current Year Jan → Dec ─────────────────────────────────
      const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      for (int m = 1; m <= 12; m++) {
        final target = DateTime(now.year, m, 1);
        final daysInM = DateTime(target.year, target.month + 1, 0).day;
        int sum = 0;
        for (int d = 1; d <= daysInM; d++) {
          final date = DateTime(target.year, target.month, d);
          final key  = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
          sum += (widget.user.history[key] ?? 0) ~/ 60;
        }
        labels.add(monthNames[m - 1]);
        values.add(sum);
        if (sum > maxVal) maxVal = sum;
      }
    }

    // Bar width: narrower for 12-month view so all fit
    final barWidth = _tab == 2 ? 20.0 : (_tab == 1 ? 44.0 : 28.0);

    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(values.length, (i) {
          final val = values[i];
          final p   = val / maxVal;
          final isToday = (_tab == 0 && i == (now.weekday % 7 + 1) % 7);
          final barColor = isToday ? AppColors.primaryLight : AppColors.primary;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (val > 0)
                Text('${val}m', style: TextStyle(
                  fontSize: _tab == 2 ? 7 : 9,
                  color: AppColors.textMuted,
                )),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                width: barWidth,
                height: p == 0 ? 4 : (p * 80).clamp(4.0, 80.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [barColor, barColor.withValues(alpha: 0.6)],
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isToday
                      ? [BoxShadow(color: barColor.withValues(alpha: 0.45), blurRadius: 8)]
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(labels[i], style: TextStyle(
                fontSize: _tab == 2 ? 8 : 10,
                fontWeight: FontWeight.w600,
                color: isToday ? AppColors.primaryLight : AppColors.textSecondary,
              )),
            ],
          );
        }),
      ),
    );
  }
}

