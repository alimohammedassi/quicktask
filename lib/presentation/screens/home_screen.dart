// lib/presentation/screens/home_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/voice_button.dart';
import '../../services/task_parser_service.dart';
import 'add_task_screen.dart';

String _getInitials(String name) {
  if (name.isEmpty) return 'U';
  final parts = name.trim().split(' ');
  if (parts.length > 1 && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}

enum TaskFilter { all, today, completed }

final _taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateStreamProvider).valueOrNull;
    final allTasks = ref.watch(tasksNotifierProvider);
    final filter = ref.watch(_taskFilterProvider);

    final now = DateTime.now();
    final todayTasks = allTasks.where((t) {
      final d = t.scheduledAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();

    final visibleTasks = switch (filter) {
      TaskFilter.all => allTasks,
      TaskFilter.today => todayTasks,
      TaskFilter.completed => completedTasks,
    };

    // Completion ratio for the progress arc
    final completionRatio =
        allTasks.isEmpty ? 0.0 : completedTasks.length / allTasks.length;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle decorative gradient blob in top-right
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.07),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopAppBar(user: user),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    children: [
                      // Hero section — greeting + progress arc side by side
                      _HeroSection(
                        user: user,
                        completionRatio: completionRatio,
                        totalCount: allTasks.length,
                        completedCount: completedTasks.length,
                      ),
                      const SizedBox(height: 28),

                      // Dashboard cards
                      // Dashboard cards
                      _DashboardCards(
                        todayCount: todayTasks.length,
                        completedCount: completedTasks.length,
                        totalCount: allTasks.length,
                      ),
                      const SizedBox(height: 36),

                      // Section header
                      _SectionHeader(
                        filter: filter,
                        count: visibleTasks.length,
                        onFilterChanged: (f) =>
                            ref.read(_taskFilterProvider.notifier).state = f,
                      ),
                      const SizedBox(height: 14),

                      // Task list or empty state
                      if (visibleTasks.isEmpty)
                        _EmptyState(
                          filter: filter,
                          onAddTap: () => Navigator.push(
                            context,
                            _slideRoute(const AddTaskScreen()),
                          ),
                        )
                      else
                        ...() {
                          bool hasShownOverdue = false;
                          bool hasShownUpcoming = false;
                          
                          return List.generate(visibleTasks.length, (i) {
                            final task = visibleTasks[i];
                            final isOverdue = task.scheduledAt.isBefore(now) && !task.isCompleted;

                            Widget? divider;
                            if (isOverdue && !hasShownOverdue) {
                              hasShownOverdue = true;
                              divider = const _DividerLabel(label: 'Overdue', color: AppColors.error);
                            } else if (!isOverdue && !hasShownUpcoming) {
                              hasShownUpcoming = true;
                              divider = const _DividerLabel(label: 'Upcoming', color: AppColors.primary);
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (divider != null) divider,
                                _AnimatedTaskItem(
                                  index: i,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: TaskCard(
                                      task: task,
                                      onDelete: () => ref
                                          .read(tasksNotifierProvider.notifier)
                                          .deleteTask(task),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          });
                        }(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _BottomInputBar(
        onAddTap: () => Navigator.push(
          context,
          _slideRoute(const AddTaskScreen()),
        ),
        onQuickAdd: (parsed) => Navigator.push(
          context,
          _slideRoute(AddTaskScreen(initialParsed: parsed)),
        ),
      ),
    );
  }

  Route _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );
}

// ─────────────────────────────────────────────
// TOP APP BAR
// ─────────────────────────────────────────────

class _TopAppBar extends ConsumerWidget {
  const _TopAppBar({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Avatar(user: user),
          // Brand mark
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'TaskVoice',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          // Settings / sign-out
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HERO SECTION — greeting + progress arc
// ─────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Text block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                firstName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Animated progress arc
        _ProgressArc(
          ratio: completionRatio,
          total: totalCount,
          done: completedCount,
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤';
    return 'Good Evening 🌙';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ─────────────────────────────────────────────
// PROGRESS ARC
// ─────────────────────────────────────────────

class _ProgressArc extends StatefulWidget {
  const _ProgressArc({
    required this.ratio,
    required this.total,
    required this.done,
  });
  final double ratio;
  final int total;
  final int done;

  @override
  State<_ProgressArc> createState() => _ProgressArcState();
}

class _ProgressArcState extends State<_ProgressArc>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_ProgressArc old) {
    super.didUpdateWidget(old);
    if (old.ratio != widget.ratio) {
      _anim = Tween<double>(begin: old.ratio, end: widget.ratio)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: 86,
        height: 86,
        child: CustomPaint(
          painter: _ArcPainter(
            progress: _anim.value * widget.ratio,
            trackColor: AppColors.primary.withValues(alpha: 0.08),
            arcColor: AppColors.primary,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.total == 0 ? '—' : '${(widget.ratio * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.total == 0
                      ? 'no tasks'
                      : (widget.ratio == 1.0
                          ? 'All done! 🎉'
                          : (widget.ratio == 0.0 && widget.total > 0
                              ? 'Let\'s go!'
                              : 'done')),
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.ratio == 1.0
                        ? AppColors.success
                        : (widget.ratio == 0.0 && widget.total > 0
                            ? AppColors.primary
                            : AppColors.textSecondary),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
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
    final radius = (size.width - 10) / 2;
    const startAngle = -math.pi * 0.75;
    const sweepMax = math.pi * 1.5;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepMax,
      false,
      trackPaint,
    );

    // Progress arc
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
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
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// DASHBOARD CARDS
// ─────────────────────────────────────────────

class _DashboardCards extends StatelessWidget {
  const _DashboardCards({
    required this.todayCount,
    required this.completedCount,
    required this.totalCount,
  });

  final int todayCount;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DashboardCard(
            title: "Today",
            subtitle: "scheduled",
            count: todayCount,
            icon: Icons.wb_sunny_rounded,
            accentColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _DashboardCard(
            title: "Done",
            subtitle: "of $totalCount total",
            count: completedCount,
            icon: Icons.check_circle_rounded,
            accentColor: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon chip
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 16),
          // Count
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────

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
        TaskFilter.completed => "Completed",
        TaskFilter.all => "All Tasks",
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _label,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isActive: filter == TaskFilter.all,
                onTap: () => onFilterChanged(TaskFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Today',
                isActive: filter == TaskFilter.today,
                onTap: () => onFilterChanged(TaskFilter.today),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Done',
                isActive: filter == TaskFilter.completed,
                onTap: () => onFilterChanged(TaskFilter.completed),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM INPUT BAR
// ─────────────────────────────────────────────

class _BottomInputBar extends StatelessWidget {
  const _BottomInputBar({
    required this.onAddTap,
    required this.onQuickAdd,
  });

  final VoidCallback onAddTap;
  final ValueChanged<ParsedTask> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bgLight,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _QuickChip(
                    label: '📅 Today',
                    onTap: () => onQuickAdd(ParsedTask(title: 'New Task', scheduledAt: DateTime.now())),
                  ),
                  const SizedBox(width: 8),
                  _QuickChip(
                    label: '⏰ In 1 hour',
                    onTap: () => onQuickAdd(ParsedTask(title: 'New Task', scheduledAt: DateTime.now().add(const Duration(hours: 1)))),
                  ),
                  const SizedBox(width: 8),
                  _QuickChip(
                    label: '🌅 Tomorrow morning',
                    onTap: () {
                      final now = DateTime.now();
                      final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0);
                      onQuickAdd(ParsedTask(title: 'New Task', scheduledAt: tomorrow));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onAddTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.edit_outlined, size: 15, color: AppColors.textHint),
                            SizedBox(width: 8),
                            Text('Add a task...', style: TextStyle(color: AppColors.textHint, fontSize: 14, fontWeight: FontWeight.w500)),
                            Spacer(),
                            Text('or type', style: TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: VoiceButton(onParsed: onQuickAdd),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AVATAR
// ─────────────────────────────────────────────

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
          border: Border.all(color: AppColors.cardBorder, width: 2),
        ),
        child: CircleAvatar(
          radius: 19,
          backgroundImage: NetworkImage(photoUrl),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ANIMATED TASK ITEM
// ─────────────────────────────────────────────

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
      duration: Duration(milliseconds: 280 + widget.index * 35),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: widget.index * 45), () {
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

// ─────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.onAddTap});
  final TaskFilter filter;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (filter) {
      TaskFilter.today => (
          Icons.wb_sunny_outlined,
          'Nothing today',
          'Enjoy your free day!',
        ),
      TaskFilter.completed => (
          Icons.check_circle_outline_rounded,
          'No completed tasks',
          'Finish a task to see it here.',
        ),
      TaskFilter.all => (
          Icons.mic_none_rounded,
          'No tasks yet',
          'Tap the mic and speak your first task!',
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Layered circles
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.04),
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.07),
                  ),
                ),
                Icon(icon, color: AppColors.primary, size: 30),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onAddTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Add your first task', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _DividerLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: color.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}
