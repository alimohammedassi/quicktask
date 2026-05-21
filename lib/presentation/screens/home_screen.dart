// lib/presentation/screens/home_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../providers/task_provider.dart';
import '../providers/current_task_provider.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import 'summary_screen.dart';
import 'profile_screen.dart';
import '../widgets/task_card.dart';
import '../../core/database/task_model_hive.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens (consistent 8dp rhythm)
// ─────────────────────────────────────────────────────────────
const _kPad = 20.0;
const _kGap = 10.0;

// ═══════════════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIdx = 0;
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _fabScale = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildBody(),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomNav(
                index: _navIdx,
                fabCtrl: _fabCtrl,
                fabScale: _fabScale,
                onTap: (i) {
                  if (i == 2) {
                    HapticFeedback.mediumImpact();
                    Navigator.push(context, _slideUp(const AddTaskScreen()));
                    return;
                  }
                  if (i == 1) {
                    Navigator.push(context, _slideUp(const SummaryScreen()));
                    return;
                  }
                  if (i == 4) {
                    Navigator.push(context, _slideUp(const ProfileScreen()));
                    return;
                  }
                  HapticFeedback.selectionClick();
                  setState(() => _navIdx = i);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final user = context.watch<User?>();
    final notifier = context.watch<TasksNotifier>();
    final currentTask = context.watch<CurrentTaskNotifier>();
    final pending = notifier.pendingTasks;
    final completed = notifier.completedTasks;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 150),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _TopBar(user: user),
              const SizedBox(height: 16),
              const _WeekNav(),
              const SizedBox(height: 20),

              // ── Current Task Mint Card ─────────────────────────
              _CurrentTaskMintCard(
                currentTaskNotifier: currentTask,
                completedTasks: completed,
                pendingTasks: pending,
              ),
              const SizedBox(height: 28),

              // ── Pending tasks ─────────────────────────────────
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                  title: 'All Tasks',
                  badge: '${pending.length}',
                  action: 'See All',
                  onAction: () {},
                ),
                const SizedBox(height: _kGap),
                ...List.generate(pending.length, (i) {
                  final task = pending[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: _kGap),
                    child: AllTaskTile(
                      task: task,
                      onTap: () => _openDetail(task),
                      onToggleComplete: () => _completeTask(notifier, task),
                      onDelete: () => _deleteTask(notifier, task),
                    ),
                  );
                }),
              ],

              // ── Completed tasks ───────────────────────────────
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Completed',
                  badge: '${completed.length}',
                  action: 'Clear all',
                  onAction: () {},
                  badgeColor: AppColors.mint,
                ),
                const SizedBox(height: _kGap),
                ...List.generate(completed.length, (i) {
                  final task = completed[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: _kGap),
                    child: AllTaskTile(
                      task: task,
                      onTap: () => _openDetail(task),
                      onToggleComplete: () => _completeTask(notifier, task),
                      onDelete: () => _deleteTask(notifier, task),
                    ),
                  );
                }),
              ],

              // ── Empty state ───────────────────────────────────
              if (notifier.tasks.isEmpty)
                _EmptyState(
                  onAdd: () =>
                      Navigator.push(context, _slideUp(const AddTaskScreen())),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  void _openDetail(TaskModelHive task) async {
    await Navigator.push(context, _slideUp(TaskDetailScreen(task: task)));
    if (mounted) setState(() {});
  }

  void _completeTask(TasksNotifier notifier, TaskModelHive task) {
    HapticFeedback.mediumImpact();
    notifier.toggleComplete(task.id);
    _showSnackBar(
      icon: task.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
      message: task.isCompleted ? 'Marked as pending' : 'Task completed! 🎉',
      color: task.isCompleted ? AppColors.purple : AppColors.mint,
      action: SnackBarAction(
        label: 'Undo',
        textColor: AppColors.textDark,
        onPressed: () => notifier.toggleComplete(task.id),
      ),
    );
  }

  void _deleteTask(TasksNotifier notifier, TaskModelHive task) {
    HapticFeedback.heavyImpact();
    notifier.deleteTask(task);
    _showSnackBar(
      icon: Icons.delete_rounded,
      message: '"${task.title}" deleted',
      color: AppColors.error,
    );
  }

  void _showSnackBar({
    required IconData icon,
    required String message,
    required Color color,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      duration: const Duration(seconds: 3),
      action: action,
    ));
  }

  Route _slideUp(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 340),
      );
}

// ═══════════════════════════════════════════════════════════════
// BENTO DASHBOARD — premium mint, purple, yellow widgets from screenshot
// ═══════════════════════════════════════════════════════════════
class _CurrentTaskMintCard extends StatelessWidget {
  const _CurrentTaskMintCard({
    required this.currentTaskNotifier,
    required this.completedTasks,
    required this.pendingTasks,
  });

