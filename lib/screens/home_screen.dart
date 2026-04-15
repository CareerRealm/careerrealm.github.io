import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../services/room_service.dart';
import '../theme/app_theme.dart';
import 'room_screen.dart';
import 'settings_screen.dart';
import '../widgets/knowledge_architect_chat.dart';
import '../widgets/skill_tree_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    // Watch theme so AppColors static values are fresh whenever theme changes.
    final tp = context.watch<ThemeProvider>();
    AppColors.applyTheme(tp.theme);
    AppStyle.applyLook(tp.look);

    final user = context.watch<AppProvider>().user;
    final currentRoom = context.watch<AppProvider>().currentRoomId;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    final isGuest = user?.isGuest ?? true;
    
    Widget body = IndexedStack(
      index: _currentIndex,
      children: [
        _CareerRealmTab(user: user),
        _FocusRealmTab(user: user, currentRoom: currentRoom),
        const _CareerCompanionTab(),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: isDesktop 
              ? Row(
                  children: [
                    _buildNavRail(isGuest),
                    Expanded(child: body),
                  ],
                )
              : Column(
                  children: [
                    _buildMobileHeader(user),
                    Expanded(child: body),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(isGuest),
    );
  }

  Widget _buildNavRail(bool isGuest) {
    return NavigationRail(
      backgroundColor: AppColors.surfaceLight,
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      selectedIconTheme: IconThemeData(color: AppColors.primaryLight),
      unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
      selectedLabelTextStyle: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: TextStyle(color: AppColors.textMuted),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.rocket_launch_outlined), selectedIcon: Icon(Icons.rocket_launch_rounded), label: Text('Career')),
        NavigationRailDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: Text('Focus')),
        NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: Text('Companion')),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: IconButton(
              icon: Icon(Icons.settings, color: AppColors.textSecondary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isGuest) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.primaryLight);
          }
          return IconThemeData(color: AppColors.textMuted);
        }),
      ),
      child: NavigationBar(
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: Colors.transparent,
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.rocket_launch_outlined), selectedIcon: Icon(Icons.rocket_launch_rounded), label: 'Career'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Focus'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Companion'),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(dynamic user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              backgroundImage: user?.photoUrl != null ? getAvatarProvider(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? Text(
                      (user?.displayName.isNotEmpty == true) ? user!.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Career Realm ✦', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                Text(
                  user?.displayName ?? 'Welcome!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.primaryLight),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Career Realm (Dashboard)
// ─────────────────────────────────────────────────────────────────────────────
class _CareerRealmTab extends StatelessWidget {
  final dynamic user;
  const _CareerRealmTab({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null || user.isGuest) {
      return const _LockedTabOverlay(
        title: 'Dashboard', 
        description: 'Track your career progression, EXP, and skill tree.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: AppStyle.heading.copyWith(fontSize: 28)),
          const SizedBox(height: 20),
          _StatsPreview(user: user),
          const SizedBox(height: 12),
          SkillTreeMap(user: user),
          const SizedBox(height: 24),
          _GatewayBanner(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: Focus Realm (The Timer)
// ─────────────────────────────────────────────────────────────────────────────
class _FocusRealmTab extends StatefulWidget {
  final dynamic user;
  final String? currentRoom;
  const _FocusRealmTab({required this.user, required this.currentRoom});

  @override
  State<_FocusRealmTab> createState() => _FocusRealmTabState();
}

class _FocusRealmTabState extends State<_FocusRealmTab> {
  final _roomIdCtrl = TextEditingController();
  final _roomService = RoomService();
  bool _loading = false;
  int _selectedMinutes = 25;

  @override
  void dispose() {
    _roomIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (widget.user == null) return;
    setState(() => _loading = true);
    try {
      final id = await _roomService.createRoom(
        widget.user.displayName,
        focusMinutes: _selectedMinutes,
      );
      if (!mounted) return;
      context.read<AppProvider>().setCurrentRoom(id);
      Navigator.push(context, MaterialPageRoute(builder: (_) => RoomScreen(roomId: id)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom() async {
    final id = _roomIdCtrl.text.trim().toUpperCase();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a room ID first')));
      return;
    }
    setState(() => _loading = true);
    try {
      final exists = await _roomService.roomExists(id);
      if (!exists) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room not found!')));
        return;
      }
      if (!mounted) return;
      if (widget.user != null) await _roomService.joinRoom(id, widget.user.displayName);
      if (!mounted) return;
      context.read<AppProvider>().setCurrentRoom(id);
      Navigator.push(context, MaterialPageRoute(builder: (_) => RoomScreen(roomId: id)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text('Focus Realm', style: AppStyle.heading.copyWith(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Enter the zone. Generate HP & AXP by sustaining your flow state.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),

          if (widget.currentRoom != null)
            _RejoinBanner(
              roomId: widget.currentRoom!,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomScreen(roomId: widget.currentRoom!))),
            ),
          if (widget.currentRoom != null) const SizedBox(height: 8),

          _StartSessionCard(
            loading: _loading,
            selectedMinutes: _selectedMinutes,
            onPreset: (m) => setState(() => _selectedMinutes = m),
            onCreateRoom: _createRoom,
          ),
          const SizedBox(height: 16),
          _JoinRoomCard(
            controller: _roomIdCtrl,
            loading: _loading,
            onJoin: _joinRoom,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomScreen(roomId: 'OFFLINE'))),
              icon: const Icon(Icons.wifi_off_rounded),
              label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Offline Room')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: AppColors.stroke),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: Career Companion
// ─────────────────────────────────────────────────────────────────────────────
class _CareerCompanionTab extends StatelessWidget {
  const _CareerCompanionTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().user;
    if (user == null || user.isGuest) {
      return const _LockedTabOverlay(
        title: 'Career Companion', 
        description: 'Get personalized mentoring and resume feedback from AI.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Career Companion', style: AppStyle.heading.copyWith(fontSize: 28)),
          const SizedBox(height: 8),
          Text('Your personal LLM mentor linked to your documents via RAG.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          const Expanded(child: KnowledgeArchitectChat()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _LockedTabOverlay extends StatelessWidget {
  final String title;
  final String description;
  const _LockedTabOverlay({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 28),
              const SizedBox(width: 12),
              Text(title, style: AppStyle.heading.copyWith(fontSize: 28, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_person_outlined, size: 64, color: AppColors.primaryLight.withValues(alpha: 0.6)),
                  const SizedBox(height: 20),
                  const Text('Sign in to unlock', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('This feature requires an account to sync your progress.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                       context.read<AppProvider>().signOut();
                    },
                    style: AppStyle.elevatedButtonStyle(),
                    icon: const Icon(Icons.login),
                    label: const Text('Go to Sign In'),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _StatsPreview extends StatelessWidget {
  final dynamic user;
  const _StatsPreview({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Global Progression',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(user.rank, style: TextStyle(fontSize: 13, color: AppColors.primaryLight)),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(label: 'Cognitive HP', value: '${user.hp}/100', emoji: '❤️'),
              const SizedBox(width: 8),
              _StatChip(label: 'AXP (Academic)', value: '${user.axp}', emoji: '📚'),
              const SizedBox(width: 8),
              _StatChip(label: 'PXP (Career)', value: '${user.pxp}', emoji: '💼'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _StatChip({required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppStyle.chipRadius),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _RejoinBanner extends StatelessWidget {
  final String roomId;
  final VoidCallback onTap;
  const _RejoinBanner({required this.roomId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF047857)]),
          borderRadius: BorderRadius.circular(AppStyle.cardRadius),
          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('🟢', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Room', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('Tap to rejoin · $roomId', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF34D399), size: 16),
          ],
        ),
      ),
    );
  }
}

class _StartSessionCard extends StatelessWidget {
  final bool loading;
  final int selectedMinutes;
  final ValueChanged<int> onPreset;
  final VoidCallback onCreateRoom;
  const _StartSessionCard({required this.loading, required this.selectedMinutes, required this.onPreset, required this.onCreateRoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppStyle.cardDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2D1B69), Color(0xFF1A1A38)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        elevated: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(AppStyle.chipRadius)),
                child: const Text('⏱', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start a Session', style: AppStyle.heading),
                  Text('Create a focus room & invite others', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _TimerPreset(label: '25m', sub: 'Pomodoro', emoji: '🍅', selected: selectedMinutes == 25, onTap: () => onPreset(25)),
              const SizedBox(width: 8),
              _TimerPreset(label: '50m', sub: 'Deep Work', emoji: '💪', selected: selectedMinutes == 50, onTap: () => onPreset(50)),
              const SizedBox(width: 8),
              _TimerPreset(label: '90m', sub: 'Flow', emoji: '🌊', selected: selectedMinutes == 90, onTap: () => onPreset(90)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onCreateRoom,
              style: AppStyle.elevatedButtonStyle(),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch_rounded),
                        SizedBox(width: 8),
                        Text('Create Room', style: TextStyle(fontSize: 16)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerPreset extends StatelessWidget {
  final String label, sub, emoji;
  final bool selected;
  final VoidCallback onTap;
  const _TimerPreset({required this.label, required this.sub, required this.emoji, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppStyle.chipRadius),
            border: Border.all(color: selected ? AppColors.primary : AppColors.stroke, width: selected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: selected ? AppColors.primaryLight : Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(sub, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinRoomCard extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onJoin;
  const _JoinRoomCard({required this.controller, required this.loading, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyle.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔗  Join a Room', style: AppStyle.heading),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 2),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: const InputDecoration(hintText: 'ROOM ID', counterText: ''),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : onJoin,
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Join'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GatewayBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A0A3E), Color(0xFF2D1B69)]),
        borderRadius: BorderRadius.circular(AppStyle.cardRadius),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⭐ Career Verification Gateway', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Generate Proof-of-Skill AI Resumes • Recruiter Contact Filters', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PXP Gateway Opening Soon! 🚀'))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Unlock', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
