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

    final cPct = total == 0 ? 0.43 : done / total;
    final iPct = total == 0 ? 0.25 : pending / total;
    final oPct = total == 0 ? 0.10 : overdue / total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                children: [
                  _ActivityCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              value: '${total > 0 ? pending : 13}h',
                              label: 'Total Focus',
                              color: AppColors.purple,
                              change: '+12')),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _StatCard(
                              value: '${total > 0 ? done : 43}',
                              label: 'Tasks Done',
                              color: AppColors.yellow,
                              change: '+${total > 0 ? done : 12}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _OverviewCard(cPct: cPct, iPct: iPct, oPct: oPct),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: _iconBtn(Icons.arrow_back_ios_new_rounded),
            ),
            Text('Summary',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            _iconBtn(Icons.more_horiz_rounded),
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
}

// ── TASK ACTIVITY CARD ──────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksNotifier>().tasks;
    final counts = List.filled(7, 0);
    final now = DateTime.now();
    // Only count tasks for the current week to make it meaningful
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    for (var t in tasks) {
      if (t.scheduledAt.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
          t.scheduledAt.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        final idx = t.scheduledAt.weekday - 1;
        counts[idx]++;
      }
    }

    final maxCount = counts.reduce(math.max);
    final yMax = maxCount < 4 ? 4 : maxCount + (maxCount % 2 == 0 ? 0 : 1); // keep it even
    
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
      if (counts[i] == maxCount && maxCount > 0) {
        highIdx = i;
      }
    }

    final totalThisWeek = counts.reduce((a, b) => a + b);
    final avg = (totalThisWeek / 7).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
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
                  Text('Task Activity',
                      style: GoogleFonts.outfit(
                          color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('Avg $avg tasks per day',
                      style: GoogleFonts.outfit(
                          color: AppColors.textDark.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.textDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_outward_rounded,
                    color: AppColors.textPrimary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: yLabels
                      .map((l) => Text(l,
                          style: GoogleFonts.outfit(
                              color: AppColors.textDark.withValues(alpha: 0.5), fontSize: 10)))
                      .toList(),
                ),
                const SizedBox(width: 8),
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
                            height: barH,
                            decoration: BoxDecoration(
                              color: isBold
                                  ? AppColors.textDark
                                  : AppColors.textDark.withValues(alpha: 0.2),
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(days[i],
                              style: GoogleFonts.outfit(
                                  color: AppColors.textDark.withValues(alpha: 0.7),
                                  fontSize: 10)),
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
  const _StatCard(
      {required this.value,
      required this.label,
      required this.color,
      required this.change});
  final String value, label, change;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(value,
                      style: GoogleFonts.outfit(
                          color: AppColors.textDark,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(change,
                      style: GoogleFonts.outfit(
                          color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            Text(label,
                style: GoogleFonts.outfit(
                    color: AppColors.textDark.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      );
}

// ── OVERVIEW CARD ────────────────────────────────────────────
class _OverviewCard extends StatelessWidget {
  const _OverviewCard(
      {required this.cPct, required this.iPct, required this.oPct});
  final double cPct, iPct, oPct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Task Overview',
                  style: GoogleFonts.outfit(
                      color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.innerCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_outward_rounded,
                    color: AppColors.textSecondary, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total spending',
                  style: GoogleFonts.outfit(
                      color: AppColors.textSecondary, fontSize: 12)),
              Text('\$2,580.00',
                  style: GoogleFonts.outfit(
                      color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                      flex: (cPct * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.mint)),
                  Expanded(
                      flex: (iPct * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.purple)),
                  Expanded(
                      flex: (oPct * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.yellow)),
                  Expanded(
                      flex: ((1 - cPct - iPct - oPct) * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.innerCard)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Legend(color: AppColors.mint, label: 'Completed', pct: '${(cPct * 100).round()}%'),
          const SizedBox(height: 8),
          _Legend(color: AppColors.purple, label: 'In Progress', pct: '${(iPct * 100).round()}%'),
          const SizedBox(height: 8),
          _Legend(color: AppColors.yellow, label: 'On Hold', pct: '${(oPct * 100).round()}%'),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.pct});
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
              child: Text(label,
                  style: GoogleFonts.outfit(
                      color: AppColors.textSecondary, fontSize: 13))),
          Text(pct,
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      );
}




