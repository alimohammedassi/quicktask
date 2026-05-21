// lib/presentation/screens/summary_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/task_provider.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<TasksNotifier>();
    final total = n.tasks.length;
    final done = n.completedTasks.length;
    final pending = n.pendingTasks.length;
    final overdue = n.overdueTasks.length;

    final cPct = total == 0 ? 0.0 : done / total;
    final iPct = total == 0 ? 0.0 : pending / total;
    final oPct = total == 0 ? 0.0 : overdue / total;

    // Consistency calculations
    final focusHours = done; // 1 hour per completed task to match home_screen

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                children: [
                  _ActivityCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${focusHours}h',
                          label: 'Total Focus',
                          color: AppColors.purple,
                          change: '+${focusHours > 0 ? focusHours : 12}',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          value: '$done',
                          label: 'Tasks Done',
                          color: AppColors.yellow,
                          change: '+${done > 0 ? done : 12}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _OverviewCard(cPct: cPct, iPct: iPct, oPct: oPct),
                  const SizedBox(height: 16),
                  _ProductivityInsightsCard(),
                  const SizedBox(height: 16),
                  _CategoryBreakdownCard(),
                  const SizedBox(height: 16),
                  _ProcessHistoryCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── APP BAR ──────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (canPop)
            _iconBtn(
              context,
              Icons.keyboard_arrow_left_rounded,
              onTap: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 42),
          Text(
            'Summary',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          _iconBtn(
            context,
            Icons.more_horiz_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.divider.withOpacity(0.5),
              width: 1.2,
            ),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      );
}

// ── TASK ACTIVITY CARD ──────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksNotifier>().tasks;
    final counts = List.filled(7, 0);
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    for (var t in tasks) {
      if (t.scheduledAt
              .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          t.scheduledAt.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        final idx = t.scheduledAt.weekday - 1;
        if (idx >= 0 && idx < 7) {
          counts[idx]++;
        }
      }
    }

    final maxCount = counts.reduce(math.max);
    final yMax = maxCount < 4 ? 4 : maxCount + (maxCount % 2 == 0 ? 0 : 1);

    final yLabels = [
      yMax.toString(),
      (yMax * 0.75).round().toString(),
      (yMax * 0.5).round().toString(),
      (yMax * 0.25).round().toString(),
      '0',
    ];

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    int highIdx = 0;
    for (int i = 0; i < counts.length; i++) {
      if (counts[i] == maxCount && maxCount > 0) highIdx = i;
    }

    final totalThisWeek = counts.reduce((a, b) => a + b);
    final avg = (totalThisWeek / 7).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Activity',
                    style: GoogleFonts.outfit(
                      color: AppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Avg $avg tasks per day',
                    style: GoogleFonts.outfit(
                      color: AppColors.textDark.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: yLabels
                      .map((l) => Text(
                            l,
                            style: GoogleFonts.outfit(
                              color: AppColors.textDark.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (i) {
                      final barH = yMax > 0 ? (counts[i] / yMax) * 85 : 0.0;
                      final isBold = i == highIdx && maxCount > 0;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 18,
                            height: barH == 0 ? 4 : barH,
                            decoration: BoxDecoration(
                              color: isBold
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            days[i],
                            style: GoogleFonts.outfit(
                              color: AppColors.textDark.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    }),
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

// ── STAT CARD ────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.change,
  });

  final String value, label, change;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 124,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: AppColors.textDark,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    change,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.textDark.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

// ── OVERVIEW CARD (Donut + Legend) ───────────────────────────
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.cPct,
    required this.iPct,
    required this.oPct,
  });

  final double cPct, iPct, oPct;

  @override
  Widget build(BuildContext context) {
    final hasData = cPct > 0 || iPct > 0 || oPct > 0;
    final displayCompleted = hasData ? cPct : 0.63;
    final displayInProgress = hasData ? iPct : 0.25;
    final displayOverdue = hasData ? oPct : 0.12;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(100, 100),
                  painter: _DonutPainter(
                    completed: displayCompleted,
                    inProgress: displayInProgress,
                    overdue: displayOverdue,
                    completedColor: AppColors.mint,
                    inProgressColor: AppColors.purple,
                    overdueColor: Colors.white.withOpacity(0.15),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(displayCompleted * 100).round()}%',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      'done',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(
                  color: AppColors.mint,
                  label: 'Completed',
                  pct: '${(displayCompleted * 100).round()}%',
                ),
                const SizedBox(height: 12),
                _Legend(
                  color: AppColors.purple,
                  label: 'In Progress',
                  pct: '${(displayInProgress * 100).round()}%',
                ),
                const SizedBox(height: 12),
                _Legend(
                  color: Colors.white.withOpacity(0.15),
                  label: 'Overdue',
                  pct: '${(displayOverdue * 100).round()}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── DONUT PAINTER ────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.completed,
    required this.inProgress,
    required this.overdue,
    required this.completedColor,
    required this.inProgressColor,
    required this.overdueColor,
  });

  final double completed, inProgress, overdue;
  final Color completedColor, inProgressColor, overdueColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 6;
    const strokeW = 10.0;
    const gap = 0.06; // gap in radians
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    final segments = [
      (completed, completedColor),
      (inProgress, inProgressColor),
      (overdue, overdueColor),
    ];

    double angle = startAngle;
    final total = completed + inProgress + overdue;

    if (total > 0) {
      for (final (pct, color) in segments) {
        if (pct <= 0) continue;
        final sweep = (pct / total) * (2 * math.pi) - gap;
        if (sweep <= 0) continue;

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          angle,
          sweep,
          false,
          paint,
        );
        angle += sweep + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.completed != completed ||
      old.inProgress != inProgress ||
      old.overdue != overdue;
}

// ── LEGEND ROW ───────────────────────────────────────────────
class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.pct,
  });

  final Color color;
  final String label, pct;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            pct,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}

