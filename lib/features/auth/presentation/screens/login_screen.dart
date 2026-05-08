// lib/features/auth/presentation/screens/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';
import '../../../../core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Entrance animation
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // Auth state listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthNotifier>().addListener(_onAuthStateChanged);
    });
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final state = context.read<AuthNotifier>().state;
    if (state is AuthError) _showErrorSnackBar(state.message);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthNotifier>().state is AuthLoading;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AmbientBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      _buildLogo(),
                      const SizedBox(height: 32),
                      _buildBranding(),
                      const Spacer(flex: 2),
                      _buildCard(isLoading),
                      const Spacer(flex: 3),
                      _buildFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo ────────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
    );
  }

  // ── Branding ─────────────────────────────────────────────────────────────────

  Widget _buildBranding() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'QuickTask',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Colors.white, // masked by shader
              letterSpacing: -2,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'The silent partner in your daily workflow.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ── Sign-in Card ─────────────────────────────────────────────────────────────

  Widget _buildCard(bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to continue your workflow.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          GoogleSignInButton(
            isLoading: isLoading,
            onPressed: () => context.read<AuthNotifier>().signInWithGoogle(),
          ),
          const SizedBox(height: 28),
          _buildDivider(),
          const SizedBox(height: 28),
          _SocialProofRow(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.cardBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Trusted by professionals',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.cardBorder, thickness: 1)),
      ],
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FooterLink(label: 'Privacy Policy'),
            Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.textHint,
                shape: BoxShape.circle,
              ),
            ),
            _FooterLink(label: 'Terms of Service'),
          ],
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Soft ambient gradient blobs in the background.
class _AmbientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -150,
          right: -100,
          child: _Blob(color: AppColors.primaryLight, size: 400, alpha: 0.15),
        ),
        Positioned(
          bottom: -100,
          left: -120,
          child: _Blob(color: AppColors.accent, size: 350, alpha: 0.15),
        ),
        Positioned(
          top: 200,
          left: -80,
          child: _Blob(color: AppColors.primary, size: 250, alpha: 0.10),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double alpha;
  const _Blob({required this.color, required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), Colors.transparent],
        ),
      ),
    );
  }
}

/// Avatars + user count to reinforce social proof.
class _SocialProofRow extends StatelessWidget {
  final _avatarColors = const [
    Color(0xFF6C63FF),
    Color(0xFF43B89C),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];
  final _initials = const ['A', 'M', 'J', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 4 * 24.0 + 8, // overlap math
          height: 28,
          child: Stack(
            children: List.generate(4, (i) {
              return Positioned(
                left: i * 20.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _avatarColors[i],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            children: [
              TextSpan(
                text: '2,000+ ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(text: 'professionals trust us'),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* TODO: open URL */},
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.textHint,
        ),
      ),
    );
  }
}
