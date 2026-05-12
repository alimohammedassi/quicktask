// lib/presentation/screens/home_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/models/subtask.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
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
const _kRadius = 20.0;
const _kPad = 20.0;
const _kCardPad = 16.0;
const _kGap = 14.0;

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

              // ── Stats strip ───────────────────────────────────
              _StatsStrip(pending: pending.length, completed: completed.length),
              const SizedBox(height: 20),

              // ── Hero card ─────────────────────────────────────
              _HeroCard(currentTask: currentTask),
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
                    child: TaskCard(
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
                    child: TaskCard(
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
// STATS STRIP — quick summary above hero card
// ═══════════════════════════════════════════════════════════════
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.pending, required this.completed});
  final int pending, completed;

  @override
  Widget build(BuildContext context) {
    final total = pending + completed;
    final pct = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          _StatItem(
              value: '$total', label: 'Total', color: AppColors.textPrimary),
          _VertDivider(),
          _StatItem(
              value: '$pending', label: 'Pending', color: AppColors.yellow),
          _VertDivider(),
          _StatItem(value: '$completed', label: 'Done', color: AppColors.mint),
          const Spacer(),
          // Mini completion bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(pct * 100).round()}%',
                  style: TextStyle(
                    color: AppColors.mint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 80,
                  height: 6,
                  child: Stack(
                    children: [
                      Container(color: AppColors.innerCard),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.mint, AppColors.purple],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(
      {required this.value, required this.label, required this.color});
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )),
          Text(label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              )),
        ],
      );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: AppColors.divider,
      );
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
// HERO CARD — current task + subtasks + progress arc
// ═══════════════════════════════════════════════════════════════
class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.currentTask});
  final CurrentTaskNotifier currentTask;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> with TickerProviderStateMixin {
  late AnimationController _arcCtrl;
  late Animation<double> _arcAnim;
  late ConfettiController _confettiCtrl;
  bool _hasCelebrated = false;

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _arcAnim = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOutCubic);
    _confettiCtrl =
        ConfettiController(duration: const Duration(milliseconds: 1500));
    _arcCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant _HeroCard old) {
    super.didUpdateWidget(old);
    _arcCtrl.forward(from: 0);
    final progress = widget.currentTask.progress;
    if (progress == 1.0 &&
        widget.currentTask.totalCount > 0 &&
        !_hasCelebrated) {
      _hasCelebrated = true;
      HapticFeedback.heavyImpact();
      _confettiCtrl.play();
    }
    if (progress < 1.0) _hasCelebrated = false;
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.currentTask.currentTask;

    if (task == null) return _EmptyHeroCard();

    final progress = widget.currentTask.progress;
    final allDone = progress == 1.0 && widget.currentTask.totalCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: AppColors.divider, width: 1),
            // Subtle gradient shimmer on top
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardBg,
                AppColors.cardBg,
                allDone
                    ? AppColors.gold.withOpacity(0.05)
                    : AppColors.mint.withOpacity(0.04),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: (allDone ? AppColors.gold : AppColors.mint)
                    .withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top section ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color:
                                      allDone ? AppColors.gold : AppColors.mint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text('Current task',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Task title
                          Text(task.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),

                          // Trend indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (allDone ? AppColors.gold : AppColors.mint)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  allDone
                                      ? Icons.check_rounded
                                      : Icons.trending_up_rounded,
                                  size: 12,
                                  color:
                                      allDone ? AppColors.gold : AppColors.mint,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  allDone
                                      ? 'All done!'
                                      : '${widget.currentTask.completedCount}/${widget.currentTask.totalCount} done',
                                  style: TextStyle(
                                    color: allDone
                                        ? AppColors.gold
                                        : AppColors.mint,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Category chips
                          Wrap(
                            spacing: 8,
                            children: task.categories
                                .take(2)
                                .map((c) => _TagChip(label: c))
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                    // Right column: buttons + arc
                    Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CircleIconBtn(icon: Icons.ios_share_rounded),
                            const SizedBox(width: 8),
                            _CircleIconBtn(icon: Icons.arrow_outward_rounded),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _arcAnim,
                          builder: (_, __) => _ProgressArc(
                            progress: progress * _arcAnim.value,
                            allDone: allDone,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Subtasks section ─────────────────────────────
              if (widget.currentTask.subtasks.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                          child:
                              Container(height: 1, color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.checklist_rounded,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Subtasks',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                      Expanded(
                          child:
                              Container(height: 1, color: AppColors.divider)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    children: widget.currentTask.subtasks
                        .map((s) => _SubtaskRow(
                              subtask: s,
                              onToggle: () => widget.currentTask
                                  .toggleSubtask(task.id, s.id),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Confetti
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.25,
              numberOfParticles: 20,
              maxBlastForce: 22,
              gravity: 0.3,
              colors: const [
                AppColors.mint,
                AppColors.purple,
                AppColors.yellow,
                AppColors.gold
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(color: AppColors.divider),
          // Dashed border effect via gradient
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.innerCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.push_pin_outlined,
                  color: AppColors.textHint, size: 24),
            ),
            const SizedBox(height: 12),
            const Text('No pinned task',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 4),
            const Text('Open a task and pin it as your current focus.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                )),
          ],
        ),
      );
}

// ─── Tag chip ──────────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.innerCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
      );
}

// ─── Circle icon button ────────────────────────────────────────
class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.innerCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      );
}

// ─── Progress arc ──────────────────────────────────────────────
class _ProgressArc extends StatelessWidget {
  const _ProgressArc({required this.progress, required this.allDone});
  final double progress;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final color = allDone ? AppColors.gold : AppColors.mint;
    return SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(
        painter: _SemiArcPainter(progress: progress, color: color),
        child: Center(
          child: allDone
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_rounded, color: AppColors.gold, size: 16),
                    Text('Done!',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                )
              : Text('${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  )),
        ),
      ),
    );
  }
}

class _SemiArcPainter extends CustomPainter {
  const _SemiArcPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const start = -math.pi * 0.75;
    const sweep = math.pi * 1.5;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = AppColors.innerCard
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    if (progress > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * progress,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep * progress,
            colors: [color.withOpacity(0.6), color],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SemiArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Subtask row ───────────────────────────────────────────────
class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({required this.subtask, required this.onToggle});
  final SubTask subtask;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        splashColor: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      subtask.isCompleted ? AppColors.mint : Colors.transparent,
                  border: subtask.isCompleted
                      ? null
                      : Border.all(color: AppColors.checkboxBorder, width: 1.5),
                  boxShadow: subtask.isCompleted
                      ? [
                          BoxShadow(
                            color: AppColors.mint.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: -2,
                          )
                        ]
                      : null,
                ),
                child: subtask.isCompleted
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: AppColors.textDark)
                    : null,
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: subtask.isCompleted
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight:
                        subtask.isCompleted ? FontWeight.w400 : FontWeight.w500,
                    decoration: subtask.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: AppColors.textHint,
                  ),
                  child: Text(subtask.title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed _SwipeableTaskCard, _SwipeBg, and _TaskListCard in favor of widgets/task_card.dart

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
