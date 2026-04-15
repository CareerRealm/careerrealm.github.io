
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _guestCtrl = TextEditingController();
  bool _obscure = true;
  bool _showGuest = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _guestCtrl.dispose();
    super.dispose();
  }

  void _navigate() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Future<void> _googleSignIn() async {
    final ok = await context.read<AppProvider>().signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      _navigate();
    } else {
      final err = context.read<AppProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Google sign-in failed. Please try again.')),
      );
    }
  }

  Future<void> _emailSignIn() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')));
      return;
    }
    final ok = await context
        .read<AppProvider>()
        .signInWithEmail(_emailCtrl.text, _passCtrl.text);
    if (ok && mounted) _navigate();
    if (!ok && mounted) {
      final err = context.read<AppProvider>().error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? 'Sign in failed')));
    }
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Name & email required. Password ≥6 chars')));
      return;
    }
    final ok = await context
        .read<AppProvider>()
        .createAccount(_nameCtrl.text, _emailCtrl.text, _passCtrl.text);
    if (ok && mounted) _navigate();
    if (!ok && mounted) {
      final err = context.read<AppProvider>().error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? 'Registration failed')));
    }
  }

  Future<void> _guest() async {
    final name = _guestCtrl.text.trim();
    final ok = await context.read<AppProvider>().continueAsGuest(name);
    if (ok && mounted) {
      _navigate();
    } else if (mounted) {
      final err = context.read<AppProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Could not continue as guest')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 36),
                // Logo
                Hero(
                  tag: 'logo',
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/Career Realm.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Career Realm',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gamified Focus & Validated Experience ✨',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 36),

                // Google button — available on all platforms
                _GlassCard(
                  child: Column(
                    children: [
                      _GoogleSignInButton(
                        onTap: provider.isLoading ? null : _googleSignIn,
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Divider(color: AppColors.stroke)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        Expanded(child: Divider(color: AppColors.stroke)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Email / Password tab card (always shown on all platforms)
                _GlassCard(
                  child: Column(
                    children: [
                      // Tab bar: Sign In / Create
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tab,
                          indicator: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                          tabs: const [
                            Tab(text: 'Sign In'),
                            Tab(text: 'Create Account'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        height: 340,
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            _buildSignInForm(),
                            _buildRegisterForm(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 16),

                // Guest mode
                _GlassCard(
                  child: _showGuest
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your display name (optional)',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _guestCtrl,
                              style: const TextStyle(color: Colors.white),
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'Leave blank for a random name',
                                prefixIcon: Icon(Icons.person_outline,
                                    color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: provider.isLoading ? null : _guest,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text('Continue as Guest'),
                              ),
                            ),
                          ],
                        )
                      : TextButton.icon(
                          onPressed: () => setState(() => _showGuest = true),
                          icon: const Text('👤'),
                          label: const Text('Continue as Guest'),
                        ),
                ),

                if (provider.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _emailSignIn,
            child: const Text('Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Display Name',
            prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _register,
            child: const Text('Create Account'),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: child,
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: _pressed
                ? Color(0xFFE8E8E8)
                : _hovered
                    ? Color(0xFFF5F5F5)
                    : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Color(0xFFDADCE0), width: 1.5),
            boxShadow: _hovered && !_pressed
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Color(0xFF3C4043),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



