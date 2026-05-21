// lib/presentation/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/current_task_provider.dart';

enum _State { upcoming, overdue, completed, synced }

extension _StateX on _State {
  Color get accent => switch (this) {
        _State.upcoming => AppColors.purple,
        _State.overdue => AppColors.error,
        _State.completed => AppColors.mint,
        _State.synced => AppColors.yellow,
      };
}

class TaskCard extends StatefulWidget {
  final TaskEntity task;
  final VoidCallback onDelete;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onTap;

  const TaskCard({
    required this.task,
    required this.onDelete,
    this.onToggleComplete,
    this.onTap,
    super.key,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
        color: AppColors.mint,
        icon: isDone
            ? Icons.remove_done_rounded
            : Icons.check_circle_outline_rounded,
        label: isDone ? 'UNDO' : 'DONE',
        alignment: AlignmentDirectional.centerStart,
      ),
      secondaryBackground: const _ActionBg(
        color: AppColors.error,
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
        onTap: () {
          _ctrl.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: _Shell(
            cs: cs,
            task: widget.task,
            onDelete: widget.onDelete,
            onToggleComplete: widget.onToggleComplete,
          ),
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.cs,
    required this.task,
    required this.onDelete,
    this.onToggleComplete,
  });

  final _State cs;
  final TaskEntity task;
  final VoidCallback onDelete;
  final VoidCallback? onToggleComplete;

  bool get _done => task.isCompleted;

  @override
  Widget build(BuildContext context) {
    final cardColor = _done ? const Color(0xFF070707) : const Color(0xFF0E0E0E);
    final borderColor =
        _done ? const Color(0xFF141414) : const Color(0xFF1C1C1C);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Orb(cs: cs, onTap: onToggleComplete),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chips
                  if (task.categories.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: task.categories
                          .map((cat) => _CategoryTag(cat: cat))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Title
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _done ? AppColors.textHint : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.3,
                      height: 1.3,
                      decoration: _done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textHint,
                      decorationThickness: 2.0,
                    ),
                  ),

                  // Description
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Footer (Schedule info + Sync indicator)
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: cs == _State.overdue
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d · h:mm a').format(task.scheduledAt),
                        style: TextStyle(
                          color: cs == _State.overdue
                              ? AppColors.error
                              : AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (task.isSyncedToCalendar) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.yellow,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Synced',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CloseBtn(onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.cs, this.onTap});
  final _State cs;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDone = cs == _State.completed;
    final color = cs.accent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? color : Colors.transparent,
          border: Border.all(
            color: isDone ? color : color.withOpacity(0.5),
            width: 2.0,
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
        child: isDone
            ? const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.black,
                  size: 18,
                  weight: 3.0,
                ),
              )
            : (cs == _State.overdue
                ? Center(
                    child: Icon(
                      Icons.priority_high_rounded,
                      color: color,
                      size: 14,
                    ),
                  )
                : null),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String cat;
  const _CategoryTag({required this.cat});

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(cat);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.24), width: 0.8),
      ),
      child: Text(
        cat.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    return AppColors.getCategoryColor(cat);
  }
}

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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.06),
        ),
        child: const Center(
          child: Icon(
            Icons.close_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        alignment: alignment,
        padding: isStart
            ? const EdgeInsetsDirectional.only(start: 24)
            : const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.24), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isStart
              ? [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ]
              : [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, color: color, size: 20),
                ],
        ),
      ),
    );
  }
}

class AllTaskTile extends StatelessWidget {
  const AllTaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.onToggleComplete,
  });

  final TaskEntity task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;

    // Use first category color or deterministic fallback pastel color
    final Color bg;
    if (task.categories.isNotEmpty) {
      bg = AppColors.getCategoryColor(task.categories.first);
    } else {
      final colors = [AppColors.purple, AppColors.yellow, AppColors.mint];
      bg = colors[task.id.hashCode.abs() % colors.length];
    }

    final currentTaskNotifier = Provider.of<CurrentTaskNotifier>(context);
    final subtasks = currentTaskNotifier.subtasksForTask(task.id);
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    final totalCount = subtasks.length;

    final double progress =
        subtasks.isEmpty ? (done ? 1.0 : 0.0) : (completedCount / totalCount);

    final String subtitleText = subtasks.isEmpty
        ? '${(task.title.length % 5) + 3} participants'
        : '$completedCount/$totalCount subtasks';

    return Dismissible(
      key: Key('all_${task.id}'),
      direction: DismissDirection.horizontal,
      background: _ActionBg(
        color: AppColors.mint,
        icon: done
            ? Icons.remove_done_rounded
            : Icons.check_circle_outline_rounded,
        label: done ? 'UNDO' : 'DONE',
        alignment: AlignmentDirectional.centerStart,
      ),
      secondaryBackground: const _ActionBg(
        color: AppColors.error,
        icon: Icons.delete_outline_rounded,
        label: 'DELETE',
        alignment: AlignmentDirectional.centerEnd,
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.endToStart) {
          onDelete();
          return true;
        } else if (direction == DismissDirection.startToEnd) {
          onToggleComplete?.call();
          return false;
        }
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: Colors.black.withOpacity(0.08), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category tags if present
                        if (task.categories.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: task.categories
                                .map((cat) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            width: 0.8),
                                      ),
                                      child: Text(
                                        cat.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Title
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            decorationThickness: 2,
                          ),
                        ),

                        // Description
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Stacked Avatars + Subtasks/Participants Count Row
                        Row(
                          children: [
                            const _OverlappingAvatars(),
                            const SizedBox(width: 8),
                            Text(
                              subtitleText,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Circular Progress Ring
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onToggleComplete?.call();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3.5,
                            backgroundColor: Colors.black.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.black),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }
}

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars();

  @override
  Widget build(BuildContext context) {
    final List<Color> avatarColors = [
      const Color(0xFFFFB7B2), // soft peach
      const Color(0xFFB5EAD7), // soft mint
      const Color(0xFFC7CEEA), // soft lavender
    ];
    final List<IconData> avatarIcons = [
      Icons.face_retouching_natural_rounded,
      Icons.sentiment_satisfied_alt_rounded,
      Icons.face_unlock_rounded,
    ];

    return SizedBox(
      height: 24,
      width: 52,
      child: Stack(
        children: List.generate(3, (index) {
          return Positioned(
            left: index * 14.0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColors[index],
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: Center(
                child: Icon(
                  avatarIcons[index],
                  size: 11,
                  color: Colors.black,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
