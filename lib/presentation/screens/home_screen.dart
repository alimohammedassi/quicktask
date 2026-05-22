// lib/presentation/screens/home_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/task_provider.dart';
import '../providers/current_task_provider.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import 'summary_screen.dart';
import 'profile_screen.dart';
import '../widgets/task_card.dart';
import '../../core/database/task_model_hive.dart';
import '../../domain/models/subtask.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens (consistent 8dp rhythm)
// ─────────────────────────────────────────────────────────────
const _kPad = 20.0;
const _kGap = 4.2;

// ═══════════════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _navIdx = 0;
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  // ── Staggered entrance animations ──────────────────────────
  late final AnimationController _entranceCtrl;
  late final Animation<double> _topBarAnim;
  late final Animation<double> _weekNavAnim;
  late final Animation<double> _mintCardAnim;
  late final Animation<Offset> _mintCardSlide;
  late final Animation<double> _taskListAnim;
  late final Animation<double> _navBarAnim;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _fabScale = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut));

    // Stagger controller — 900ms total for smooth cascade
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _topBarAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _weekNavAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
    );
    _mintCardAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic),
    );
    _mintCardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_mintCardAnim);
    _taskListAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    _navBarAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildBody(),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1.2),
                  end: Offset.zero,
                ).animate(_navBarAnim),
                child: FadeTransition(
                  opacity: _navBarAnim,
                  child: _BottomNav(
                    index: _navIdx,
                    fabCtrl: _fabCtrl,
                    fabScale: _fabScale,
                    onTap: (i) {
                      if (i == 2) {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                            context, _slideUp(const AddTaskScreen()));
                        return;
                      }
                      if (i == 1) {
                        Navigator.push(
                            context, _slideUp(const SummaryScreen()));
                        return;
                      }
                      if (i == 4) {
                        Navigator.push(
                            context, _slideUp(const ProfileScreen()));
                        return;
                      }
                      HapticFeedback.selectionClick();
                      setState(() => _navIdx = i);
                    },
                  ),
                ),
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
              // ── Top bar with fade-in ───────────────────────────
              FadeTransition(
                opacity: _topBarAnim,
                child: _TopBar(user: user),
              ),
              const SizedBox(height: 16),

              // ── Week nav with fade-in ──────────────────────────
              FadeTransition(
                opacity: _weekNavAnim,
                child: const _WeekNav(),
              ),
              const SizedBox(height: 20),

              // ── Current Task Mint Card with slide-up ───────────
              SlideTransition(
                position: _mintCardSlide,
                child: FadeTransition(
                  opacity: _mintCardAnim,
                  child: _CurrentTaskMintCard(
                    currentTaskNotifier: currentTask,
                    completedTasks: completed,
                    pendingTasks: pending,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Pending tasks ─────────────────────────────────
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                  title: context.translate('all_tasks'),
                  badge: '${pending.length}',
                  action: context.translate('see_all'),
                  onAction: () {},
                ),
                const SizedBox(height: _kGap),
                ...List.generate(pending.length, (i) {
                  final task = pending[i];
                  return _StaggeredTaskItem(
                    index: i,
                    parentAnimation: _taskListAnim,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: _kGap),
                      child: AllTaskTile(
                        task: task,
                        onTap: () => _openDetail(task),
                        onToggleComplete: () => _completeTask(notifier, task),
                        onDelete: () => _deleteTask(notifier, task),
                      ),
                    ),
                  );
                }),
              ],

              // ── Completed tasks ───────────────────────────────
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader(
                  title: context.translate('completed'),
                  badge: '${completed.length}',
                  action: context.translate('clear_all'),
                  onAction: () {},
                  badgeColor: context.tokens.mint,
                ),
                const SizedBox(height: _kGap),
                ...List.generate(completed.length, (i) {
                  final task = completed[i];
                  return _StaggeredTaskItem(
                    index: i,
                    parentAnimation: _taskListAnim,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: _kGap),
                      child: AllTaskTile(
                        task: task,
                        onTap: () => _openDetail(task),
                        onToggleComplete: () => _completeTask(notifier, task),
                        onDelete: () => _deleteTask(notifier, task),
                      ),
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
    await Navigator.of(context, rootNavigator: true)
        .push(_slideUp(TaskDetailScreen(task: task)));
    if (mounted) setState(() {});
  }

  void _completeTask(TasksNotifier notifier, TaskModelHive task) {
    final tokens = context.tokens;
    HapticFeedback.mediumImpact();
    notifier.toggleComplete(task.id);
    final currentTask = context.read<CurrentTaskNotifier>();
    if (currentTask.currentTaskId == task.id) {
      currentTask.clearCurrentTask();
    }
    _showSnackBar(
      icon: task.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
      message: task.isCompleted
          ? context.translate('marked_pending_toast')
          : context.translate('task_completed_toast'),
      color: task.isCompleted ? tokens.purple : tokens.mint,
      action: SnackBarAction(
        label: context.translate('undo'),
        textColor: tokens.textDark,
        onPressed: () => notifier.toggleComplete(task.id),
      ),
    );
  }

  void _deleteTask(TasksNotifier notifier, TaskModelHive task) {
    final tokens = context.tokens;
    HapticFeedback.heavyImpact();
    notifier.deleteTask(task);
    final currentTask = context.read<CurrentTaskNotifier>();
    if (currentTask.currentTaskId == task.id) {
      currentTask.clearCurrentTask();
    }
    _showSnackBar(
      icon: Icons.delete_rounded,
      message: '"${task.title}" ${context.translate('deleted_toast')}',
      color: tokens.error,
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
            color: Colors.white.withValues(alpha: 0.15),
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
        transitionsBuilder: (_, a, __, child) {
          final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                  parent: a,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
            ),
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      );
}

// ═══════════════════════════════════════════════════════════════
// STAGGERED TASK ITEM — cascading fade+slide for each card
// ═══════════════════════════════════════════════════════════════
class _StaggeredTaskItem extends StatefulWidget {
  const _StaggeredTaskItem({
    required this.index,
    required this.parentAnimation,
    required this.child,
  });

  final int index;
  final Animation<double> parentAnimation;
  final Widget child;

  @override
  State<_StaggeredTaskItem> createState() => _StaggeredTaskItemState();
}

class _StaggeredTaskItemState extends State<_StaggeredTaskItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
    ));

    // Trigger after a staggered delay based on index
    final delayMs = 80 + (widget.index * 60);
    if (widget.parentAnimation.isCompleted) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      widget.parentAnimation.addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.forward) {
          Future.delayed(Duration(milliseconds: delayMs), () {
            if (mounted) _ctrl.forward();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
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
    final tokens = context.tokens;
    final focusTask = currentTaskNotifier.currentTask ??
        (pendingTasks.isNotEmpty ? pendingTasks.first : null);

    // Title determination: Pinned task or first pending task, otherwise "No active tasks"
    final String focusTaskTitle = focusTask != null
        ? focusTask.title
        : context.translate('no_active_tasks');

    // Progress determination: Pinned task's subtasks progress, otherwise overall progress
    final double focusProgress;
    if (focusTask != null) {
      focusProgress = currentTaskNotifier.progressForTask(focusTask.id);
    } else {
      final total = completedTasks.length + pendingTasks.length;
      focusProgress = total == 0 ? 0.0 : completedTasks.length / total;
    }

    // Categories: Pinned task's categories, or first pending's categories, or default
    final List<String> categories =
        focusTask != null ? focusTask.categories : [];

    final displayCategories = categories.isEmpty ? ['QuickTask'] : categories;

    final taskSubs = focusTask != null
        ? currentTaskNotifier.subtasksForTask(focusTask.id)
        : <SubTask>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.mint,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tokens.mint.withValues(alpha: 0.12),
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
                      context.translate('current_tasks').toUpperCase(),
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.4),
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
                    // Subtask checklist
                    if (focusTask != null && taskSubs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...taskSubs.take(3).map((sub) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                currentTaskNotifier.toggleSubtask(
                                    focusTask.id, sub.id);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: sub.isCompleted
                                          ? Colors.black
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: sub.isCompleted
                                            ? Colors.black
                                            : Colors.black
                                                .withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: sub.isCompleted
                                        ? Center(
                                            child: Icon(
                                              Icons.check_rounded,
                                              size: 11,
                                              color: tokens.mint,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      sub.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: sub.isCompleted
                                            ? Colors.black
                                                .withValues(alpha: 0.4)
                                            : Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        decoration: sub.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor:
                                            Colors.black.withValues(alpha: 0.4),
                                        decorationThickness: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded,
                              color: Colors.black, size: 12),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
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
                        child: Icon(Icons.share_rounded,
                            color: Colors.black, size: 16),
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
                          transitionsBuilder: (_, a, __, child) =>
                              SlideTransition(
                            position: Tween(
                                    begin: const Offset(0, 1), end: Offset.zero)
                                .animate(CurvedAnimation(
                                    parent: a, curve: Curves.easeOutCubic)),
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
                        child: Icon(Icons.arrow_outward_rounded,
                            color: Colors.white, size: 16),
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

class _SemiDonutGauge extends StatefulWidget {
  const _SemiDonutGauge({required this.progress});
  final double progress;

  @override
  State<_SemiDonutGauge> createState() => _SemiDonutGaugeState();
}

class _SemiDonutGaugeState extends State<_SemiDonutGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    // Short delay so the card has time to slide in first
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(covariant _SemiDonutGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final value = _progressAnim.value;
        return SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _SemiDonutPainter(progress: value),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    context.translate('done'),
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        ..color = Colors.black.withValues(alpha: 0.08)
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
    final tokens = context.tokens;
    final name = user?.userMetadata?['display_name'] as String? ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: tokens.divider.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.05 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            children: [
              // Avatar with dual gradient border and outer glow shadow
              Container(
                width: 52,
                height: 52,
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
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2.5),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: tokens.cardBg,
                  backgroundImage: user?.userMetadata?['avatar_url'] != null
                      ? NetworkImage(
                          user!.userMetadata!['avatar_url'] as String)
                      : null,
                  child: user?.userMetadata?['avatar_url'] == null
                      ? Text(initial,
                          style: GoogleFonts.plusJakartaSans(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ))
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.translate('welcome_back'),
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Calendar Sync Pill
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: tokens.mint, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Synced with Google Calendar',
                            style: GoogleFonts.plusJakartaSans(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: tokens.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: tokens.divider.withValues(alpha: 0.5)),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.mint.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tokens.mint.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: tokens.mint,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      // Pulse Indicator dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: tokens.mint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: tokens.mint,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WEEK NAV
// ═══════════════════════════════════════════════════════════════
class _WeekNav extends StatelessWidget {
  const _WeekNav();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    final day = DateFormat('EEEE, MMMM d', locale).format(now);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ChevronBtn(icon: Icons.chevron_left_rounded),
        Column(
          children: [
            Text(day,
                style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            Text(context.translate('this_week'),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 25,
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
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tokens.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.divider),
        ),
        child: Icon(icon, color: tokens.textPrimary, size: 20),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Text(title,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (badgeColor ?? tokens.purple).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(badge,
              style: TextStyle(
                color: badgeColor ?? tokens.purple,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              )),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(action,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 13,
              )),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE — with breathing pulse
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatefulWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    // Breathing pulse on the icon
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Fade-in entrance
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: tokens.cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.divider, width: 1.5),
                ),
                child: Icon(Icons.task_alt_rounded,
                    size: 36, color: tokens.textHint),
              ),
            ),
            const SizedBox(height: 20),
            Text(context.translate('all_clear'),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 8),
            Text(context.translate('empty_state_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                )),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: widget.onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tokens.mint, Theme.of(context).brightness == Brightness.light ? const Color(0xFF23A196) : const Color(0xFF2BBDAE)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.mint.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        color: tokens.textDark, size: 18),
                    const SizedBox(width: 6),
                    Text(context.translate('add_first_task'),
                        style: TextStyle(
                          color: tokens.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final tokens = context.tokens;
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
                    color: tokens.cardBg.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: tokens.divider.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.08 : 0.3),
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
                      color: tokens.cardBg.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tokens.divider.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.08 : 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: tokens.mint,
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
    final tokens = context.tokens;
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
          color: active
              ? tokens.mint.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? tokens.mint : tokens.textSecondary,
            ),
            if (active) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: tokens.mint,
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
