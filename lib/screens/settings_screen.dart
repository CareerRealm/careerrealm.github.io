import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_background.dart';
import 'auth_screen.dart';
import 'theme_settings_screen.dart';

/// Shared preset avatar list used across the settings and profile card.
const List<Map<String, String>> kAvatarOptions = [
  // ── Custom Local Assets ───────────────────────────────────────────────────
  {'label': 'Allah',     'url': 'assets/images/allah.jpg'},
  {'label': 'Anonymous', 'url': 'assets/images/anony.jpg'},
  {'label': 'Anonymous 2','url': 'assets/images/anonymous.png'},
  {'label': 'Car',       'url': 'assets/images/car.png'},
  {'label': 'Clown',     'url': 'assets/images/clown.avif'},
  {'label': 'Done',      'url': 'assets/images/done.jpg'},
  {'label': 'Hacker',    'url': 'assets/images/hacker.jpg'},
  {'label': 'Phantom',   'url': 'assets/images/Phantom.png'},
  {'label': 'Programmer','url': 'assets/images/programmer.png'},
  {'label': 'Sad',       'url': 'assets/images/sad.avif'},
  {'label': 'Sad 2',     'url': 'assets/images/sad1.jpg'},
  {'label': 'Student',   'url': 'assets/images/student.jpg'},
  // ── Fun Emoji ─────────────────────────────────────────────────────────────
  {'label': 'Clown',   'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=clown&backgroundColor=ffdfbf'},
  {'label': 'Ninja',   'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=ninja&backgroundColor=1d1d2e'},
  {'label': 'Alien',   'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=alien&backgroundColor=b6e3f4'},
  {'label': 'Devil',   'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=devil&backgroundColor=ff7c7c'},
  {'label': 'Angel',   'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=angel&backgroundColor=d1d4f9'},
  {'label': 'Zombie',  'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=zombie&backgroundColor=c0aede'},
  {'label': 'Pirate',  'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=pirate&backgroundColor=ffdfbf'},
  {'label': 'Wizard',  'url': 'https://api.dicebear.com/7.x/fun-emoji/png?seed=wizard&backgroundColor=c0aede'},
  // ── Bottts (Robots / Hackers) ───────────────────────────────────────────
  {'label': 'Hacker',  'url': 'https://api.dicebear.com/7.x/bottts/png?seed=hacker&backgroundColor=1d1d2e'},
  {'label': 'Robot',   'url': 'https://api.dicebear.com/7.x/bottts/png?seed=cyborg&backgroundColor=b6e3f4'},
  {'label': 'Android', 'url': 'https://api.dicebear.com/7.x/bottts/png?seed=android&backgroundColor=d1d4f9'},
  {'label': 'Glitch',  'url': 'https://api.dicebear.com/7.x/bottts/png?seed=glitch&backgroundColor=ff7c7c'},
  // ── Adventurer (Heroes & Characters) ───────────────────────────────────
  {'label': 'Hero',    'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Hero&backgroundColor=ffd700&skinColor=f2d3b1'},
  {'label': 'Warrior', 'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Warrior&backgroundColor=b6e3f4&skinColor=ae5d29'},
  {'label': 'Mage',    'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Mage&backgroundColor=c0aede&skinColor=f2d3b1'},
  {'label': 'Ranger',  'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Ranger&backgroundColor=b5ead7&skinColor=ae5d29'},
  {'label': 'Pirate',  'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Pirate&backgroundColor=ffdfbf&skinColor=f2d3b1'},
  {'label': 'Rogue',   'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Rogue&backgroundColor=1d1d2e&skinColor=f2d3b1'},
  // ── Micah (Artistic Portraits) ─────────────────────────────────────────
  {'label': 'Artist',  'url': 'https://api.dicebear.com/7.x/micah/png?seed=Artist&backgroundColor=ffdfbf'},
  {'label': 'Scholar', 'url': 'https://api.dicebear.com/7.x/micah/png?seed=Scholar&backgroundColor=d1d4f9'},
  {'label': 'Chef',    'url': 'https://api.dicebear.com/7.x/micah/png?seed=Chef&backgroundColor=ffd700'},
  {'label': 'Gamer',   'url': 'https://api.dicebear.com/7.x/micah/png?seed=Gamer&backgroundColor=1d1d2e'},
  // ── Pixel Art ──────────────────────────────────────────────────────────
  {'label': 'Pixel',   'url': 'https://api.dicebear.com/7.x/pixel-art/png?seed=pixel&backgroundColor=b6e3f4'},
  {'label': 'Knight',  'url': 'https://api.dicebear.com/7.x/pixel-art/png?seed=knight&backgroundColor=c0aede'},
  {'label': 'Elf',     'url': 'https://api.dicebear.com/7.x/pixel-art/png?seed=elf&backgroundColor=b5ead7'},
  {'label': 'Samurai', 'url': 'https://api.dicebear.com/7.x/pixel-art/png?seed=samurai&backgroundColor=ff7c7c'},
  // ── Big Smile (Fun / Casual) ───────────────────────────────────────────
  {'label': 'Happy',   'url': 'https://api.dicebear.com/7.x/big-smile/png?seed=happy&backgroundColor=ffdfbf'},
  {'label': 'Cool',    'url': 'https://api.dicebear.com/7.x/big-smile/png?seed=cool&backgroundColor=b6e3f4'},
  {'label': 'Ghost',   'url': 'https://api.dicebear.com/7.x/big-smile/png?seed=ghost&backgroundColor=d1d4f9'},
  {'label': 'Sporty',  'url': 'https://api.dicebear.com/7.x/big-smile/png?seed=sporty&backgroundColor=b5ead7'},
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch both providers at the top level so the gradient background, the
    // ThemeBackground particle style, and all AppColors statics are instantly
    // updated whenever the user taps a theme tile — without leaving Settings.
    final tp = context.watch<ThemeProvider>();
    AppColors.applyTheme(tp.theme);
    AppStyle.applyLook(tp.look);
    final user = context.watch<AppProvider>().user;
    return Scaffold(
      body: ThemeBackground(
        style: tp.theme.bg,
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.bgGradient),
          child: SafeArea(
            child: Column(children: [

              _header(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    if (user != null) _ProfileCard(user: user),
                    const SizedBox(height: 16),
                    _Section(title: '🎨 Appearance', children: [
                      _Tile(
                        icon: Icons.palette_rounded, 
                        label: 'App Appearance & Timer Faces', 
                        sub: 'Themes, timer rings, and colors', 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsScreen())),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: '⚙️ Preferences', children: [
                      _SwitchTile(
                        icon: Icons.coffee_rounded, label: 'Auto-start Breaks', 
                        sub: 'Automatically start breaks when focus time ends',
                        value: tp.autoStartBreaks, onChanged: (v) => tp.toggleAutoStartBreaks(),
                      ),
                      _SwitchTile(
                        icon: Icons.shield_rounded, label: 'Strict Focus Mode', 
                        sub: 'Locks the app to prevent distractions while a timer is active',
                        value: tp.strictFocusMode, onChanged: (v) => tp.toggleStrictFocusMode(),
                      ),
                      _SwitchTile(
                        icon: Icons.bolt_rounded, label: 'Auto-start Focus', 
                        sub: 'Automatically resume focus when break ends',
                        value: tp.autoStartFocus, onChanged: (v) => tp.toggleAutoStartFocus(),
                      ),
                      _SwitchTile(
                        icon: Icons.star_rounded, label: 'Show Rank in Rooms', 
                        sub: 'Display your experience rank to others',
                        value: tp.showRank, onChanged: (v) => tp.toggleShowRank(),
                      ),
                      _SwitchTile(
                        icon: Icons.notifications_active_rounded, label: 'App Notifications', 
                        sub: 'Allow background alerts and session reminders',
                        value: tp.notificationsEnabled, onChanged: (v) async {
                          if (v) {
                            final granted = await NotificationService().requestPermission();
                            if (granted) tp.toggleNotifications();
                          } else {
                            tp.toggleNotifications();
                          }
                        },
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: '👤 Account', children: [
                      _Tile(icon: Icons.badge_outlined, label: 'Change Name', sub: user?.displayName ?? '', onTap: () => _showEditName(context, user)),
                      if (!(user?.isGuest ?? true))
                        _Tile(icon: Icons.face_rounded, label: 'Choose Avatar', sub: 'Pick from preset avatars', onTap: () => _pickAvatar(context, user)),
                      _Tile(
                        icon: Icons.star_outline_rounded, label: 'Career Realm Pro', sub: 'Unlock premium features',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pro coming soon! 🚀'))),
                        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(6)),
                          child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                      ),
                      _Tile(icon: Icons.logout_rounded, label: 'Sign Out', sub: 'Return to login screen', iconColor: Colors.red,
                        onTap: () async {
                          await context.read<AppProvider>().signOut();
                          if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
                        }),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: '📱 About', children: [
                      _Tile(icon: Icons.info_outline_rounded, label: 'Version', sub: '1.0.0 — Career Realm', onTap: () {}),
                      _Tile(icon: Icons.shield_outlined, label: 'Privacy Policy', sub: 'How we handle your data', onTap: () {}),
                    ]),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ]),
          ),
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
          const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      );

  // Fix issue 5: dialog close bug — capture context before async gap
  void _showEditName(BuildContext context, AppUser? user) {
    if (user == null) return;
    final ctrl = TextEditingController(text: user.displayName);
    final nav  = Navigator.of(context); // capture before async
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Change Name',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
              labelText: 'Your name',
              prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted)),
        ),
        actions: [
          TextButton(
              onPressed: () => nav.pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              nav.pop(); // close dialog immediately — don't wait for async
              if (newName.isEmpty || newName == user.displayName) return;
              await AuthService().updateDisplayName(user.uid, newName);
              if (context.mounted) {
                final updated = await AuthService().fetchUser(user.uid);
                if (updated != null && context.mounted) {
                  context.read<AppProvider>().setUser(updated);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Name updated to "$newName" ✅')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context, AppUser? user) async {
    if (user == null || user.isGuest) return;
    final selected = await showAvatarSheet(context, user.photoUrl);
    if (selected == null || !context.mounted) return;
    final success = await context.read<AppProvider>().updateAvatar(selected);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Avatar updated! ✅' : 'Failed to update. Check connection.'),
      ));
    }
  }
}

/// Top-level avatar picker sheet so both _SettingsScreenState and _ProfileCard can use it.
Future<String?> showAvatarSheet(BuildContext context, String? currentUrl) =>
  showModalBottomSheet<String>(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65, maxChildSize: 0.92, minChildSize: 0.4,
      expand: false,
      builder: (ctx, scroll) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.stroke, borderRadius: BorderRadius.circular(2))),
          const Text('🧑‍🚀 Choose Your Avatar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('${kAvatarOptions.length} characters available',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              controller: scroll,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 14,
                childAspectRatio: 0.78),
              itemCount: kAvatarOptions.length,
              itemBuilder: (_, i) {
                final av = kAvatarOptions[i];
                final url = av['url']!;
                final label = av['label']!;
                final isSel = currentUrl == url;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, url),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 62, height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.stroke,
                            width: isSel ? 3 : 1.5),
                          boxShadow: isSel ? [BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 10)] : null,
                          image: DecorationImage(image: getAvatarProvider(url), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                          color: isSel ? AppColors.primaryLight : AppColors.textMuted)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    ),
  );