// ── PRODUCTIVITY INSIGHTS CARD ──────────────────────────────
class _ProductivityInsightsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final n = context.watch<TasksNotifier>();
    final allTasks = n.tasks;
    final completed = n.completedTasks;
    final totalCount = allTasks.length;

    final consistencyScore = totalCount == 0 ? 0 : ((completed.length / totalCount) * 100).round();

    // Streak Calculation
    final completedDates = completed.map((t) {
      final d = t.scheduledAt;
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    int streak = 0;
    final today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    if (!completedDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (completedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Most Productive Day
    final weekdayCounts = List.filled(8, 0);
    for (var t in completed) {
      if (t.scheduledAt.weekday >= 1 && t.scheduledAt.weekday <= 7) {
        weekdayCounts[t.scheduledAt.weekday]++;
      }
    }

    int maxDayIdx = 1;
    int maxDayVal = 0;
    for (int i = 1; i <= 7; i++) {
      if (weekdayCounts[i] > maxDayVal) {
        maxDayVal = weekdayCounts[i];
        maxDayIdx = i;
      }
    }

    final daysMap = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    final mostProductiveDay = maxDayVal > 0 ? daysMap[maxDayIdx] : 'None';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productivity Insights',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                Icons.insights_rounded,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Current Streak',
                  value: '$streak ${streak == 1 ? "Day" : "Days"}',
                  subtitle: streak > 0 ? 'Keep it up! 🔥' : 'Complete a task!',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricTile(
                  label: 'Consistency',
                  value: '$consistencyScore%',
                  subtitle: consistencyScore > 70 ? 'Highly Reliable 🎯' : 'Room to grow 🌱',
                  icon: Icons.ads_click_rounded,
                  iconColor: AppColors.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MetricTile(
            label: 'Most Productive Day',
            value: mostProductiveDay!,
            subtitle: maxDayVal > 0 ? '$maxDayVal tasks completed' : 'No tasks completed yet',
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.purple,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.fullWidth = false,
  });

  final String label, value, subtitle;
  final IconData icon;
  final Color iconColor;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.innerCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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

// ── CATEGORY BREAKDOWN CARD ────────────────────────────────
class _CategoryBreakdownCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final n = context.watch<TasksNotifier>();
    final allTasks = n.tasks;

    final mapTotal = <String, int>{};
    final mapCompleted = <String, int>{};

    for (var t in allTasks) {
      final cats = t.categories.isEmpty ? ['General'] : t.categories;
      for (var c in cats) {
        final cleanCat = c.trim();
        if (cleanCat.isEmpty) continue;
        mapTotal[cleanCat] = (mapTotal[cleanCat] ?? 0) + 1;
        if (t.isCompleted) {
          mapCompleted[cleanCat] = (mapCompleted[cleanCat] ?? 0) + 1;
        }
      }
    }

    if (mapTotal.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.divider.withOpacity(0.5),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Progress',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No categories found yet. Add categories to your tasks!',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final sortedCategories = mapTotal.keys.toList()
      ..sort((a, b) => mapTotal[b]!.compareTo(mapTotal[a]!));

    final colors = [AppColors.mint, AppColors.purple, AppColors.yellow];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Progress',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                Icons.pie_chart_outline_rounded,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(sortedCategories.length, (idx) {
            final cat = sortedCategories[idx];
            final total = mapTotal[cat] ?? 0;
            final completed = mapCompleted[cat] ?? 0;
            final ratio = total == 0 ? 0.0 : completed / total;
            final percent = (ratio * 100).round();
            final color = colors[idx % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cat,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$completed/$total completed ($percent%)',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── PROCESS HISTORY CARD ──────────────────────────────────
class _ProcessHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final completed = context.watch<TasksNotifier>().completedTasks;

    final recent = completed.toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    final displayTasks = recent.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Process History',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                Icons.history_rounded,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (displayTasks.isEmpty)
            Text(
              'No completed tasks yet. Finish a task to start your history!',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayTasks.length,
              itemBuilder: (context, idx) {
                final task = displayTasks[idx];
                final isLast = idx == displayTasks.length - 1;
                final formattedDate =
                    "${task.scheduledAt.day} ${_getMonthName(task.scheduledAt.month)}";

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.mint.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColors.mint,
                              size: 14,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppColors.divider.withOpacity(0.4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (task.categories.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: AppColors.textSecondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Wrap(
                                      spacing: 4,
                                      children: task.categories
                                          .map((c) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.innerCard,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  c,
                                                  style: GoogleFonts.outfit(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
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
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
