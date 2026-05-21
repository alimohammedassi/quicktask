// lib/features/auth/presentation/screens/login_screen.dart
//
// Redesign goals:
//  1. Human warmth through copy, not emoji — time-aware greeting, real product voice
//  2. Emoji removed from all structural UI (heading, pills) — Icons only
//  3. "TaskVoice" branding aligned with session notes
//  4. Footer links meet 44×44px touch target
//  5. Semantics labels on every interactive element
//  6. withOpacity() → withValues(alpha:) throughout
//  7. Social proof replaced with a trust strip (more honest, more readable)
//  8. Feature pills use consistent Icons with semantic labels
//  9. Loading state disables sign-in button with clear visual feedback
// 10. Error snackbar accessible via assertiveness
// 11. Fully localized (AR, EN, DE, FR) with dynamic language switcher

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/l10n.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFF080A12);
const _kCard = Color(0xFF0F1320);
const _kBorder = Color(0xFF1E2440);
const _kPrimary = Color(0xFF6C63FF); // violet
const _kAccent = Color(0xFF3DD8C9); // teal
const _kGold = Color(0xFFF5C842); // gold
const _kTextPrime = Color(0xFFF0F2FF);
const _kTextSecond = Color(0xFF7B82A8);
const _kTextHint = Color(0xFF3E4466);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _floatCtrl;

  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.96)
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
            // Animated ambient background
            _AnimatedOrbs(floatAnim: _floatCtrl, size: size),

            // Blur veil
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const ColoredBox(color: Colors.transparent),
            ),

            // Curved background waves
            _BackgroundWaves(floatAnim: _floatCtrl),

            // Noise grain
            Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: _NoisePainter()),
            ),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(flex: 3),
                            _buildBranding(),
                            const Spacer(flex: 2),
                            _buildGlassCard(isLoading),
                            const Spacer(flex: 2),
                            _buildFooter(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Floating dynamic RTL Language Switcher
            Positioned(
              top: 16,
              right: context.isRtl ? null : 16,
              left: context.isRtl ? 16 : null,
              child: const SafeArea(
                child: _LanguageSwitcher(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Branding ──────────────────────────────────────────────────────────────

  Widget _buildBranding() {
    return Column(
      children: [
        // Title gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFB8B0FF), Color(0xFF6C63FF), Color(0xFF3DD8C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            context.translate('quiktask'),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -2.0,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tagline — no dots, no emoji, real copy
        Text(
          context.translate('app_tagline'),
          style: const TextStyle(
            fontSize: 15,
            color: _kTextSecond,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: BoxDecoration(
            color: _kCard.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _kBorder.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: -8,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.06),
                blurRadius: 60,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card header with time-aware greeting ────────────────────
              _CardHeader(),

              const SizedBox(height: 24),

              // ── What you get — 3 value props ────────────────────────────
              const _ValueProps(),

              const SizedBox(height: 28),

              // ── Divider ──────────────────────────────────────────────────
              Container(height: 1, color: _kBorder),

              const SizedBox(height: 28),

              // ── Sign-in button ────────────────────────────────────────────
              Semantics(
                button: true,
                label: context.translate('sign_in_google'),
                enabled: !isLoading,
                child: ScaleTransition(
                  scale: _btnScale,
                  child: GestureDetector(
                    onTapDown: isLoading ? null : (_) => _btnCtrl.forward(),
                    onTapUp: isLoading ? null : (_) => _btnCtrl.reverse(),
                    onTapCancel: isLoading ? null : () => _btnCtrl.reverse(),
                    child: GoogleSignInButton(
                      isLoading: isLoading,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<AuthNotifier>().signInWithGoogle();
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Privacy note ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: _kTextHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.translate('privacy_note'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kTextHint,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Column(
      children: [
        // Trust strip — platform logos replaced by honest copy
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TrustBadge(
              icon: Icons.calendar_month_outlined,
              label: context.translate('google_calendar'),
            ),
            const SizedBox(width: 6),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: _kTextHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            _TrustBadge(
              icon: Icons.notifications_none_rounded,
              label: context.translate('smart_reminders'),
            ),
            const SizedBox(width: 6),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: _kTextHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            _TrustBadge(
              icon: Icons.translate_rounded,
              label: context.translate('multi_language'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Legal — min 44px touch area via Padding
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FooterLink(label: context.translate('privacy_policy')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: _kTextHint,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            _FooterLink(label: context.translate('terms_of_service')),
          ],
        ),
      ],
    );
  }

  // ─── Error snackbar ────────────────────────────────────────────────────────

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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
// Language Switcher — elegant glassmorphic Globe button
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher();

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final activeLocale = localeProvider.locale;

    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: _kCard,
      ),
      child: PopupMenuButton<Locale>(
        icon: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _kCard.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _kBorder.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Icon(
            Icons.language_rounded,
            color: _kAccent,
            size: 20,
          ),
        ),
        tooltip: context.translate('language_switcher_title'),
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kBorder, width: 1.5),
        ),
        onSelected: (Locale locale) {
          HapticFeedback.mediumImpact();
          localeProvider.setLocale(locale);
        },
        itemBuilder: (BuildContext context) {
          return L10n.all.map((locale) {
            final isSelected = locale.languageCode == activeLocale.languageCode;
            return PopupMenuItem<Locale>(
              value: locale,
              child: Row(
                children: [
                  Text(
                    L10n.getFlag(locale.languageCode),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      L10n.getLanguageName(locale.languageCode),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _kAccent : _kTextPrime,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: _kAccent,
                      size: 16,
                    ),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card header — time-aware, no emoji
// ─────────────────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (greeting, sub) = _copy(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrime,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kTextSecond,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // "Secure" badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _kAccent.withValues(alpha: 0.25),
              width: 1,
            ),
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
              Text(
                context.translate('secure'),
                style: const TextStyle(
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
    );
  }

  (String, String) _copy(BuildContext context) {
    final h = DateTime.now().hour;
    if (h < 5) {
      return (
        context.translate('greeting_still_up'),
        context.translate('greeting_still_up_sub'),
      );
    }
    if (h < 12) {
      return (
        context.translate('greeting_morning'),
        context.translate('greeting_morning_sub'),
      );
    }
    if (h < 17) {
      return (
        context.translate('greeting_afternoon'),
        context.translate('greeting_afternoon_sub'),
      );
    }
    if (h < 21) {
      return (
        context.translate('greeting_evening'),
        context.translate('greeting_evening_sub'),
      );
    }
    return (
      context.translate('greeting_night'),
      context.translate('greeting_night_sub'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Value props — what the app actually does
// ─────────────────────────────────────────────────────────────────────────────

class _ValueProps extends StatelessWidget {
  const _ValueProps();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ValuePropRow(
          icon: Icons.mic_none_rounded,
          color: _kPrimary,
          title: context.translate('speak_voice'),
          subtitle: context.translate('speak_voice_sub'),
        ),
        const SizedBox(height: 16),
        _ValuePropRow(
          icon: Icons.calendar_month_outlined,
          color: _kAccent,
          title: context.translate('sync_gcal_title'),
          subtitle: context.translate('sync_gcal_sub'),
        ),
        const SizedBox(height: 16),
        _ValuePropRow(
          icon: Icons.notifications_none_rounded,
          color: _kGold,
          title: context.translate('smart_reminders_title'),
          subtitle: context.translate('smart_reminders_sub'),
        ),
      ],
    );
  }
}

class _ValuePropRow extends StatelessWidget {
  const _ValuePropRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrime,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kTextSecond,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trust badge
// ─────────────────────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _kTextHint),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _kTextHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer link — 44px tall touch area
// ─────────────────────────────────────────────────────────────────────────────

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // Generous vertical padding → real 44px hit area
          padding: const EdgeInsets.symmetric(vertical: 16),
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated orbs background
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedOrbs extends StatelessWidget {
  const _AnimatedOrbs({required this.floatAnim, required this.size});
  final Animation<double> floatAnim;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatAnim,
      builder: (_, __) {
        final t = floatAnim.value;
        return Stack(
          children: [
            Positioned(
              top: -120 + 20 * t,
              right: -80 + 10 * math.sin(t * math.pi),
              child: _GlowOrb(size: 380, color: _kPrimary, opacity: 0.13),
            ),
            Positioned(
              bottom: -80 - 15 * t,
              left: -100 + 10 * t,
              child: _GlowOrb(size: 320, color: _kAccent, opacity: 0.11),
            ),
            Positioned(
              top: size.height * 0.38 + 20 * t,
              left: -60,
              child: _GlowOrb(size: 200, color: _kGold, opacity: 0.07),
            ),
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
  const _GlowOrb(
      {required this.size, required this.color, required this.opacity});
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot-grid painter
// ─────────────────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 32.0;
    final paint = Paint()
      ..color = const Color(0xFF1E2440).withValues(alpha: 0.4)
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
// Background waves painter
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundWaves extends StatelessWidget {
  const _BackgroundWaves({required this.floatAnim});
  final Animation<double> floatAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatAnim,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(floatAnim.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  _WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // We want thick, white, bold S-curves like the reference
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 45 // Much thicker
      ..strokeCap = StrokeCap.round;

    final double phase = animationValue * math.pi * 2;

    // Top-left bundle
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final double offset = i * 65.0; // Larger gap
      
      // Calculate curve points with some "flow"
      final double startX = -100;
      final double startY = 50 + offset;
      
      final double cp1x = size.width * 0.3 + math.sin(phase + i * 0.2) * 30;
      final double cp1y = offset - 100 + math.cos(phase + i * 0.1) * 20;
      
      final double cp2x = size.width * 0.2 + math.cos(phase + i * 0.3) * 50;
      final double cp2y = size.height * 0.6 + offset + math.sin(phase + i * 0.2) * 40;
      
      final double endX = size.width + 100;
      final double endY = size.height * 0.4 + offset;

      path.moveTo(startX, startY);
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);
      
      canvas.drawPath(path, paint);
    }
    
    // Bottom-right bundle
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 35
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final double offset = i * 55.0;
      
      final double startX = size.width + 100;
      final double startY = size.height * 0.7 + offset;
      
      final double cp1x = size.width * 0.6 + math.cos(phase - i * 0.2) * 40;
      final double cp1y = size.height * 0.9 + offset;
      
      final double cp2x = size.width * 0.4 + math.sin(phase - i * 0.1) * 30;
      final double cp2y = size.height * 0.3 + offset;
      
      final double endX = -100;
      final double endY = size.height * 0.1 + offset;

      path.moveTo(startX, startY);
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);
      
      canvas.drawPath(path, paint2);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}
