// lib/presentation/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/l10n.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/database/database_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animationController;
  late final Animation<double> _checkAnimation;

  int _currentPage = 0;
  bool _isLanguageSelected = false;
  String _selectedLangCode = 'en';
  bool _isThemeSelected = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _checkAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    );

    // Read stored language code as default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localeProv = Provider.of<LocaleProvider>(context, listen: false);
      setState(() {
        _selectedLangCode = localeProv.locale.languageCode;
        // Language is pre-selected on startup
        _isLanguageSelected = true;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      await DatabaseService.settingsBox.put('onboarding_done', true);
    } catch (_) {}
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final localeProvider = context.watch<LocaleProvider>();
    final localizations = AppLocalizations.of(context)!;
    final isRtl = localeProvider.isArabic;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: Icon(
                        isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                        color: tokens.textSecondary,
                        size: 20,
                      ),
                      onPressed: _prevPage,
                    )
                  else
                    const SizedBox(width: 40),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: () {
                        // Skip directly goes to Language selection (index 2)
                        _pageController.animateToPage(
                          2,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: Text(
                        localizations.translate('skip') ?? 'Skip',
                        style: TextStyle(
                          color: tokens.mint,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // strict control
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(tokens, localizations),
                  _buildCalendarPage(tokens, localizations),
                  _buildLanguagePage(tokens, localizations, localeProvider),
                  _buildThemePage(tokens, localizations),
                ],
              ),
            ),

            // Indicator Dots & Bottom Action Buttons
            _buildBottomControls(tokens, localizations, isRtl),
          ],
        ),
      ),
    );
  }

  // ─── PAGE 1: Welcome Screen ────────────────────────────────────────────────
  Widget _buildWelcomePage(AppThemeTokens tokens, AppLocalizations localizations) {
    final welcomeTitle = localizations.translate('onboarding_welcome_title') ?? 'QuickTask';
    final welcomeSub = localizations.translate('onboarding_welcome_sub') ??
        'Elevate your productivity, simplify your day.';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // Logo in white rounded container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Image.asset(
              'assets/Blue Modern Company Logo (1).png',
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(height: 24),

          // Custom animated title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [tokens.mint, tokens.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              welcomeTitle,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              welcomeSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: tokens.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Beautiful Animated Checklist Custom Painter
          AnimatedBuilder(
            animation: _checkAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 220),
                painter: ChecklistPainter(
                  progress: _checkAnimation.value,
                  checkColor: tokens.mint,
                  lineColor: tokens.textSecondary,
                  cardColor: tokens.cardBg,
                  glowColor: tokens.purple,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── PAGE 2: Google Calendar Showcase ──────────────────────────────────────────
  Widget _buildCalendarPage(AppThemeTokens tokens, AppLocalizations localizations) {
    final title = localizations.translate('onboarding_calendar_title') ?? 'Google Calendar Sync';
    final sub = localizations.translate('onboarding_calendar_sub') ??
        'Your tasks are automatically synced with Google Calendar. Never miss a deadline again.';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: tokens.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Google Calendar Custom Painter
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return CustomPaint(
                size: const Size(double.infinity, 220),
                painter: CalendarPainter(
                  progress: _animationController.value,
                  primaryColor: tokens.mint,
                  secondaryColor: tokens.purple,
                  textColor: tokens.textPrimary,
                  cardColor: tokens.cardBg,
                  glowColor: tokens.mint,
                  isDark: isDark,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── PAGE 3: Language Selection ──────────────────────────────────────────
  Widget _buildLanguagePage(
      AppThemeTokens tokens, AppLocalizations localizations, LocaleProvider localeProvider) {
    final title = localizations.translate('onboarding_lang_title') ?? 'Choose Language';
    final sub = localizations.translate('onboarding_lang_sub') ??
        'Select your preferred language to customize your workspace.';

    final List<String> languages = ['en', 'ar', 'de', 'fr'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: tokens.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),

          // Beautiful Grid of Languages
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: languages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final code = languages[index];
              final isSelected = _selectedLangCode == code;
              final flag = L10n.getFlag(code);
              final name = L10n.getLanguageName(code);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLangCode = code;
                    _isLanguageSelected = true;
                  });
                  localeProvider.setLocale(Locale(code));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: isSelected ? tokens.cardBg : tokens.cardBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? tokens.mint : tokens.divider,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: tokens.mint.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              flag,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: tokens.mint,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── PAGE 3: Theme Selection ─────────────────────────────────────────────
  Widget _buildThemePage(AppThemeTokens tokens, AppLocalizations localizations) {
    final title = localizations.translate('onboarding_theme_title') ?? 'Select Theme';
    final sub = localizations.translate('onboarding_theme_sub') ??
        'Personalize your visual experience. You can change this anytime.';

    final themeNotifier = context.watch<ThemeNotifier>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: tokens.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),

          // Side-by-side Theme Cards
          Row(
            children: [
              // Light Mode Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    themeNotifier.setDark(false);
                    setState(() {
                      _isThemeSelected = true;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: !themeNotifier.isDark ? tokens.cardBg : tokens.cardBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: !themeNotifier.isDark ? tokens.mint : tokens.divider,
                        width: !themeNotifier.isDark ? 2 : 1,
                      ),
                      boxShadow: !themeNotifier.isDark
                          ? [
                              BoxShadow(
                                color: tokens.mint.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        // Mock Screen Drawing
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6FB), // Light BG
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8DEFF), // light purple
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 28,
                                left: 12,
                                right: 12,
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFC5CCDF)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 40,
                                        height: 6,
                                        color: const Color(0xFF9BA3BF),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wb_sunny_rounded,
                              size: 16,
                              color: !themeNotifier.isDark ? tokens.mint : tokens.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localizations.translate('light') ?? 'Light',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: !themeNotifier.isDark ? FontWeight.w700 : FontWeight.w500,
                                color: !themeNotifier.isDark ? tokens.textPrimary : tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Dark Mode Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    themeNotifier.setDark(true);
                    setState(() {
                      _isThemeSelected = true;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeNotifier.isDark ? tokens.cardBg : tokens.cardBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: themeNotifier.isDark ? tokens.mint : tokens.divider,
                        width: themeNotifier.isDark ? 2 : 1,
                      ),
                      boxShadow: themeNotifier.isDark
                          ? [
                              BoxShadow(
                                color: tokens.mint.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        // Mock Screen Drawing
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0F1A), // Dark BG
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E2440),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 28,
                                left: 12,
                                right: 12,
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141720),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF3E4466)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 40,
                                        height: 6,
                                        color: const Color(0xFF7B82A8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.nightlight_round_rounded,
                              size: 16,
                              color: themeNotifier.isDark ? tokens.mint : tokens.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localizations.translate('dark') ?? 'Dark',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: themeNotifier.isDark ? FontWeight.w700 : FontWeight.w500,
                                color: themeNotifier.isDark ? tokens.textPrimary : tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Live Preview Strip Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              localizations.translate('live_preview') ?? 'Live Preview',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Live Preview Strip itself
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.mint.withOpacity(0.15),
                    border: Border.all(color: tokens.mint, width: 2),
                  ),
                  child: Icon(
                    Icons.check,
                    color: tokens.mint,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('onboarding_preview_task') ?? 'Try toggling themes above!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: 5:00 PM',
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Work',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tokens.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── BOTTOM CONTROLS & PHYSICS ───────────────────────────────────────────
  Widget _buildBottomControls(AppThemeTokens tokens, AppLocalizations localizations, bool isRtl) {
    final nextBtnText = localizations.translate('next') ?? 'Next';
    final getStartedBtnText = localizations.translate('get_started') ?? 'Get Started';
    final doneBtnText = localizations.translate('done') ?? 'Done';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isActive ? 24 : 8,
                decoration: BoxDecoration(
                  color: isActive ? tokens.mint : tokens.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Primary CTA Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage == 0 || _currentPage == 1) {
                  _nextPage();
                } else if (_currentPage == 2) {
                  if (_isLanguageSelected) {
                    _nextPage();
                  }
                } else {
                  _completeOnboarding();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.mint,
                foregroundColor: tokens.textDark,
                elevation: 0,
                shadowColor: tokens.mint.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _currentPage == 0
                      ? getStartedBtnText
                      : (_currentPage == 1 || _currentPage == 2)
                          ? nextBtnText
                          : doneBtnText,
                  key: ValueKey<int>(_currentPage),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChecklistPainter extends CustomPainter {
  final double progress;
  final Color checkColor;
  final Color lineColor;
  final Color cardColor;
  final Color glowColor;

  ChecklistPainter({
    required this.progress,
    required this.checkColor,
    required this.lineColor,
    required this.cardColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw glowing orb in background
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [glowColor.withOpacity(0.25), glowColor.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.5), radius: size.width * 0.45));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.45, glowPaint);

    // 2. Draw mock checklist card
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.5), width: size.width * 0.72, height: size.height * 0.75),
      const Radius.circular(20),
    );
    final cardPaint = Paint()
      ..color = cardColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(cardRect, cardPaint);

    // Draw card border
    final borderPaint = Paint()
      ..color = lineColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(cardRect, borderPaint);

    // 3. Draw checklist item 1 (uncompleted)
    final item1Y = size.height * 0.32;
    final check1Center = Offset(size.width * 0.24, item1Y);
    final checkPaint1 = Paint()
      ..color = lineColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(check1Center, 9, checkPaint1);

    // Draw list lines for item 1
    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.35)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;
    canvas.drawLine(Offset(size.width * 0.32, item1Y - 2), Offset(size.width * 0.65, item1Y - 2), linePaint);
    canvas.drawLine(Offset(size.width * 0.32, item1Y + 6), Offset(size.width * 0.52, item1Y + 6), Paint()
      ..color = lineColor.withOpacity(0.15)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0);

    // 4. Draw checklist item 2 (animated checked item)
    final item2Y = size.height * 0.50;
    final check2Center = Offset(size.width * 0.24, item2Y);
    
    // Checkbox background
    final checkBgPaint = Paint()
      ..color = checkColor.withOpacity(0.08 + progress * 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(check2Center, 9, checkBgPaint);

    // Checkbox border
    final checkBorderPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(check2Center, 9, checkBorderPaint);

    // Checkmark inside checkbox (animated path)
    if (progress > 0) {
      final checkPath = Path();
      final p1 = Offset(check2Center.dx - 4, check2Center.dy);
      final p2 = Offset(check2Center.dx - 1, check2Center.dy + 3);
      final p3 = Offset(check2Center.dx + 4, check2Center.dy - 3);

      checkPath.moveTo(p1.dx, p1.dy);
      if (progress < 0.4) {
        final t = progress / 0.4;
        checkPath.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
      } else {
        checkPath.lineTo(p2.dx, p2.dy);
        final t = (progress - 0.4) / 0.6;
        checkPath.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
      }

      final checkPaint = Paint()
        ..color = cardColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.2;
      canvas.drawPath(checkPath, checkPaint);
    }

    // List lines for item 2
    final linePaint2 = Paint()
      ..color = Color.lerp(lineColor.withOpacity(0.7), lineColor.withOpacity(0.25), progress)!
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;
    canvas.drawLine(Offset(size.width * 0.32, item2Y - 2), Offset(size.width * 0.70, item2Y - 2), linePaint2);
    
    // Draw horizontal strike-through line
    if (progress > 0) {
      canvas.drawLine(
        Offset(size.width * 0.32, item2Y - 2),
        Offset(size.width * 0.32 + (size.width * 0.38) * progress, item2Y - 2),
        Paint()
          ..color = checkColor.withOpacity(0.7)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.8
      );
    }

    canvas.drawLine(Offset(size.width * 0.32, item2Y + 6), Offset(size.width * 0.58, item2Y + 6), Paint()
      ..color = lineColor.withOpacity(0.15)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0);

    // 5. Draw checklist item 3 (uncompleted)
    final item3Y = size.height * 0.68;
    final check3Center = Offset(size.width * 0.24, item3Y);
    final checkPaint3 = Paint()
      ..color = lineColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(check3Center, 9, checkPaint3);

    final linePaint3 = Paint()
      ..color = lineColor.withOpacity(0.35)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;
    canvas.drawLine(Offset(size.width * 0.32, item3Y - 2), Offset(size.width * 0.58, item3Y - 2), linePaint3);
    canvas.drawLine(Offset(size.width * 0.32, item3Y + 6), Offset(size.width * 0.46, item3Y + 6), Paint()
      ..color = lineColor.withOpacity(0.15)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0);
  }

  @override
  bool shouldRepaint(covariant ChecklistPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.cardColor != cardColor;
  }
}

class CalendarPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color primaryColor; // e.g. tokens.mint
  final Color secondaryColor; // e.g. tokens.purple
  final Color textColor;
  final Color cardColor;
  final Color glowColor;
  final bool isDark;

  CalendarPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.cardColor,
    required this.glowColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Glowing background orb
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [glowColor.withOpacity(0.22), glowColor.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: Offset(width * 0.5, height * 0.5), radius: width * 0.45));
    canvas.drawCircle(Offset(width * 0.5, height * 0.5), width * 0.45, glowPaint);

    // 2. Draw Google Calendar Card (on the right/bottom)
    final calRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.48, height * 0.2, width * 0.45, height * 0.65),
      const Radius.circular(16),
    );
    
    final calPaint = Paint()
      ..color = cardColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(calRect, calPaint);

    // Border for calendar card
    final calBorderPaint = Paint()
      ..color = textColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(calRect, calBorderPaint);

    // Draw calendar header (e.g. "May 2026")
    final headerPaint = Paint()
      ..color = textColor.withOpacity(0.4)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    canvas.drawLine(Offset(width * 0.54, height * 0.28), Offset(width * 0.68, height * 0.28), headerPaint);

    // Draw calendar grid circles/squares
    final gridPaint = Paint()
      ..color = textColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    const rows = 4;
    const cols = 5;
    final startX = width * 0.54;
    final startY = height * 0.36;
    final cellW = width * 0.07;
    final cellH = height * 0.08;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = startX + c * cellW;
        final cy = startY + r * cellH;

        // Make one specific day the "synced task day"
        if (r == 2 && c == 2) {
          // Pulse the highlight day
          final pulsePaint = Paint()
            ..color = primaryColor.withOpacity(0.15 + 0.3 * (1.0 - (progress - 0.5).abs() * 2))
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: cellW - 4, height: cellH - 4),
              const Radius.circular(6),
            ),
            pulsePaint,
          );
          
          final eventPaint = Paint()
            ..color = primaryColor
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy + 2), width: cellW - 8, height: cellH * 0.4),
              const Radius.circular(3),
            ),
            eventPaint,
          );
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: cellW - 6, height: cellH - 6),
              const Radius.circular(4),
            ),
            gridPaint,
          );
        }
      }
    }

    // 3. Draw Task Card (on the left/top)
    final taskRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.08, height * 0.3, width * 0.36, height * 0.42),
      const Radius.circular(16),
    );
    
    canvas.drawRRect(taskRect, calPaint);
    canvas.drawRRect(taskRect, calBorderPaint);

    // Task Card Content
    final checkboxPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(width * 0.16, height * 0.42), 7, checkboxPaint);

    // Draw some text lines representing task title
    canvas.drawLine(
      Offset(width * 0.22, height * 0.42),
      Offset(width * 0.38, height * 0.42),
      Paint()
        ..color = textColor.withOpacity(0.7)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(width * 0.14, height * 0.5),
      Offset(width * 0.32, height * 0.5),
      Paint()
        ..color = textColor.withOpacity(0.3)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );

    // GCal sync tag on the task card
    final tagPaint = Paint()
      ..color = primaryColor.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.14, height * 0.58, width * 0.24, height * 0.08),
        const Radius.circular(4),
      ),
      tagPaint,
    );
    canvas.drawLine(
      Offset(width * 0.18, height * 0.62),
      Offset(width * 0.34, height * 0.62),
      Paint()
        ..color = primaryColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );

    // 4. Draw Animated Sync Bezier Curve
    final path = Path();
    final startPt = Offset(width * 0.38, height * 0.5);
    final endPt = Offset(startX + 2 * cellW, startY + 2 * cellH);
    
    path.moveTo(startPt.dx, startPt.dy);
    // Draw beautiful S-shaped curve
    final controlPt1 = Offset(width * 0.42, height * 0.35);
    final controlPt2 = Offset(width * 0.48, height * 0.6);
    path.cubicTo(controlPt1.dx, controlPt1.dy, controlPt2.dx, controlPt2.dy, endPt.dx, endPt.dy);

    final pathPaint = Paint()
      ..shader = LinearGradient(
        colors: [secondaryColor, primaryColor],
      ).createShader(Rect.fromPoints(startPt, endPt))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw dashed/animated line
    canvas.drawPath(path, pathPaint);

    // Draw the pulsing particle along the path
    final pathMetrics = path.computeMetrics();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final currentPos = metric.length * progress;
      final tangent = metric.getTangentForOffset(currentPos);
      if (tangent != null) {
        final particleCenter = tangent.position;
        // Particle glow
        final particleGlow = Paint()
          ..color = primaryColor.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(particleCenter, 8.0, particleGlow);

        final particlePaint = Paint()
          ..color = primaryColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(particleCenter, 4.0, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CalendarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.cardColor != cardColor ||
        oldDelegate.textColor != textColor;
  }
}
