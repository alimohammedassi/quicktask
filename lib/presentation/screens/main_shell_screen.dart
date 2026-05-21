import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';

class MainShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == 2) {
      // Add Task Action
      HapticFeedback.mediumImpact();
      context.push('/add-task');
      return;
    }

    // Map bottom nav indices to shell branch indices
    // 0: Home -> Branch 0
    // 1: Stats -> Branch 1
    // 4: Profile -> Branch 2
    int branchIndex = 0;
    if (index == 1) branchIndex = 1;
    if (index == 4) branchIndex = 2;

    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the bottom nav index based on the current shell branch
    int navIndex = 0;
    switch (widget.navigationShell.currentIndex) {
      case 0:
        navIndex = 0;
        break;
      case 1:
        navIndex = 1;
        break;
      case 2:
        navIndex = 4;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          widget.navigationShell,
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomNav(
              index: navIndex,
              fabCtrl: _fabCtrl,
              fabScale: _fabScale,
              onTap: _onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onTap,
    required this.fabCtrl,
    required this.fabScale,
  });
  final int index;
  final void Function(int) onTap;
  final AnimationController fabCtrl;
  final Animation<double> fabScale;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PillNavItem(
                        label: context.translate('nav_tasks'),
                        icon: Icons.home_filled,
                        active: index == 0,
                        onTap: () => onTap(0),
                      ),
                      _PillNavItem(
                        label: context.translate('nav_stats'),
                        icon: Icons.stacked_bar_chart_rounded,
                        active: index == 1,
                        onTap: () => onTap(1),
                      ),
                      _PillNavItem(
                        label: context.translate('nav_profile'),
                        icon: Icons.person_rounded,
                        active: index == 4,
                        onTap: () => onTap(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTapDown: (_) => fabCtrl.forward(),
            onTapUp: (_) {
              fabCtrl.reverse();
              onTap(2);
            },
            onTapCancel: () => fabCtrl.reverse(),
            child: ScaleTransition(
              scale: fabScale,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.mint,
                      size: 32,
                    ),
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

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 16 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.mint.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.mint : AppColors.textSecondary,
            ),
            if (active) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.mint,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