  final CurrentTaskNotifier currentTaskNotifier;
  final List<TaskModelHive> completedTasks;
  final List<TaskModelHive> pendingTasks;

  @override
  Widget build(BuildContext context) {
    final focusTask = currentTaskNotifier.currentTask;
    
    // Title determination: Pinned task or first pending task, otherwise "No active tasks"
    final String focusTaskTitle = focusTask != null
        ? focusTask.title
        : (pendingTasks.isNotEmpty ? pendingTasks.first.title : 'No active tasks');

    // Progress determination: Pinned task's subtasks progress, otherwise overall progress
    final double focusProgress;
    if (focusTask != null) {
      focusProgress = currentTaskNotifier.progress;
    } else {
      final total = completedTasks.length + pendingTasks.length;
      focusProgress = total == 0 ? 0.0 : completedTasks.length / total;
    }

    // Categories: Pinned task's categories, or first pending's categories, or default
    final List<String> categories = focusTask != null
        ? focusTask.categories
        : (pendingTasks.isNotEmpty ? pendingTasks.first.categories : []);

    final displayCategories = categories.isEmpty ? ['QuickTask'] : categories;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Text and Pills
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current tasks'.toUpperCase(),
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      focusTaskTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // White trend pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded, color: Colors.black, size: 12),
                          SizedBox(width: 4),
                          Text(
                            '+12%',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Black category tag pills
                    ...displayCategories.take(2).map((cat) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Right Side: Navigation Buttons & Gauge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Share Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.share_rounded, color: Colors.black, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Diagonal Arrow Button to Stats Screen
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const SummaryScreen(),
                          transitionsBuilder: (_, a, __, child) => SlideTransition(
                            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_outward_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SemiDonutGauge(progress: focusProgress),
            ],
          ),
        ],
      ),
    );
  }
}

class _SemiDonutGauge extends StatelessWidget {
  const _SemiDonutGauge({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _SemiDonutPainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Done',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SemiDonutPainter extends CustomPainter {
  const _SemiDonutPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final radius = (size.width - 16) / 2;
    const start = -math.pi * 1.1;
    const sweep = math.pi * 1.2;

    // Background Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Active Progress Arc
    if (progress > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SemiDonutPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  const _TopBar({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.userMetadata?['display_name'] as String? ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.purple, width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.purple.withOpacity(0.2),
              backgroundImage: user?.userMetadata?['avatar_url'] != null
                  ? NetworkImage(user!.userMetadata!['avatar_url'] as String)
                  : null,
              child: user?.userMetadata?['avatar_url'] == null
                  ? Text(initial,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ))
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    )),
                Text(name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // Notification bell — NOT sign out
          _IconBtn(
            icon: Icons.notifications_outlined,
            onTap: () {/* TODO: open notifications */},
            badge: true,
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.search_rounded,
            onTap: () {/* TODO: search */},
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.badge = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 20),
              ),
              if (badge)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// WEEK NAV
// ═══════════════════════════════════════════════════════════════
class _WeekNav extends StatelessWidget {
  const _WeekNav();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = DateFormat('EEEE, MMMM d').format(now);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ChevronBtn(icon: Icons.chevron_left_rounded),
        Column(
          children: [
            Text(day,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            const Text('This Week',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
        _ChevronBtn(icon: Icons.chevron_right_rounded),
      ],
    );
  }
}

class _ChevronBtn extends StatelessWidget {
  const _ChevronBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {},
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.badge,
    required this.action,
    required this.onAction,
    this.badgeColor,
  });
  final String title, badge, action;
  final VoidCallback onAction;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppColors.purple).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badge,
                style: TextStyle(
                  color: badgeColor ?? AppColors.purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Text(action,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                )),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1.5),
            ),
            child: const Icon(Icons.task_alt_rounded,
                size: 36, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          const Text('All clear!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          const Text('You have no tasks yet.\nTap the + button to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              )),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.mint, Color(0xFF2BBDAE)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mint.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, color: AppColors.textDark, size: 18),
                  SizedBox(width: 6),
                  Text('Add First Task',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM NAV
// ═══════════════════════════════════════════════════════════════
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
          // Main Navigation Pill - Glassmorphic Dark
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.divider.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
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
                        label: 'Tasks',
                        icon: Icons.home_filled,
                        active: index == 0,
                        onTap: () => onTap(0),
                      ),
                      _PillNavItem(
                        label: 'Stats',
                        icon: Icons.stacked_bar_chart_rounded,
                        active: index == 1,
                        onTap: () => onTap(1),
                      ),
                      _PillNavItem(
                        label: 'Profile',
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
          // Separate Add Button - Glassmorphic Dark Circle
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
                      color: AppColors.cardBg.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.divider.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
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
          color: active ? AppColors.mint.withOpacity(0.15) : Colors.transparent,
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

// Removed _RingPainter
