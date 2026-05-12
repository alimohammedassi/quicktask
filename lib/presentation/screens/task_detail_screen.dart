// lib/presentation/screens/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/task_model_hive.dart';
import '../providers/task_provider.dart';
import '../providers/current_task_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});
  final TaskModelHive task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late DateTime _dueDate;
  late bool _isCompleted;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
    _dueDate = widget.task.scheduledAt;
    _isCompleted = widget.task.isCompleted;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _saveChanges() async {
    final notifier = context.read<TasksNotifier>();
    final updated = widget.task.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      scheduledAt: _dueDate,
      isCompleted: _isCompleted,
    );
    await notifier.updateTask(updated);
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text('Changes saved',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: AppColors.mint.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
      setState(() => _hasChanges = false);
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Task?',
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('This action cannot be undone.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      HapticFeedback.heavyImpact();
      await context.read<TasksNotifier>().deleteTask(widget.task);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _toggleComplete() async {
    HapticFeedback.mediumImpact();
    setState(() => _isCompleted = !_isCompleted);
    _markChanged();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.mint,
            surface: AppColors.cardBg,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.mint,
            surface: AppColors.cardBg,
            onSurface: AppColors.textPrimary,
          ),
          timePickerTheme: TimePickerThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() => _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
    _markChanged();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _isCompleted ? 1.0 : 0.48;
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final save = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Unsaved Changes',
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            content: Text('Save your changes before leaving?',
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Discard',
                    style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Save',
                    style: GoogleFonts.outfit(color: AppColors.mint, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (save == true) await _saveChanges();
        if (mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  children: [
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 20),
                    _buildAssignDueRow(),
                    const SizedBox(height: 16),
                    _buildStatusCard(progress),
                    const SizedBox(height: 16),
                    _buildDescriptionCard(),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    _buildChecklistCard(),
                    const SizedBox(height: 24),
                    _buildDeleteButton(),
                  ],
                ),
              ),
              if (_hasChanges) _buildSaveBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────
  Widget _buildAppBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                if (_hasChanges) {
                  // trigger WillPopScope
                  Navigator.maybePop(context);
                } else {
                  Navigator.pop(context);
                }
              },
              child: _iconBtn(Icons.arrow_back_ios_new_rounded),
            ),
            Text('Task Details',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            PopupMenuButton<String>(
              icon: _iconBtn(Icons.more_horiz_rounded),
              color: AppColors.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'delete') _deleteTask();
                if (v == 'toggle') _toggleComplete();
                if (v == 'set_current') {
                  context.read<CurrentTaskNotifier>().setCurrentTask(widget.task);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: [
                      const Icon(Icons.star_rounded, color: AppColors.textDark, size: 18),
                      const SizedBox(width: 10),
                      Text('Pinned to Home screen', style: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    ]),
                    backgroundColor: AppColors.mint,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.all(16),
                  ));
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'set_current',
                  child: Row(children: [
                    const Icon(Icons.star_outline_rounded, color: AppColors.gold, size: 18),
                    const SizedBox(width: 10),
                    Text('Set as Current',
                        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(_isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
                        color: AppColors.mint, size: 18),
                    const SizedBox(width: 10),
                    Text(_isCompleted ? 'Mark Pending' : 'Mark Done',
                        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Text('Delete Task',
                        style: GoogleFonts.outfit(color: AppColors.error, fontSize: 14)),
                  ]),
                ),
              ],
            ),
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

  // ── TITLE (editable) ───────────────────────────────────────
  Widget _buildTitle() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleCtrl,
                  onChanged: (_) => _markChanged(),
                  style: GoogleFonts.outfit(
                      color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Task title',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 28),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text('Task manager ui kit',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: _iconBtn(Icons.share_outlined),
          ),
        ],
      );

  // ── ASSIGN + DUE DATE (tappable date) ──────────────────────
  Widget _buildAssignDueRow() => Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client Name',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.purple,
                        child: Text('C',
                            style: GoogleFonts.outfit(
                                color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text('Client',
                          style: GoogleFonts.outfit(
                              color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.mint),
                        const SizedBox(width: 4),
                        Text('Due date',
                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11)),
                        const Spacer(),
                        const Icon(Icons.edit_outlined, size: 12, color: AppColors.textHint),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(DateFormat('MMM d, h:mm a').format(_dueDate),
                        style: GoogleFonts.outfit(
                            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  // ── STATUS (tappable toggle) ───────────────────────────────
  Widget _buildStatusCard(double progress) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Task Status',
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: _toggleComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isCompleted ? AppColors.mint : AppColors.yellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isCompleted ? 'COMPLETED' : 'IN PROGRESS',
                      style: GoogleFonts.outfit(
                          color: AppColors.textDark, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                Text('${(_isCompleted ? 100 : (progress * 100).round())}%',
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: _isCompleted ? 1.0 : progress),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => LinearProgressIndicator(
                  value: val,
                  minHeight: 6,
                  backgroundColor: AppColors.innerCard,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCompleted ? AppColors.mint : AppColors.yellow,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  // ── DESCRIPTION (editable) ─────────────────────────────────
  Widget _buildDescriptionCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              onChanged: (_) => _markChanged(),
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.6),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Add a description...',
                hintStyle: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 13),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 6,
              minLines: 3,
            ),
          ],
        ),
      );

  // ── CHECKLIST (Subtasks) ───────────────────────────────────
  Widget _buildChecklistCard() {
    final currentTaskNotifier = context.watch<CurrentTaskNotifier>();
    final subtasks = currentTaskNotifier.subtasksForTask(widget.task.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Checklist',
                  style: GoogleFonts.outfit(
                      color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => _showAddSubtaskDialog(currentTaskNotifier),
                child: const Icon(Icons.add_rounded, color: AppColors.mint, size: 22),
              ),
            ],
          ),
          if (subtasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...subtasks.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => currentTaskNotifier.toggleSubtask(widget.task.id, s.id),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: s.isCompleted ? AppColors.mint : Colors.transparent,
                            border: Border.all(color: s.isCompleted ? AppColors.mint : AppColors.textHint, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: s.isCompleted ? const Icon(Icons.check_rounded, size: 14, color: AppColors.textDark) : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.title,
                            style: GoogleFonts.outfit(
                                color: s.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                                fontSize: 13,
                                decoration: s.isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: AppColors.textSecondary)),
                      ),
                      GestureDetector(
                        onTap: () => currentTaskNotifier.deleteSubtask(widget.task.id, s.id),
                        child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 16),
                      ),
                    ],
                  ),
                )),
          ] else ...[
            const SizedBox(height: 12),
            Text('No items in checklist. Tap + to add one.',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddSubtaskDialog(CurrentTaskNotifier notifier) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Checklist Item',
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.outfit(color: AppColors.textPrimary),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Call client',
            hintStyle: GoogleFonts.outfit(color: AppColors.textHint),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.mint)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                notifier.addSubtask(widget.task.id, ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: Text('Add',
                style: GoogleFonts.outfit(color: AppColors.mint, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── DELETE BUTTON ──────────────────────────────────────────
  Widget _buildDeleteButton() => GestureDetector(
        onTap: _deleteTask,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text('Delete Task',
                  style: GoogleFonts.outfit(
                      color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );

  // ── SAVE BAR (shown when changes exist) ────────────────────
  Widget _buildSaveBar() => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('You have unsaved changes',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
            ),
            GestureDetector(
              onTap: _saveChanges,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Save',
                    style: GoogleFonts.outfit(
                        color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
}