// ── Timer Face Section ────────────────────────────────────────────────────────
// ── Profile card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final AppUser user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.card],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          // Avatar with edit badge
          MouseRegion(
            cursor: user.isGuest ? MouseCursor.defer : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _showAvatarOptions(context),
              child: Stack(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: user.photoUrl != null ? getAvatarProvider(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white))
                      : null,
                ),
                if (!user.isGuest)
                  Positioned(right: 0, bottom: 0, child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 1.5)),
                    child: const Icon(Icons.edit, size: 10, color: Colors.white),
                  )),
              ]),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(user.rank,
                  style: TextStyle(fontSize: 12, color: AppColors.primaryLight)),
              if (user.email != null)
                Text(user.email!,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
          if (user.isGuest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)),
              child: Text('GUEST',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ]),
      );

  Future<void> _showAvatarOptions(BuildContext context) async {
    if (user.isGuest) return;
    final selected = await showAvatarSheet(context, user.photoUrl);
    if (selected == null || !context.mounted) return;
    final success = await context.read<AppProvider>().updateAvatar(selected);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Avatar updated! ✅' : 'Failed to update. Check connection.'),
      ));
    }
  }
}

// ── Generic section / tile ────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary, letterSpacing: 0.5)),
      ),
      Container(
        decoration: AppStyle.cardDecoration(),
        child: Column(
          children: children.asMap().entries.map((e) => Column(children: [
            e.value,
            if (e.key < children.length - 1)
              Divider(height: 1, indent: 56, color: AppColors.stroke),
          ])).toList(),
        ),
      ),
    ]);
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;
  const _Tile({required this.icon, required this.label, required this.sub, required this.onTap, this.iconColor, this.trailing});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor ?? AppColors.primaryLight, size: 20),
        ),
        title: Text(label,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 14)),
        subtitle: Text(sub,
            style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins', fontSize: 12)),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  
  const _SwitchTile({
    required this.icon, required this.label, required this.sub,
    required this.value, required this.onChanged
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: value,
    onChanged: onChanged,
    activeThumbColor: AppColors.primaryLight,
    activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
    inactiveTrackColor: AppColors.surfaceLight,
    inactiveThumbColor: AppColors.textMuted,
    secondary: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppColors.primaryLight, size: 20),
    ),
    title: Text(label,
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 14)),
    subtitle: Text(sub,
        style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins', fontSize: 12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}
