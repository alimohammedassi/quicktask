// lib/presentation/widgets/task_card.dart
//
// ══════════════════════════════════════════════════════════════
//  TaskCard — Dark Premium Glassmorphism
//  Aesthetic: Deep navy/slate dark glass + gold/violet accents
//  Typography: tight letterspacing, weight contrast
//  Interactions: press-scale + haptics, swipe-delete glow
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';

// ─────────────────────────────────────────────────────────────
//  Private design tokens — dark glass system
// ─────────────────────────────────────────────────────────────
class _G {
  // Surfaces
  static const s0 = AppColors.surface;
  static const s1 = AppColors.cardBg;
  static const s2 = AppColors.bgLight;

  // Glass layers
  static const shine = Color(0x05000000); // subtle dark shine
  static const border = Color(0x11000000); // faint dark border
  static const borderSub = Color(0x05000000); // inner faint dark

  // Accent palette
  static const violet = AppColors.accent;
  static const gold = AppColors.warning;
  static const emerald = AppColors.success;
  static const rose = AppColors.error;

  // Typography
  static const t1 = AppColors.textPrimary;
  static const t2 = AppColors.textSecondary;
  static const t3 = AppColors.textHint;
}

// ─────────────────────────────────────────────────────────────
//  Card state model
// ─────────────────────────────────────────────────────────────
enum _State { upcoming, overdue, completed, synced }

extension _StateX on _State {
  Color get accent => switch (this) {
        _State.upcoming => _G.violet,
        _State.overdue => _G.rose,
        _State.completed => _G.emerald,
        _State.synced => _G.gold,
      };

  IconData get icon => switch (this) {
        _State.upcoming => Icons.circle_outlined,
        _State.overdue => Icons.error_outline_rounded,
        _State.completed => Icons.check_circle_rounded,
        _State.synced => Icons.flash_on_rounded,
      };

  String get tag => switch (this) {
        _State.upcoming => 'UPCOMING',
        _State.overdue => 'OVERDUE',
        _State.completed => 'DONE',
        _State.synced => 'SYNCED',
      };
}

// ─────────────────────────────────────────────────────────────
//  TaskCard
// ─────────────────────────────────────────────────────────────
class TaskCard extends StatefulWidget {
  final TaskEntity task;
  final VoidCallback onDelete;
  final VoidCallback? onToggleComplete;

  const TaskCard({required this.task, required this.onDelete, this.onToggleComplete, super.key});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.967)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _glow = Tween<double>(begin: 1.0, end: 0.3)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _State get _cardState {
    if (widget.task.isCompleted) return _State.completed;
    if (widget.task.scheduledAt.isBefore(DateTime.now())) return _State.overdue;
    if (widget.task.isSyncedToCalendar) return _State.synced;
    return _State.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final cs = _cardState;
    final bool isDone = widget.task.isCompleted;

    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.horizontal,
      background: _ActionBg(
        color: _G.emerald,
        icon: isDone ? Icons.remove_done_rounded : Icons.check_circle_outline_rounded,
        label: isDone ? 'UNDO' : 'DONE',
        alignment: AlignmentDirectional.centerStart,
      ),
      secondaryBackground: const _ActionBg(
        color: _G.rose,
        icon: Icons.delete_outline_rounded,
        label: 'DELETE',
        alignment: AlignmentDirectional.centerEnd,
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.endToStart) {
          widget.onDelete();
          return true;
        } else if (direction == DismissDirection.startToEnd) {
          widget.onToggleComplete?.call();
          return false;
        }
        return false;
      },
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          _ctrl.forward();
        },
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: _Shell(
              cs: cs,
              task: widget.task,
              onDelete: widget.onDelete,
              onToggleComplete: widget.onToggleComplete,
              glow: _glow),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shell — glass container with all layers
// ─────────────────────────────────────────────────────────────
class _Shell extends StatelessWidget {
  const _Shell({
    required this.cs,
    required this.task,
    required this.onDelete,
    this.onToggleComplete,
    required this.glow,
  });

  final _State cs;
  final TaskEntity task;
  final VoidCallback onDelete;
  final VoidCallback? onToggleComplete;
  final Animation<double> glow;

