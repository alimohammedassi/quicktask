// lib/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/l10n.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../providers/task_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final user = context.watch<User?>();
    final notifier = context.watch<TasksNotifier>();
    final name = user?.userMetadata?['display_name'] ?? 'User';
    final email = user?.email ?? '';
    final total = notifier.tasks.length;
    final done = notifier.completedTasks.length;
    final pending = notifier.pendingTasks.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Extra padding for bottom nav
      children: [
        _buildAppBar(context, tokens),
        const SizedBox(height: 24),
        _buildAvatar(context, tokens, user, name),
        const SizedBox(height: 20),
        _buildName(tokens, name, email),
        const SizedBox(height: 28),
        _buildStatsRow(context, tokens, total, done, pending),
        const SizedBox(height: 24),
        _buildSection(context, tokens, context.translate('account_section')),
        const SizedBox(height: 12),
        _buildTile(context, tokens, Icons.person_outline_rounded, context.translate('edit_profile'), () => _showEditProfileDialog(context, tokens, user)),
        _buildTile(context, tokens, Icons.lock_outline_rounded, context.translate('change_password'), () => _showPasswordReset(context, tokens, user)),
        _buildTile(context, tokens, Icons.notifications_outlined, context.translate('notifications'), () => _showComingSoon(context, tokens, context.translate('notifications'))),
        const SizedBox(height: 24),
        _buildSection(context, tokens, context.translate('preferences_section')),
        const SizedBox(height: 12),
        _buildTile(
          context,
          tokens,
          Icons.language_rounded,
          context.translate('language'),
          () => _showLanguageBottomSheet(context, tokens),
          subtitle: L10n.getLanguageName(Localizations.localeOf(context).languageCode),
        ),
        _buildAppearanceTile(context, tokens),
        _buildTile(context, tokens, Icons.calendar_today_outlined, context.translate('calendar_sync'), () => _showComingSoon(context, tokens, context.translate('calendar_sync'))),
        const SizedBox(height: 24),
        _buildSection(context, tokens, context.translate('about_section')),
        const SizedBox(height: 12),
        _buildTile(context, tokens, Icons.info_outline_rounded, context.translate('about_app'), () => _showComingSoon(context, tokens, context.translate('about_app'))),
        _buildTile(context, tokens, Icons.privacy_tip_outlined, context.translate('privacy_policy'), () => _showComingSoon(context, tokens, context.translate('privacy_policy'))),
        const SizedBox(height: 32),
        _buildLogoutButton(context, tokens),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, AppThemeTokens tokens) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 42), // Spacer
            Text(context.translate('profile'),
                style: GoogleFonts.plusJakartaSans(
                    color: tokens.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            _iconBtn(tokens, Icons.settings_outlined),
          ],
        ),
      );

  Widget _iconBtn(AppThemeTokens tokens, IconData icon) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: tokens.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.divider),
        ),
        child: Icon(icon, color: tokens.textPrimary, size: 18),
      );

  Widget _buildAvatar(BuildContext context, AppThemeTokens tokens, User? user, String name) => Center(
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [tokens.mint, tokens.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tokens.mint.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: tokens.cardBg,
                  backgroundImage: user?.userMetadata?['avatar_url'] != null ? NetworkImage(user!.userMetadata!['avatar_url']) : null,
                  child: user?.userMetadata?['avatar_url'] == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: GoogleFonts.plusJakartaSans(
                              color: tokens.textPrimary, fontSize: 36, fontWeight: FontWeight.w800),
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.background, width: 3),
                ),
                child: Icon(Icons.camera_alt_rounded, size: 14, color: tokens.textDark),
              ),
            ),
          ],
        ),
      );

  Widget _buildName(AppThemeTokens tokens, String name, String email) => Column(
        children: [
          Text(name,
              style: GoogleFonts.plusJakartaSans(
                  color: tokens.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(email,
              style: GoogleFonts.plusJakartaSans(color: tokens.textSecondary, fontSize: 14)),
        ],
      );

  Widget _buildStatsRow(BuildContext context, AppThemeTokens tokens, int total, int done, int pending) => Row(
        children: [
          Expanded(child: _statChip(tokens, '$total', context.translate('total'), tokens.purple)),
          const SizedBox(width: 12),
          Expanded(child: _statChip(tokens, '$done', context.translate('done'), tokens.mint)),
          const SizedBox(width: 12),
          Expanded(child: _statChip(tokens, '$pending', context.translate('pending'), tokens.yellow)),
        ],
      );

  Widget _statChip(AppThemeTokens tokens, String value, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: tokens.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.divider),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    color: color, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.plusJakartaSans(color: tokens.textSecondary, fontSize: 12)),
          ],
        ),
      );

  Widget _buildSection(BuildContext context, AppThemeTokens tokens, String title) => Align(
        alignment: context.isRtl ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(title,
            style: GoogleFonts.plusJakartaSans(
                color: tokens.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _buildTile(
    BuildContext context,
    AppThemeTokens tokens,
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: tokens.textSecondary.withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: tokens.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.innerCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: tokens.textPrimary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            color: tokens.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              color: tokens.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    context.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: tokens.textHint,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildAppearanceTile(BuildContext context, AppThemeTokens tokens) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tokens.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.innerCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_outlined, color: tokens.textPrimary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.translate('appearance'),
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const _ThemeToggle(),
            ],
          ),
        ),
      );

  Widget _buildLogoutButton(BuildContext context, AppThemeTokens tokens) => GestureDetector(
        onTap: () => context.read<AuthNotifier>().signOut(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: tokens.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: tokens.error, size: 20),
              const SizedBox(width: 8),
              Text(context.translate('log_out'),
                  style: GoogleFonts.plusJakartaSans(
                      color: tokens.error, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );

  void _showEditProfileDialog(BuildContext context, AppThemeTokens tokens, User? user) {
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.userMetadata?['display_name']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardBg,
        title: Text(context.translate('edit_profile'), style: GoogleFonts.plusJakartaSans(color: tokens.textPrimary)),
        content: TextField(
          controller: nameCtrl,
          style: GoogleFonts.plusJakartaSans(color: tokens.textPrimary),
          decoration: InputDecoration(
            labelText: context.translate('display_name'),
            labelStyle: GoogleFonts.plusJakartaSans(color: tokens.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: tokens.divider)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tokens.mint)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.translate('cancel'), style: GoogleFonts.plusJakartaSans(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                try {
                  await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'display_name': nameCtrl.text.trim()}));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.translate('profile_updated_toast'), style: GoogleFonts.plusJakartaSans())),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${context.translate('profile_update_err')}: $e', style: GoogleFonts.plusJakartaSans())),
                    );
                  }
                }
              }
            },
            child: Text(context.translate('save'), style: GoogleFonts.plusJakartaSans(color: tokens.mint, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPasswordReset(BuildContext context, AppThemeTokens tokens, User? user) async {
    if (user?.email == null) return;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(user!.email!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.translate('pass_reset_toast')} ${user.email}', style: GoogleFonts.plusJakartaSans())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.translate('pass_reset_err')}: $e', style: GoogleFonts.plusJakartaSans())),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context, AppThemeTokens tokens, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature ${context.translate('coming_soon_toast')}', style: GoogleFonts.plusJakartaSans()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.innerCard,
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, AppThemeTokens tokens) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final activeLocale = localeProvider.locale;

    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.translate('language_switcher_title'),
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...L10n.all.map((locale) {
                final isSelected = locale.languageCode == activeLocale.languageCode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        localeProvider.setLocale(locale);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tokens.mint.withValues(alpha: 0.1)
                              : tokens.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? tokens.mint.withValues(alpha: 0.5)
                                : tokens.cardBg,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              L10n.getFlag(locale.languageCode),
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              L10n.getLanguageName(locale.languageCode),
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? tokens.mint : tokens.textPrimary,
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: tokens.mint,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.isDark;

    return GestureDetector(
      onTap: () {
        themeNotifier.toggleTheme();
      },
      child: Container(
        width: 72,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: tokens.innerCard,
          border: Border.all(color: tokens.divider),
        ),
        child: Stack(
          children: [
            // Background icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    size: 14,
                    color: isDark ? tokens.textHint : tokens.mint,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.nightlight_round_rounded,
                    size: 14,
                    color: isDark ? tokens.mint : tokens.textHint,
                  ),
                ),
              ],
            ),
            // Sliding thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutBack,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isDark ? Icons.nightlight_round_rounded : Icons.wb_sunny_rounded,
                    size: 14,
                    color: tokens.mint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
