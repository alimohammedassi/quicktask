// lib/presentation/screens/summary_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/task_provider.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;
  static const _cardCount = 6;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims = List.generate(_cardCount, (i) {
      final start = (i * 0.1).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(_cardCount, (i) {
      final start = (i * 0.1).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Widget _anim(int index, Widget child) => FadeTransition(
        opacity: _fadeAnims[index],
        child: SlideTransition(
          position: _slideAnims[index],
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
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
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                children: [
                  _anim(0, _ActivityCard()),
                  const SizedBox(height: 16),
                  _anim(1, Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${focusHours}h',
                          label: context.translate('total_focus'),
                          color: tokens.purple,
                          change: '+${focusHours > 0 ? focusHours : 12}',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          value: '$done',
                          label: context.translate('tasks_done'),
                          color: tokens.yellow,
                          change: '+${done > 0 ? done : 12}',
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(height: 16),
                  _anim(2, _OverviewCard(cPct: cPct, iPct: iPct, oPct: oPct)),
                  const SizedBox(height: 16),
                  _anim(3, _ProductivityInsightsCard()),
                  const SizedBox(height: 16),
                  _anim(4, _CategoryBreakdownCard()),
                  const SizedBox(height: 16),
                  _anim(5, _ProcessHistoryCard()),
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
    final tokens = context.tokens;
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (canPop)
            _iconBtn(
              context,
              context.isRtl ? Icons.keyboard_arrow_right_rounded : Icons.keyboard_arrow_left_rounded,
              onTap: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 42),
          Text(
            context.translate('summary'),
            style: GoogleFonts.plusJakartaSans(
              color: tokens.textPrimary,
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

  Widget _iconBtn(BuildContext context, IconData icon, {VoidCallback? onTap}) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: tokens.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: tokens.divider.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Icon(icon, color: tokens.textPrimary, size: 22),
      ),
    );
  }
}

// ── TASK ACTIVITY CARD ──────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
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

    int highIdx = 0;
    for (int i = 0; i < counts.length; i++) {
      if (counts[i] == maxCount && maxCount > 0) highIdx = i;
    }

    final totalThisWeek = counts.reduce((a, b) => a + b);
    final avg = (totalThisWeek / 7).toStringAsFixed(1);
    final localeCode = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.mint,
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
                    context.translate('task_activity'),
                    style: GoogleFonts.plusJakartaSans(
                      color: tokens.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.translate('avg_tasks_per_day').replaceAll('{avg}', avg),
                    style: GoogleFonts.plusJakartaSans(
                      color: tokens.textDark.withValues(alpha: 0.6),
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
                child: Icon(
                  context.isRtl ? Icons.arrow_back_rounded : Icons.arrow_outward_rounded,
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
                            style: GoogleFonts.plusJakartaSans(
                              color: tokens.textDark.withValues(alpha: 0.5),
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
                      final dayDate = startOfWeek.add(Duration(days: i));
                      final weekdayName = DateFormat.E(localeCode).format(dayDate);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 18,
                            height: barH == 0 ? 4 : barH,
                            decoration: BoxDecoration(
                              color: isBold
                                  ? Colors.black
                                  : Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            weekdayName,
                            style: GoogleFonts.plusJakartaSans(
                              color: tokens.textDark.withValues(alpha: 0.7),
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
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
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
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.textDark,
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
                  style: GoogleFonts.plusJakartaSans(
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
            style: GoogleFonts.plusJakartaSans(
              color: tokens.textDark.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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
    final tokens = context.tokens;
    final hasData = cPct > 0 || iPct > 0 || oPct > 0;
    final displayCompleted = hasData ? cPct : 0.63;
    final displayInProgress = hasData ? iPct : 0.25;
    final displayOverdue = hasData ? oPct : 0.12;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: tokens.divider.withValues(alpha: 0.5),
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
                    completedColor: tokens.mint,
                    inProgressColor: tokens.purple,
                    overdueColor: tokens.divider,
                    trackColor: tokens.innerCard,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(displayCompleted * 100).round()}%',
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      context.translate('completed').toLowerCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  color: tokens.mint,
                  label: context.translate('completed'),
                  pct: '${(displayCompleted * 100).round()}%',
                ),
                const SizedBox(height: 12),
                _Legend(
                  color: tokens.purple,
                  label: context.translate('in_progress'),
                  pct: '${(displayInProgress * 100).round()}%',
                ),
                const SizedBox(height: 12),
                _Legend(
                  color: tokens.divider,
                  label: context.translate('overdue'),
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
    required this.trackColor,
  });

  final double completed, inProgress, overdue;
  final Color completedColor, inProgressColor, overdueColor, trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 6;
    const strokeW = 10.0;
    const gap = 0.06; // gap in radians
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
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
      old.overdue != overdue ||
      old.trackColor != trackColor;
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
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
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
            style: GoogleFonts.plusJakartaSans(
              color: tokens.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          pct,
          style: GoogleFonts.plusJakartaSans(
            color: tokens.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ── PRODUCTIVITY INSIGHTS CARD ──────────────────────────────
class _ProductivityInsightsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
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

    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final dayDate = startOfWeek.add(Duration(days: maxDayIdx - 1));
    final localizedProductiveDay = maxDayVal > 0
        ? DateFormat.EEEE(Localizations.localeOf(context).languageCode).format(dayDate)
        : context.translate('no_tasks_completed');

    final streakText = streak == 1
        ? context.translate('streak_day').replaceAll('{count}', '1')
        : context.translate('streak_days').replaceAll('{count}', '$streak');

    final streakSubtitle = streak > 0 ? context.translate('keep_it_up') : context.translate('complete_a_task');
    final consistencySubtitle = consistencyScore > 70 ? context.translate('highly_reliable') : context.translate('room_to_grow');
    final productiveSubtitle = maxDayVal > 0
        ? context.translate('tasks_completed_count').replaceAll('{count}', '$maxDayVal')
        : context.translate('no_tasks_completed');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: tokens.divider.withValues(alpha: 0.5),
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
                context.translate('productivity_insights'),
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                Icons.insights_rounded,
                color: tokens.textSecondary.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: context.translate('current_streak'),
                  value: streakText,
                  subtitle: streakSubtitle,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricTile(
                  label: context.translate('consistency'),
                  value: '$consistencyScore%',
                  subtitle: consistencySubtitle,
                  icon: Icons.ads_click_rounded,
                  iconColor: tokens.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MetricTile(
            label: context.translate('most_productive_day'),
            value: localizedProductiveDay,
            subtitle: productiveSubtitle,
            icon: Icons.calendar_today_rounded,
            iconColor: tokens.purple,
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
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.innerCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tokens.divider.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
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
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.textSecondary.withValues(alpha: 0.6),
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

Color _getCategoryColor(String cat, BuildContext context) {
  final tokens = context.tokens;
  switch (cat.toLowerCase().trim()) {
    case 'work':
      return tokens.purple;
    case 'personal':
      return tokens.mint;
    case 'health':
    case 'fitness':
      return tokens.error;
    case 'study':
    case 'learning':
      return tokens.yellow;
    case 'family':
    case 'home':
      return tokens.gold;
    default:
      return tokens.mint;
  }
}

// ── CATEGORY BREAKDOWN CARD ────────────────────────────────
class _CategoryBreakdownCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
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
          color: tokens.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: tokens.divider.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate('category_progress'),
              style: GoogleFonts.plusJakartaSans(
                color: tokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.translate('no_categories_yet'),
              style: GoogleFonts.plusJakartaSans(
                color: tokens.textSecondary,
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


    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: tokens.divider.withValues(alpha: 0.5),
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
                context.translate('category_progress'),
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                Icons.pie_chart_outline_rounded,
                color: tokens.textSecondary.withValues(alpha: 0.5),
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
            final color = _getCategoryColor(cat, context);

            final categoryLabel = ['Work', 'Personal', 'Health', 'Study', 'Family', 'Shopping', 'General'].contains(cat)
                ? context.translate('cat_${cat.toLowerCase()}')
                : cat;

            final completedRatioText = context.translate('completed_ratio')
                .replaceAll('{completed}', '$completed')
                .replaceAll('{total}', '$total')
                .replaceAll('{percent}', '$percent');

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryLabel,
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        completedRatioText,
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.textSecondary,
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
                          color: tokens.innerCard,
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
    final tokens = context.tokens;
    final completed = context.watch<TasksNotifier>().completedTasks;

    final recent = completed.toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    final displayTasks = recent.take(5).toList();
    final localeCode = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: tokens.divider.withValues(alpha: 0.5),
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
                context.translate('process_history'),
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                Icons.history_rounded,
                color: tokens.textSecondary.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (displayTasks.isEmpty)
            Text(
              context.translate('no_completed_history'),
              style: GoogleFonts.plusJakartaSans(
                color: tokens.textSecondary,
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
                final formattedDate = DateFormat('d MMM', localeCode).format(task.scheduledAt);

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
                              color: tokens.mint.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: tokens.mint,
                              size: 14,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: tokens.divider.withValues(alpha: 0.4),
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
                                style: GoogleFonts.plusJakartaSans(
                                  color: tokens.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: tokens.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (task.categories.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: tokens.textSecondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Wrap(
                                      spacing: 4,
                                      children: task.categories
                                          .map((c) {
                                            final categoryLabel = ['Work', 'Personal', 'Health', 'Study', 'Family', 'Shopping', 'General'].contains(c)
                                                ? context.translate('cat_${c.toLowerCase()}')
                                                : c;
                                            return Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: tokens.innerCard,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                categoryLabel,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: tokens.textPrimary,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          })
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
}

