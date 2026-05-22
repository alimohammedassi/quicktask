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
import '../../core/localization/app_localizations.dart';

String _translateCategory(BuildContext context, String label) {
  switch (label.toLowerCase()) {
    case 'work':
      return context.translate('cat_work');
    case 'personal':
      return context.translate('cat_personal');
    case 'health':
      return context.translate('cat_health');
    case 'study':
      return context.translate('cat_study');
    case 'family':
      return context.translate('cat_family');
    case 'shopping':
      return context.translate('cat_shopping');
    default:
      return label;
  }
}

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});
  final TaskModelHive task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with TickerProviderStateMixin {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late DateTime _dueDate;
  late bool _isCompleted;
  late List<String> _selectedCats;
  bool _hasChanges = false;

  // ── Staggered entrance animations ──────────────────────────
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;
  static const _sectionCount = 7;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
    _dueDate = widget.task.scheduledAt;
    _isCompleted = widget.task.isCompleted;
    _selectedCats = List.from(widget.task.categories);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnims = List.generate(_sectionCount, (i) {
      final start = (i * 0.08).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(_sectionCount, (i) {
      final start = (i * 0.08).clamp(0.0, 0.7);
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
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _saveChanges() async {
    final tokens = context.tokens;
    final notifier = context.read<TasksNotifier>();
    final currentTask = context.read<CurrentTaskNotifier>();
    final updated = widget.task.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      scheduledAt: _dueDate,
      isCompleted: _isCompleted,
      categories: _selectedCats,
    );
    await notifier.updateTask(updated);
    
    // Clear if it's the current task and has been completed
    if (_isCompleted) {
      if (currentTask.currentTaskId == widget.task.id) {
        await currentTask.clearCurrentTask();
      }
    }

    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(context.translate('changes_saved_toast'),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: tokens.mint.withValues(alpha: 0.9),
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
      builder: (ctx) {
        final dialogTokens = ctx.tokens;
        return AlertDialog(
          backgroundColor: dialogTokens.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(ctx.translate('delete_task_confirm'),
              style: GoogleFonts.plusJakartaSans(color: dialogTokens.textPrimary, fontWeight: FontWeight.w700)),
          content: Text(ctx.translate('delete_task_warning'),
              style: GoogleFonts.plusJakartaSans(color: dialogTokens.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.translate('cancel_btn'),
                  style: GoogleFonts.plusJakartaSans(color: dialogTokens.textSecondary, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.translate('delete'),
                  style: GoogleFonts.plusJakartaSans(color: dialogTokens.error, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      HapticFeedback.heavyImpact();
      final currentTask = context.read<CurrentTaskNotifier>();
      final tasksNotifier = context.read<TasksNotifier>();
      if (currentTask.currentTaskId == widget.task.id) {
        await currentTask.clearCurrentTask();
      }
      await tasksNotifier.deleteTask(widget.task);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _toggleComplete() async {
    HapticFeedback.mediumImpact();
    setState(() => _isCompleted = !_isCompleted);
    _markChanged();
  }

  Future<void> _pickDate() async {
    final tokens = context.tokens;
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: tokens.mint,
            surface: tokens.cardBg,
            onSurface: tokens.textPrimary,
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
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: tokens.mint,
            surface: tokens.cardBg,
            onSurface: tokens.textPrimary,
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

  // ── Helper: wrap a section in staggered fade + slide ──────────
  Widget _animSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(
        position: _slideAnims[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final currentTaskNotifier = Provider.of<CurrentTaskNotifier>(context);
    final subtasks = currentTaskNotifier.subtasksForTask(widget.task.id);
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    final totalCount = subtasks.length;
    final double progress = subtasks.isEmpty
        ? (_isCompleted ? 1.0 : 0.0)
        : (completedCount / totalCount);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final save = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final dialogTokens = ctx.tokens;
            return AlertDialog(
              backgroundColor: dialogTokens.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(ctx.translate('unsaved_changes'),
                  style: GoogleFonts.plusJakartaSans(color: dialogTokens.textPrimary, fontWeight: FontWeight.w700)),
              content: Text(ctx.translate('unsaved_changes_warning'),
                  style: GoogleFonts.plusJakartaSans(color: dialogTokens.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(ctx.translate('discard'),
                      style: GoogleFonts.plusJakartaSans(color: dialogTokens.error, fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(ctx.translate('save'),
                      style: GoogleFonts.plusJakartaSans(color: dialogTokens.mint, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
        if (save == true) await _saveChanges();
        if (!context.mounted) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: tokens.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 40),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 20),
                    _animSection(0, _buildTitle()),
                    const SizedBox(height: 20),
                    _animSection(1, _buildAssignDueRow()),
                    const SizedBox(height: 16),
                    _animSection(2, _buildStatusCard(progress)),
                    const SizedBox(height: 16),
                    _animSection(3, _buildCategoryCard()),
                    const SizedBox(height: 16),
                    _animSection(4, _buildDescriptionCard()),
                    const SizedBox(height: 16),
                    _animSection(5, _buildChecklistCard()),
                    const SizedBox(height: 24),
                    _animSection(6, _buildDeleteButton()),
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
  Widget _buildAppBar() {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (_hasChanges) {
                Navigator.maybePop(context);
              } else {
                Navigator.pop(context);
              }
            },
            child: _iconBtn(context, Icons.arrow_back_rounded),
          ),
          Text(context.translate('task_details'),
              style: GoogleFonts.plusJakartaSans(
                  color: tokens.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          PopupMenuButton<String>(
            icon: _iconBtn(context, Icons.more_horiz_rounded),
            color: tokens.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              if (v == 'delete') _deleteTask();
              if (v == 'toggle') _toggleComplete();
              if (v == 'set_current') {
                context.read<CurrentTaskNotifier>().setCurrentTask(widget.task);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [
                    Icon(Icons.star_rounded, color: tokens.textDark, size: 18),
                    const SizedBox(width: 10),
                    Text(context.translate('pinned_to_home'), style: GoogleFonts.plusJakartaSans(color: tokens.textDark, fontWeight: FontWeight.w600)),
                  ]),
                  backgroundColor: tokens.mint,
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
                  Icon(Icons.star_outline_rounded, color: tokens.gold, size: 18),
                  const SizedBox(width: 10),
                  Text(context.translate('set_as_current'),
                      style: GoogleFonts.plusJakartaSans(color: tokens.textPrimary, fontSize: 14)),
                ]),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(_isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
                      color: tokens.mint, size: 18),
                  const SizedBox(width: 10),
                  Text(_isCompleted ? context.translate('mark_pending') : context.translate('mark_done'),
                      style: GoogleFonts.plusJakartaSans(color: tokens.textPrimary, fontSize: 14)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, color: tokens.error, size: 18),
                  const SizedBox(width: 10),
                  Text(context.translate('delete_task'),
                      style: GoogleFonts.plusJakartaSans(color: tokens.error, fontSize: 14)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon) {
    final tokens = context.tokens;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.divider, width: 1.2),
      ),
      child: Icon(icon, color: tokens.textPrimary, size: 18),
    );
  }

  // ── TITLE (editable) ───────────────────────────────────────
  Widget _buildTitle() {
    final tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                onChanged: (_) => _markChanged(),
                style: GoogleFonts.plusJakartaSans(
                    color: tokens.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: context.translate('task_title_label'),
                  hintStyle: GoogleFonts.plusJakartaSans(color: tokens.textHint, fontSize: 28),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(context.translate('task_manager_ui_kit'),
                  style: GoogleFonts.plusJakartaSans(color: tokens.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: _iconBtn(context, Icons.share_outlined),
        ),
      ],
    );
  }

  // ── ASSIGN + DUE DATE (tappable date) ──────────────────────
  Widget _buildAssignDueRow() {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.divider, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.translate('client_name'),
                    style: GoogleFonts.plusJakartaSans(color: tokens.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: tokens.purple,
                      child: Text('C',
                          style: GoogleFonts.plusJakartaSans(
                              color: tokens.textDark, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(context.translate('client'),
                          style: GoogleFonts.plusJakartaSans(
                              color: tokens.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.divider, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 12, color: tokens.mint),
                      const SizedBox(width: 6),
                      Text(context.translate('due_date'),
                          style: GoogleFonts.plusJakartaSans(color: tokens.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Icon(Icons.edit_outlined, size: 12, color: tokens.textHint),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(DateFormat('MMM d, h:mm a', Localizations.localeOf(context).languageCode).format(_dueDate),
                      style: GoogleFonts.plusJakartaSans(
                          color: tokens.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── STATUS (tappable toggle) ───────────────────────────────
  Widget _buildStatusCard(double progress) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.divider, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.translate('task_status'),
                  style: GoogleFonts.plusJakartaSans(
                      color: tokens.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: _toggleComplete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isCompleted ? tokens.mint : tokens.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isCompleted ? context.translate('completed').toUpperCase() : context.translate('in_progress'),
                    style: GoogleFonts.plusJakartaSans(
                        color: tokens.textDark, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.translate('progress'),
                  style: GoogleFonts.plusJakartaSans(color: tokens.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              Text('${(_isCompleted ? 100 : (progress * 100).round())}%',
                  style: GoogleFonts.plusJakartaSans(
                      color: tokens.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _isCompleted ? 1.0 : progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: tokens.innerCard,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isCompleted ? tokens.mint : tokens.yellow,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CATEGORY SELECTOR CARD ────────────────────────────────
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

  Widget _buildCategoryCard() {
    final tokens = context.tokens;
    final availableCategories = ['Work', 'Personal', 'Health', 'Study', 'Family', 'Shopping'];
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.divider, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.translate('categories'),
              style: GoogleFonts.plusJakartaSans(
                  color: tokens.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableCategories.map((cat) {
              final isSelected = _selectedCats.contains(cat);
              final catColor = _getCategoryColor(cat, context);
              
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedCats.remove(cat);
                    } else {
                      _selectedCats.add(cat);
                    }
                    _markChanged();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? catColor : tokens.innerCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? catColor : tokens.divider,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: catColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: -2,
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    _translateCategory(context, cat).toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: isSelected ? tokens.textDark : tokens.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── DESCRIPTION (editable) ─────────────────────────────────
  Widget _buildDescriptionCard() {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.divider, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.translate('description_label'),
              style: GoogleFonts.plusJakartaSans(
                  color: tokens.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            onChanged: (_) => _markChanged(),
            style: GoogleFonts.plusJakartaSans(
                color: tokens.textSecondary, fontSize: 13, height: 1.6),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: context.translate('add_description_hint'),
              hintStyle: GoogleFonts.plusJakartaSans(color: tokens.textHint, fontSize: 13),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: 6,
            minLines: 3,
          ),
        ],
      ),
    );
  }

  // ── CHECKLIST (Subtasks) ───────────────────────────────────
  Widget _buildChecklistCard() {
    final tokens = context.tokens;
    final currentTaskNotifier = context.watch<CurrentTaskNotifier>();
    final subtasks = currentTaskNotifier.subtasksForTask(widget.task.id);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.divider, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.translate('checklist'),
                  style: GoogleFonts.plusJakartaSans(
                      color: tokens.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => _showAddSubtaskDialog(currentTaskNotifier),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tokens.innerCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.divider),
                  ),
                  child: Icon(Icons.add_rounded, color: tokens.mint, size: 18),
                ),
              ),
            ],
          ),
          if (subtasks.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...subtasks.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                     children: [
                       GestureDetector(
                         onTap: () {
                           HapticFeedback.selectionClick();
                           currentTaskNotifier.toggleSubtask(widget.task.id, s.id);
                         },
                         child: AnimatedContainer(
                           duration: const Duration(milliseconds: 200),
                           width: 22,
                           height: 22,
                           decoration: BoxDecoration(
                             color: s.isCompleted ? tokens.mint : Colors.transparent,
                             border: Border.all(
                               color: s.isCompleted ? tokens.mint : tokens.checkboxBorder,
                               width: 1.5,
                             ),
                             borderRadius: BorderRadius.circular(6),
                           ),
                           child: s.isCompleted
                               ? Icon(Icons.check_rounded, size: 14, color: tokens.textDark)
                               : null,
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(s.title,
                             style: GoogleFonts.plusJakartaSans(
                                 color: s.isCompleted ? tokens.textSecondary : tokens.textPrimary,
                                 fontSize: 13.5,
                                 decoration: s.isCompleted ? TextDecoration.lineThrough : null,
                                 decorationColor: tokens.textSecondary)),
                       ),
                       GestureDetector(
                         onTap: () {
                           HapticFeedback.lightImpact();
                           currentTaskNotifier.deleteSubtask(widget.task.id, s.id);
                         },
                         child: Container(
                           padding: const EdgeInsets.all(2),
                           decoration: const BoxDecoration(
                             color: Colors.transparent,
                             shape: BoxShape.circle,
                           ),
                           child: Icon(Icons.close_rounded, color: tokens.textSecondary, size: 16),
                         ),
                       ),
                     ],
                  ),
                )),
          ] else ...[
            const SizedBox(height: 14),
            Text(context.translate('no_items_checklist'),
                style: GoogleFonts.plusJakartaSans(color: tokens.textSecondary, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddSubtaskDialog(CurrentTaskNotifier notifier) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        final dialogTokens = ctx.tokens;
        return AlertDialog(
          backgroundColor: dialogTokens.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(ctx.translate('add_checklist_item'),
              style: GoogleFonts.plusJakartaSans(color: dialogTokens.textPrimary, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            style: GoogleFonts.plusJakartaSans(color: dialogTokens.textPrimary),
            autofocus: true,
            decoration: InputDecoration(
              hintText: ctx.translate('eg_call_client'),
              hintStyle: GoogleFonts.plusJakartaSans(color: dialogTokens.textHint),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dialogTokens.divider)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: dialogTokens.mint)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.translate('cancel_btn'),
                  style: GoogleFonts.plusJakartaSans(color: dialogTokens.textSecondary, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  notifier.addSubtask(widget.task.id, ctrl.text.trim());
                }
                Navigator.pop(ctx);
              },
              child: Text(ctx.translate('add_btn'),
                  style: GoogleFonts.plusJakartaSans(color: dialogTokens.mint, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // ── DELETE BUTTON ──────────────────────────────────────────
  Widget _buildDeleteButton() {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: _deleteTask,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: tokens.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.error.withValues(alpha: 0.3), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: tokens.error, size: 20),
            const SizedBox(width: 8),
            Text(context.translate('delete_task'),
                style: GoogleFonts.plusJakartaSans(
                    color: tokens.error, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ── SAVE BAR (shown when changes exist) ────────────────────
  Widget _buildSaveBar() {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        border: Border(top: BorderSide(color: tokens.divider, width: 1.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(context.translate('you_have_unsaved_changes'),
                style: GoogleFonts.plusJakartaSans(color: tokens.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: _saveChanges,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(context.translate('save'),
                  style: GoogleFonts.plusJakartaSans(
                      color: tokens.textDark, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
