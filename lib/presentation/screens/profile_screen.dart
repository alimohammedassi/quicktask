// lib/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/task_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        _buildAppBar(context),
        const SizedBox(height: 24),
        _buildAvatar(user, name),
        const SizedBox(height: 20),
        _buildName(name, email),
        const SizedBox(height: 28),
        _buildStatsRow(total, done, pending),
        const SizedBox(height: 24),
        _buildSection('Account'),
        const SizedBox(height: 12),
        _buildTile(context, Icons.person_outline_rounded, 'Edit Profile', () => _showEditProfileDialog(context, user)),
        _buildTile(context, Icons.lock_outline_rounded, 'Change Password', () => _showPasswordReset(context, user)),
        _buildTile(context, Icons.notifications_outlined, 'Notifications', () => _showComingSoon(context, 'Notifications')),
        const SizedBox(height: 24),
        _buildSection('Preferences'),
        const SizedBox(height: 12),
        _buildTile(context, Icons.language_rounded, 'Language', () => _showComingSoon(context, 'Language Settings')),
        _buildTile(context, Icons.palette_outlined, 'Appearance', () => _showComingSoon(context, 'Appearance Themes')),
        _buildTile(context, Icons.calendar_today_outlined, 'Calendar Sync', () => _showComingSoon(context, 'Calendar Sync')),
        const SizedBox(height: 24),
        _buildSection('About'),
        const SizedBox(height: 12),
        _buildTile(context, Icons.info_outline_rounded, 'About QuickTask', () => _showComingSoon(context, 'About')),
        _buildTile(context, Icons.privacy_tip_outlined, 'Privacy Policy', () => _showComingSoon(context, 'Privacy Policy')),
        const SizedBox(height: 32),
        _buildLogoutButton(context),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 42), // Spacer
            Text('Profile',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            _iconBtn(Icons.settings_outlined),
          ],
        ),
      );

  Widget _iconBtn(IconData icon) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      );

  Widget _buildAvatar(User? user, String name) => Center(
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.mint, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mint.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: AppColors.cardBg,
                  backgroundImage: user?.userMetadata?['avatar_url'] != null ? NetworkImage(user!.userMetadata!['avatar_url']) : null,
                  child: user?.userMetadata?['avatar_url'] == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: GoogleFonts.outfit(
                              color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w800),
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
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.textDark),
              ),
            ),
          ],
        ),
      );

  Widget _buildName(String name, String email) => Column(
        children: [
          Text(name,
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(email,
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
        ],
      );

  Widget _buildStatsRow(int total, int done, int pending) => Row(
        children: [
          Expanded(child: _statChip('$total', 'Total', AppColors.purple)),
          const SizedBox(width: 12),
          Expanded(child: _statChip('$done', 'Done', AppColors.mint)),
          const SizedBox(width: 12),
          Expanded(child: _statChip('$pending', 'Pending', AppColors.yellow)),
        ],
      );

  Widget _statChip(String value, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.outfit(
                    color: color, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );

  Widget _buildSection(String title) => Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: GoogleFonts.outfit(
                color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _buildTile(BuildContext context, IconData icon, String title, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.innerCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.textPrimary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title,
                        style: GoogleFonts.outfit(
                            color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildLogoutButton(BuildContext context) => GestureDetector(
        onTap: () => context.read<AuthNotifier>().signOut(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text('Log Out',
                  style: GoogleFonts.outfit(
                      color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );

  void _showEditProfileDialog(BuildContext context, User? user) {
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.userMetadata?['display_name']);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Edit Profile', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        content: TextField(
          controller: nameCtrl,
          style: GoogleFonts.outfit(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.mint)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                try {
                  await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'display_name': nameCtrl.text.trim()}));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile updated successfully!', style: GoogleFonts.outfit())),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e', style: GoogleFonts.outfit())),
                    );
                  }
                }
              }
            },
            child: Text('Save', style: GoogleFonts.outfit(color: AppColors.mint, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPasswordReset(BuildContext context, User? user) async {
    if (user?.email == null) return;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(user!.email!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to ${user.email}', style: GoogleFonts.outfit())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e', style: GoogleFonts.outfit())),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!', style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.innerCard,
      ),
    );
  }
}




