// lib/features/auth/presentation/screens/login_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';
import '../../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF080A12); // near black with blue tint
const _kCard = Color(0xFF0F1320); // slightly lighter dark card
const _kBorder = Color(0xFF1E2440); // subtle border
const _kPrimary = Color(0xFF6C63FF); // violet
const _kAccent = Color(0xFF3DD8C9); // teal
const _kGold = Color(0xFFF5C842); // gold highlight
const _kTextPrime = Color(0xFFF0F2FF); // almost white
const _kTextSecond = Color(0xFF7B82A8); // muted blue-gray
const _kTextHint = Color(0xFF3E4466); // very muted

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Entrance animation
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Continuous ambient orb float
  late final AnimationController _floatCtrl;

  // Button press scale
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _btnScale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();

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
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthNotifier>().state is AuthLoading;
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Animated ambient background ──────────────────────────────────
            _AnimatedOrbs(floatAnim: _floatCtrl, size: size),

            // ── Blur veil ────────────────────────────────────────────────────
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const ColoredBox(color: Colors.transparent),
            ),

            // ── Noise grain overlay ──────────────────────────────────────────
            Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: _NoisePainter()),
            ),

            // ── Main content ─────────────────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      height: size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),
                          _buildLogoWithRing(),
                          const SizedBox(height: 28),
                          _buildBranding(),
                          const Spacer(flex: 2),
                          _buildGlassCard(isLoading),
                          const Spacer(flex: 2),
                          _buildFooter(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogoWithRing() {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, child) {
        final t = _floatCtrl.value;
        return Transform.translate(
          offset: Offset(0, -4 + 8 * t),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _kPrimary.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.18),
                  blurRadius: 48,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Inner logo box
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _kBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.20),
                  blurRadius: 32,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  // ─── Branding ──────────────────────────────────────────────────────────────

  Widget _buildBranding() {
    return Column(
      children: [
        // Title with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFB8B0FF), Color(0xFF6C63FF), Color(0xFF3DD8C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            'QuickTask',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -2.0,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Tagline with accent dot
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _kAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Your silent productivity partner',
              style: TextStyle(
                fontSize: 14,
                color: _kTextSecond,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _kAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Glass Card ────────────────────────────────────────────────────────────

  Widget _buildGlassCard(bool isLoading) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1320).withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF1E2440).withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: -8,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: _kPrimary.withOpacity(0.06),
                blurRadius: 60,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrime,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in to continue your workflow',
                          style: TextStyle(
                            fontSize: 13,
                            color: _kTextSecond,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _kAccent.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _kAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Secure',
                          style: TextStyle(
                            color: _kAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Google Sign-in Button (enhanced wrapper) ─────────────────
              ScaleTransition(
                scale: _btnScale,
                child: GestureDetector(
                  onTapDown: (_) => _btnCtrl.forward(),
                  onTapUp: (_) => _btnCtrl.reverse(),
                  onTapCancel: () => _btnCtrl.reverse(),
                  child: GoogleSignInButton(
                    isLoading: isLoading,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.read<AuthNotifier>().signInWithGoogle();
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Divider ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: _kBorder),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 11, color: _kTextHint),
                        const SizedBox(width: 5),
                        const Text(
                          'Trusted by professionals',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kTextHint,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(height: 1, color: _kBorder),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Social proof ─────────────────────────────────────────────
              _buildSocialProof(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Social Proof ──────────────────────────────────────────────────────────

  Widget _buildSocialProof() {
    const avatarColors = [
      Color(0xFF6C63FF),
      Color(0xFF3DD8C9),
      Color(0xFFF5C842),
      Color(0xFFEF4444),
    ];
    const initials = ['A', 'M', 'J', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Overlapping avatars
        SizedBox(
          width: 4 * 22.0 + 6,
          height: 30,
          child: Stack(
            children: List.generate(
                4,
                (i) => Positioned(
                      left: i * 20.0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: avatarColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: _kCard, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials[i],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )),
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 12, color: _kTextSecond),
            children: [
              TextSpan(
                text: '2,000+ ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _kTextPrime,
                ),
              ),
              TextSpan(text: 'professionals trust'),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Column(
      children: [
        // Feature pills
        Wrap(
          spacing: 10,
          children: [
            _FeaturePill(
                icon: Icons.flash_on_rounded, label: 'Fast', color: _kGold),
            _FeaturePill(
                icon: Icons.security_rounded, label: 'Secure', color: _kAccent),
            _FeaturePill(
                icon: Icons.sync_rounded,
                label: 'Cross-sync',
                color: _kPrimary),
          ],
        ),
        const SizedBox(height: 20),
        // Legal links
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FooterLink(label: 'Privacy Policy'),
            Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                color: _kTextHint,
                shape: BoxShape.circle,
              ),
            ),
            _FooterLink(label: 'Terms of Service'),
          ],
        ),
      ],
    );
  }

  // ─── Error SnackBar ────────────────────────────────────────────────────────

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Orbs Background
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedOrbs extends StatelessWidget {
  final Animation<double> floatAnim;
  final Size size;
  const _AnimatedOrbs({required this.floatAnim, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatAnim,
      builder: (_, __) {
        final t = floatAnim.value;
        return Stack(
          children: [
            // Top-right violet orb
            Positioned(
              top: -120 + 20 * t,
              right: -80 + 10 * math.sin(t * math.pi),
              child: _GlowOrb(
                size: 380,
                color: const Color(0xFF6C63FF),
                opacity: 0.13,
              ),
            ),
            // Bottom-left teal orb
            Positioned(
              bottom: -80 - 15 * t,
              left: -100 + 10 * t,
              child: _GlowOrb(
                size: 320,
                color: const Color(0xFF3DD8C9),
                opacity: 0.11,
              ),
            ),
            // Center-left small gold orb
            Positioned(
              top: size.height * 0.35 + 20 * t,
              left: -60,
              child: _GlowOrb(
                size: 200,
                color: const Color(0xFFF5C842),
                opacity: 0.07,
              ),
            ),
            // Subtle grid lines
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb(
      {required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtle dot-grid painter
// ─────────────────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 32.0;
    final paint = Paint()
      ..color = const Color(0xFF1E2440).withOpacity(0.4)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Noise texture painter
// ─────────────────────────────────────────────────────────────────────────────

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 8000; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 0.8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_NoisePainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeaturePill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        label,
        style: const TextStyle(
          color: _kTextHint,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: _kTextHint,
        ),
      ),
    );
  }
}