  bool get _done => task.isCompleted;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: cs.accent.withValues(alpha: 0.15 * glow.value),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06 * glow.value),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.4, 1.0],
              colors: [
                _G.s2.withValues(alpha: 0.92),
                _G.s1.withValues(alpha: 0.88),
                _G.s0.withValues(alpha: 0.94),
              ],
            ),
            border: Border.all(color: _G.border, width: 0.8),
          ),
          child: Stack(
              children: [
                // Top shine band
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 52,
                    decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(22)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_G.shine, Color(0x00000000)],
                      ),
                    ),
                  ),
                ),

                // Accent left rail
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cs.accent,
                          cs.accent.withValues(alpha: 0.5),
                          cs.accent.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom-right accent glow corner
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 100,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(22)),
                      gradient: RadialGradient(
                        center: Alignment.bottomRight,
                        radius: 1.2,
                        colors: [
                          cs.accent.withValues(alpha: 0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 15, 13, 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Orb(cs: cs, onTap: onToggleComplete),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Tag(cs: cs),
                            const SizedBox(height: 5),
                            // Title
                            Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _done
                                    ? _G.t3
                                    : _G.t1,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.5,
                                height: 1.35,
                                decoration:
                                    _done ? TextDecoration.lineThrough : null,
                                decorationColor: _G.t3,
                                decorationThickness: 1.8,
                              ),
                            ),
                            // Description
                            if (task.description != null &&
                                task.description!.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                task.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _G.t2,
                                  fontSize: 12.5,
                                  height: 1.5,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                            const SizedBox(height: 13),
                            _Footer(task: task, cs: cs),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _CloseBtn(onDelete: onDelete),
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

// ─────────────────────────────────────────────────────────────
//  Status orb — glowing icon chip
// ─────────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  const _Orb({required this.cs, this.onTap});
  final _State cs;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cs.accent.withValues(alpha: 0.10),
          border: Border.all(
            color: cs.accent.withValues(alpha: 0.28),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.accent.withValues(alpha: 0.25),
              blurRadius: 14,
              spreadRadius: -3,
            ),
          ],
        ),
        child: Icon(cs.icon, color: cs.accent, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  State tag — dot + uppercase label
// ─────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  const _Tag({required this.cs});
  final _State cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.accent,
            boxShadow: [
              BoxShadow(
                color: cs.accent.withValues(alpha: 0.8),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          cs.tag,
          style: TextStyle(
            color: cs.accent.withValues(alpha: 0.9),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Footer — time chip + sync badge
// ─────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer({required this.task, required this.cs});
  final TaskEntity task;
  final _State cs;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Time chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: _G.s2.withValues(alpha: 0.7),
            border: Border.all(
              color: cs.accent.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded,
                  size: 10.5, color: cs.accent.withValues(alpha: 0.8)),
              const SizedBox(width: 5),
              Text(
                DateFormat('MMM d · h:mm a').format(task.scheduledAt),
                style: const TextStyle(
                  color: _G.t2,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        if (task.isSyncedToCalendar)
          _SyncChip(),
      ],
    );
  }
}

class _SyncChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: _G.gold.withValues(alpha: 0.10),
        border: Border.all(color: _G.gold.withValues(alpha: 0.28), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 10.5, color: _G.gold),
          SizedBox(width: 4),
          Text(
            'SYNCED',
            style: TextStyle(
              color: _G.gold,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Close button
// ─────────────────────────────────────────────────────────────
class _CloseBtn extends StatelessWidget {
  const _CloseBtn({required this.onDelete});
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onDelete();
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _G.s2.withValues(alpha: 0.6),
          border: Border.all(color: _G.borderSub, width: 0.8),
        ),
        child: const Icon(Icons.close_rounded, size: 14, color: _G.t3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Swipe action background (Delete / Done)
// ─────────────────────────────────────────────────────────────
class _ActionBg extends StatelessWidget {
  const _ActionBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) {
    final isStart = alignment == AlignmentDirectional.centerStart;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        alignment: alignment,
        padding: isStart
            ? const EdgeInsetsDirectional.only(start: 26)
            : const EdgeInsetsDirectional.only(end: 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: isStart
                ? [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.12),
                    Colors.transparent
                  ]
                : [
                    Colors.transparent,
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.22)
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border:
                    Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
