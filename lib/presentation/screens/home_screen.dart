// lib/presentation/screens/home_screen.dart
//
// UX/UI Redesign v2:
//  1. Modern glassmorphism hero card with integrated progress arc
//  2. Quick stats row (overdue + upcoming count)
//  3. Enhanced dashboard cards with better iconography
//  4. Filter chips with pill design
//  5. Task list with clear visual hierarchy
//  6. Modern bottom sheet with better quick actions
//  7. Richer empty state
//  8. Consistent animation timings

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/voice_button.dart';
import '../../services/task_parser_service.dart';
import 'add_task_screen.dart';
import '../../core/database/task_model_hive.dart';

String _getInitials(String name) {
  if (name.isEmpty) return 'U';
  final parts = name.trim().split(' ');
  if (parts.length > 1 && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}

enum TaskFilter { all, today, completed }

sealed class _ListItem {}

class _LabelItem extends _ListItem {
  _LabelItem({required this.label, required this.color, required this.count});
  final String label;
  final Color color;
  final int count;
}

class _TaskItem extends _ListItem {
  _TaskItem(this.task);
  final TaskModelHive task;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TaskFilter _filter = TaskFilter.all;

  List<_ListItem> _buildListItems(
    List<TaskModelHive> visibleTasks,
    DateTime now,
    TaskFilter filter,
  ) {
    if (visibleTasks.isEmpty) return [];

    if (filter == TaskFilter.completed) {
      return visibleTasks.map(_TaskItem.new).toList();
    }

    final overdue = visibleTasks
        .where((t) => t.scheduledAt.isBefore(now) && !t.isCompleted)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final rest = visibleTasks
        .where((t) => !t.scheduledAt.isBefore(now) || t.isCompleted)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final items = <_ListItem>[];

    if (overdue.isNotEmpty) {
      items.add(_LabelItem(label: 'Overdue', color: AppColors.error, count: overdue.length));
      items.addAll(overdue.map(_TaskItem.new));
    }

    if (rest.isNotEmpty) {
      items.add(_LabelItem(label: 'Upcoming', color: AppColors.primary, count: rest.length));
      items.addAll(rest.map(_TaskItem.new));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final allTasks = context.watch<TasksNotifier>().tasks;
    final filter = _filter;
    final now = DateTime.now();

    final todayTasks = allTasks.where((t) {
      final d = t.scheduledAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();
    final overdueTasks = allTasks
        .where((t) => t.scheduledAt.isBefore(now) && !t.isCompleted)
        .toList();

    final visibleTasks = switch (filter) {
      TaskFilter.all => allTasks,
      TaskFilter.today => todayTasks,
      TaskFilter.completed => completedTasks,
    };

    final completionRatio =
        allTasks.isEmpty ? 0.0 : completedTasks.length / allTasks.length;

    final listItems = _buildListItems(visibleTasks, now, filter);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _TopAppBar(user: user),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroCard(
                                user: user,
                                completionRatio: completionRatio,
                                totalCount: allTasks.length,
                                completedCount: completedTasks.length,
                              ),
                              const SizedBox(height: 16),
                              _QuickStats(
                                overdueCount: overdueTasks.length,
                                upcomingCount: todayTasks.where((t) => !t.isCompleted).length,
                                doneToday: completedTasks.where((t) {
                                  final d = t.scheduledAt;
                                  return d.year == now.year && d.month == now.month && d.day == now.day;
                                }).length,
                              ),
                              const SizedBox(height: 20),
                              _DashboardCards(
                                todayCount: todayTasks.length,
                                completedCount: completedTasks.length,
                              ),
                              const SizedBox(height: 24),
                              _SectionHeader(
                                filter: filter,
                                count: visibleTasks.length,
                                onFilterChanged: (f) =>
                                    setState(() => _filter = f),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (visibleTasks.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
                          sliver: SliverToBoxAdapter(
                            child: _EmptyState(
                              filter: filter,
                              onAddTap: () => Navigator.push(
                                context,
                                _slideRoute(const AddTaskScreen()),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
                          sliver: SliverList.builder(
                            itemCount: listItems.length,
                            itemBuilder: (context, index) {
                              final item = listItems[index];
                              return switch (item) {
                                _LabelItem(:final label, :final color, :final count) =>
                                  _DividerLabel(label: label, color: color, count: count),
                                _TaskItem(:final task) => _AnimatedTaskItem(
                                    index: math.min(index, 10),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: TaskCard(
                                        task: task,
                                        onToggleComplete: () => context
                                            .read<TasksNotifier>()
                                            .toggleComplete(task.id),
                                        onDelete: () => context
                                            .read<TasksNotifier>()
                                            .deleteTask(task),
                                      ),
                                    ),
                                  ),
                              };
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: _BottomInputBar(
                  onAddTap: () => Navigator.push(
                    context,
                    _slideRoute(const AddTaskScreen()),
                  ),
                  onQuickAdd: (parsed) => Navigator.push(
                    context,
                    _slideRoute(AddTaskScreen(initialParsed: parsed)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Route _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP APP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Avatar(user: user),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'TaskVoice',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          Semantics(
            label: 'Sign out',
            button: true,
            child: GestureDetector(
              onTap: () => context.read<AuthNotifier>().signOut(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO CARD — glassmorphism style
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.user,
    required this.completionRatio,
    required this.totalCount,
    required this.completedCount,
  });

  final dynamic user;
  final double completionRatio;
  final int totalCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final firstName =
        (user?.displayName as String?)?.split(' ').first ?? 'there';
    final greeting = _greeting();
    final dateLabel = _todayLabel();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        greeting,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.2,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.white60),
                    const SizedBox(width: 5),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.check_circle_outline,
                      value: '$completedCount',
                      label: 'done',
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      icon: Icons.list_alt_outlined,
                      value: '$totalCount',
                      label: 'total',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ProgressRing(
            ratio: completionRatio,
            total: totalCount,
            done: completedCount,
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _todayLabel() {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d').format(now);
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS RING
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRing extends StatefulWidget {
  const _ProgressRing({
    required this.ratio,
    required this.total,
    required this.done,
  });
  final double ratio;
  final int total;
  final int done;

  @override
  State<_ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<_ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_ProgressRing old) {
    super.didUpdateWidget(old);
    if (old.ratio != widget.ratio) {
      _anim = Tween<double>(begin: old.ratio, end: widget.ratio).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl..reset()..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${(widget.ratio * 100).round()} percent complete',
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _anim.value,
              trackColor: Colors.white.withValues(alpha: 0.15),
              arcColor: Colors.white,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.total == 0
                        ? '—'
                        : '${(widget.ratio * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'done',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
  });
  final double progress;
  final Color trackColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const startAngle = -math.pi * 0.75;
    const sweepMax = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepMax,
      false,
      trackPaint,
    );

    if (progress > 0) {
      final arcPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepMax * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK STATS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.overdueCount,
    required this.upcomingCount,
    required this.doneToday,
  });

  final int overdueCount;
  final int upcomingCount;
  final int doneToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickStatCard(
          icon: Icons.warning_amber_rounded,
          value: '$overdueCount',
          label: 'Overdue',
          color: AppColors.error,
          bg: const Color(0xFFFEF2F2),
        )),
        const SizedBox(width: 12),
        Expanded(child: _QuickStatCard(
          icon: Icons.schedule_rounded,
          value: '$upcomingCount',
          label: 'Due Today',
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFFFBEB),
        )),
        const SizedBox(width: 12),
        Expanded(child: _QuickStatCard(
          icon: Icons.check_circle_rounded,
          value: '$doneToday',
          label: 'Done Today',
          color: AppColors.success,
          bg: const Color(0xFFF0FDF4),
        )),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardCards extends StatelessWidget {
  const _DashboardCards({
    required this.todayCount,
    required this.completedCount,
  });

  final int todayCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DashboardCard(
            title: "Today's Tasks",
            count: todayCount,
            icon: Icons.wb_sunny_rounded,
            iconBg: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF6366F1),
            cardBg: Colors.white,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _DashboardCard(
            title: 'Completed',
            count: completedCount,
            icon: Icons.emoji_events_rounded,
            iconBg: const Color(0xFFF0FDF4),
            iconColor: AppColors.success,
            cardBg: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.cardBg,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color cardBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              height: 1,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.filter,
    required this.count,
    required this.onFilterChanged,
  });

  final TaskFilter filter;
  final int count;
  final ValueChanged<TaskFilter> onFilterChanged;

  String get _label => switch (filter) {
        TaskFilter.today => "Today's Tasks",
        TaskFilter.completed => 'Completed',
        TaskFilter.all => 'All Tasks',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
        const Spacer(),
        _FilterChipsRow(
          filter: filter,
          onFilterChanged: onFilterChanged,
        ),
      ],
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.filter,
    required this.onFilterChanged,
  });

  final TaskFilter filter;
  final ValueChanged<TaskFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isActive: filter == TaskFilter.all,
            onTap: () => onFilterChanged(TaskFilter.all),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Today',
            isActive: filter == TaskFilter.today,
            onTap: () => onFilterChanged(TaskFilter.today),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Done',
            isActive: filter == TaskFilter.completed,
            onTap: () => onFilterChanged(TaskFilter.completed),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM INPUT BAR
// ─────────────────────────────────────────────────────────────────────────────

class _BottomInputBar extends StatelessWidget {
  const _BottomInputBar({
    required this.onAddTap,
    required this.onQuickAdd,
  });

  final VoidCallback onAddTap;
  final ValueChanged<ParsedTask> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          padding: EdgeInsets.only(
            top: 12,
            bottom: bottomPad > 0 ? bottomPad + 12 : 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick actions row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickActionChip(
                      icon: Icons.today_outlined,
                      label: 'Today',
                      color: const Color(0xFF6366F1),
                      onTap: () => onQuickAdd(
                        ParsedTask(title: 'New Task', scheduledAt: DateTime.now()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QuickActionChip(
                      icon: Icons.schedule_outlined,
                      label: 'In 1 hour',
                      color: const Color(0xFFF59E0B),
                      onTap: () => onQuickAdd(
                        ParsedTask(
                          title: 'New Task',
                          scheduledAt: DateTime.now().add(const Duration(hours: 1)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QuickActionChip(
                      icon: Icons.wb_twilight_outlined,
                      label: 'Tomorrow',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        final now = DateTime.now();
                        onQuickAdd(ParsedTask(
                          title: 'New Task',
                          scheduledAt: DateTime(now.year, now.month, now.day + 1, 9, 0),
                        ));
                      },
                    ),
                    const SizedBox(width: 8),
                    _QuickActionChip(
                      icon: Icons.calendar_month_outlined,
                      label: 'Pick date',
                      color: const Color(0xFF8B5CF6),
                      onTap: onAddTap,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Main input bar
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: onAddTap,
                        child: Container(
                          height: 44,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline,
                                  size: 18, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 10),
                              const Text(
                                'Add a new task...',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1.5,
                      height: 28,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: VoiceButton(onParsed: onQuickAdd, isCompact: true),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL as String?;
    final name = (user?.displayName as String?) ?? 'User';

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(photoUrl),
        ),
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED TASK ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedTaskItem extends StatefulWidget {
  const _AnimatedTaskItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_AnimatedTaskItem> createState() => _AnimatedTaskItemState();
}

class _AnimatedTaskItemState extends State<_AnimatedTaskItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 40),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.onAddTap});
  final TaskFilter filter;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (filter) {
      TaskFilter.today => (
          Icons.wb_sunny_outlined,
          'Clear schedule today',
          'No tasks due today. Enjoy your free time!',
        ),
      TaskFilter.completed => (
          Icons.check_circle_outline_rounded,
          'Nothing completed yet',
          'Complete a task to see it here.',
        ),
      TaskFilter.all => (
          Icons.task_outlined,
          'Start your journey',
          'Add your first task and take control of your day',
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  const Color(0xFF4F46E5).withValues(alpha: 0.03),
                ],
              ),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (filter == TaskFilter.all) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onAddTap();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Create your first task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIVIDER LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label, required this.color, required this.count});
  final String label;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count task${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
                    child: Container(height: 1, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}