// lib/presentation/screens/add_task_screen.dart
//
// UX/UI Redesign v2:
//  1. Clean indigo/violet theme matching home screen palette
//  2. Large voice hero with animated wave
//  3. Card-based sections with soft shadows
//  4. Color-coded priority selector
//  5. Better date/time picker with preview
//  6. Floating CTA with gradient
//  7. Category chips with icons
//  8. Progress strip at top

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../widgets/voice_button.dart';
import '../../services/task_parser_service.dart';
import '../../services/voice_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg = Color(0xFFF1F5F9);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFF4F46E5);
  static const accentLight = Color(0xFFEEF2FF);
  static const textPri = Color(0xFF1E293B);
  static const textSec = Color(0xFF64748B);
  static const textHint = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFF0FDF4);
  static const warn = Color(0xFFF59E0B);
  static const warnBg = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFEF2F2);
  static const radius = Radius.circular(20);
  static const radiusSm = Radius.circular(12);
}

enum _Priority { low, medium, high }

class _QuickTime {
  final String label;
  final IconData icon;
  final Duration offset;
  const _QuickTime(this.label, this.icon, this.offset);
}

const _quickTimes = [
  _QuickTime('30 min', Icons.schedule_outlined, Duration(minutes: 30)),
  _QuickTime('1 hour', Icons.schedule_outlined, Duration(hours: 1)),
  _QuickTime('Evening', Icons.wb_twilight_outlined, Duration(hours: 0)),
  _QuickTime('Tomorrow', Icons.event_outlined, Duration(hours: 0)),
  _QuickTime('Next week', Icons.calendar_month_outlined, Duration(days: 7)),
];

const _reminderOptions = ['5 min', '10 min', '15 min', '30 min', '1 hour'];

class _Cat {
  final String label;
  final IconData icon;
  final Color color;
  const _Cat(this.label, this.icon, this.color);
}

const _categories = [
  _Cat('Work', Icons.work_outline, Color(0xFF6366F1)),
  _Cat('Personal', Icons.person_outline, Color(0xFF8B5CF6)),
  _Cat('Health', Icons.favorite_outline, Color(0xFFEF4444)),
  _Cat('Study', Icons.school_outlined, Color(0xFF10B981)),
  _Cat('Family', Icons.home_outlined, Color(0xFFF59E0B)),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class AddTaskScreen extends StatefulWidget {
  final String? initialText;
  final ParsedTask? initialParsed;

  const AddTaskScreen({this.initialText, this.initialParsed, super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen>
    with TickerProviderStateMixin {
  final _descCtrl = TextEditingController();
  late TextEditingController _titleCtrl;

  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  _Priority _priority = _Priority.medium;
  int _reminderIdx = 2;
  bool _calSync = true;
  bool _isSubmitting = false;
  int? _activeQuickIdx;
  final Set<String> _selectedCategories = {'Work'};

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;
  late AnimationController _waveCtrl;

  static const _cardCount = 5;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.initialText ?? widget.initialParsed?.title ?? '',
    );
    if (widget.initialParsed?.scheduledAt != null) {
      _scheduledAt = widget.initialParsed!.scheduledAt!;
    }

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fades = List.generate(_cardCount, (i) {
      final start = i * 0.12;
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ));
    });
    _slides = List.generate(_cardCount, (i) {
      final start = i * 0.12;
      return Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ));
    });

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _entranceCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Widget _animated({required int i, required Widget child}) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  double get _progress {
    int score = 0;
    if (_titleCtrl.text.trim().isNotEmpty) score += 60;
    if (_descCtrl.text.trim().isNotEmpty) score += 15;
    if (_activeQuickIdx != null) score += 15;
    if (_selectedCategories.isNotEmpty) score += 10;
    return score / 100;
  }

  String get _dateLabel {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    if (_isSameDay(_scheduledAt, now)) return 'Today';
    if (_isSameDay(_scheduledAt, tomorrow)) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(_scheduledAt);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _applyQuickTime(int idx) {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    DateTime result;
    switch (idx) {
      case 0:
        result = now.add(_quickTimes[idx].offset);
      case 1:
        result = now.add(_quickTimes[idx].offset);
      case 2:
        result = DateTime(now.year, now.month, now.day, 19, 0);
        if (result.isBefore(now)) result = result.add(const Duration(days: 1));
      case 3:
        result = DateTime(
          now.year, now.month, now.day + 1,
          _scheduledAt.hour, _scheduledAt.minute,
        );
      default:
        result = now.add(_quickTimes[idx].offset);
    }
    setState(() {
      _scheduledAt = result;
      _activeQuickIdx = idx;
    });
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.selectionClick();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: _lightPickerTheme,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: _lightPickerTheme,
    );
    if (time == null || !mounted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _activeQuickIdx = null;
    });
  }

  Widget _lightPickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: _T.accent,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _T.textPri,
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          timePickerTheme: TimePickerThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        child: child!,
      );

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      HapticFeedback.vibrate();
      _showError('Please enter a task title');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      await context.read<TasksNotifier>().addTask(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            scheduledAt: _scheduledAt,
          );
    } catch (e) {
      if (mounted) _showError('Failed to save task: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: _T.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _T.bg,
      body: Stack(children: [
        Column(children: [
          _ProgressStrip(progress: _progress),
          Expanded(
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: _T.textPri, size: 18),
                            ),
                          ),
                          const Text('New Task',
                            style: TextStyle(
                              color: _T.textPri,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            )),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.more_horiz_rounded,
                                  color: _T.textSec, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 100),
                    sliver: SliverList(delegate: SliverChildListDelegate([

                      // ── 1. Voice hero ─────────────────────────────────
                      _animated(i: 0, child: _VoiceCard(
                        onTextCaptured: (text) {
                          HapticFeedback.lightImpact();
                          setState(() => _titleCtrl.text = text);
                        },
                        onParsed: (task) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _titleCtrl.text = task.title;
                            if (task.scheduledAt != null) {
                              _scheduledAt = task.scheduledAt!;
                              _activeQuickIdx = null;
                            }
                          });
                        },
                      )),
                      const SizedBox(height: 16),

                      // ── 2. Title + description ────────────────────────
                      _animated(i: 1, child: _Card(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                            child: Row(
                              children: [
                                _SectionLabel('Task title'),
                                const SizedBox(width: 6),
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle, color: _T.danger),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: TextField(
                              controller: _titleCtrl,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                color: _T.textPri,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                              cursorColor: _T.accent,
                              decoration: InputDecoration(
                                hintText: 'What needs to be done?',
                                hintStyle: const TextStyle(
                                  color: _T.textHint,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400),
                                filled: true,
                                fillColor: _T.bg,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(_T.radiusSm),
                                  borderSide: const BorderSide(color: _T.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(_T.radiusSm),
                                  borderSide: const BorderSide(color: _T.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(_T.radiusSm),
                                  borderSide: const BorderSide(color: _T.accent, width: 1.5),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Row(
                              children: [
                                const Icon(Icons.notes_rounded,
                                    size: 14, color: _T.textHint),
                                const SizedBox(width: 6),
                                const Text('Notes (optional)',
                                    style: TextStyle(
                                      color: _T.textHint,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text('${_titleCtrl.text.length}/80',
                                    style: const TextStyle(
                                      fontSize: 11, color: _T.textHint,
                                      fontFeatures: [FontFeature.tabularFigures()])),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                            child: TextField(
                              controller: _descCtrl,
                              onChanged: (_) => setState(() {}),
                              maxLines: 2,
                              style: const TextStyle(
                                color: _T.textPri,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                              cursorColor: _T.accent,
                              decoration: InputDecoration(
                                hintText: 'Add details or context...',
                                hintStyle: const TextStyle(
                                  color: _T.textHint,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400),
                                filled: true,
                                fillColor: _T.bg,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(_T.radiusSm),
                                  borderSide: const BorderSide(color: _T.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(_T.radiusSm),
                                  borderSide: const BorderSide(color: _T.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(_T.radiusSm),
                                  borderSide: const BorderSide(color: _T.accent, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(height: 12),

                      // ── 3. Date & Time ───────────────────────────────
                      _animated(i: 2, child: _Card(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 16, color: _T.accent),
                                const SizedBox(width: 8),
                                const Text('When',
                                    style: TextStyle(
                                      color: _T.textSec,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _DateTimeChip(
                                    label: 'Date',
                                    value: _dateLabel,
                                    icon: Icons.event_outlined,
                                    color: _T.accent,
                                    onTap: _pickDateTime,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _DateTimeChip(
                                    label: 'Time',
                                    value: DateFormat('h:mm a').format(_scheduledAt),
                                    icon: Icons.access_time_rounded,
                                    color: _T.accent,
                                    onTap: _pickDateTime,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Quick pick',
                                    style: TextStyle(
                                      color: _T.textHint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(_quickTimes.length, (i) => _QuickChip(
                                    label: _quickTimes[i].label,
                                    icon: _quickTimes[i].icon,
                                    selected: _activeQuickIdx == i,
                                    onTap: () => _applyQuickTime(i),
                                  )),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(height: 12),

                      // ── 4. Priority ─────────────────────────────────
                      _animated(i: 3, child: _Card(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.flag_outlined,
                                        size: 16, color: _T.accent),
                                    const SizedBox(width: 8),
                                    const Text('Priority',
                                        style: TextStyle(
                                          color: _T.textSec,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(children: [
                                  _PriorityBtn(
                                    label: 'Low',
                                    color: _T.success,
                                    bgColor: _T.successBg,
                                    selected: _priority == _Priority.low,
                                    icon: Icons.arrow_downward_rounded,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _priority = _Priority.low);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _PriorityBtn(
                                    label: 'Medium',
                                    color: _T.warn,
                                    bgColor: _T.warnBg,
                                    selected: _priority == _Priority.medium,
                                    icon: Icons.remove_rounded,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _priority = _Priority.medium);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _PriorityBtn(
                                    label: 'High',
                                    color: _T.danger,
                                    bgColor: _T.dangerBg,
                                    selected: _priority == _Priority.high,
                                    icon: Icons.arrow_upward_rounded,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _priority = _Priority.high);
                                    },
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(height: 12),

                      // ── 5. Reminder + Sync + Category ────────────────
                      _animated(i: 4, child: _Card(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _SettingRow(
                                  icon: Icons.notifications_outlined,
                                  iconBg: _T.accentLight,
                                  iconColor: _T.accent,
                                  label: 'Reminder',
                                  value: _reminderOptions[_reminderIdx],
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() =>
                                        _reminderIdx = (_reminderIdx + 1) % _reminderOptions.length);
                                  },
                                ),
                                Container(height: 1, color: _T.border, margin: const EdgeInsets.symmetric(vertical: 4)),
                                _SettingRow(
                                  icon: Icons.calendar_month_outlined,
                                  iconBg: const Color(0xFFF0FDF4),
                                  iconColor: _T.success,
                                  label: 'Google Calendar',
                                  value: _calSync ? 'On' : 'Off',
                                  valueColor: _calSync ? _T.success : _T.textHint,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _calSync = !_calSync);
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.category_outlined,
                                        size: 16, color: _T.accent),
                                    SizedBox(width: 8),
                                    Text('Category',
                                        style: TextStyle(
                                          color: _T.textSec,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ..._categories.map((cat) => _CategoryChip(
                                      label: cat.label,
                                      icon: cat.icon,
                                      color: cat.color,
                                      selected: _selectedCategories.contains(cat.label),
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          if (_selectedCategories.contains(cat.label)) {
                                            _selectedCategories.remove(cat.label);
                                          } else {
                                            _selectedCategories.add(cat.label);
                                          }
                                        });
                                      },
                                    )),
                                    _AddCategoryChip(onTap: () {}),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(height: 24),
                    ])),
                  ),
                ],
              ),
            ),
          ),
        ]),

        // ── Fixed CTA bar ─────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _CtaBar(
            isSubmitting: _isSubmitting,
            onTap: _isSubmitting ? null : _submit,
            bottomPad: MediaQuery.of(context).padding.bottom,
            canSubmit: _titleCtrl.text.trim().isNotEmpty,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LayoutBuilder(builder: (_, constraints) {
        return Stack(children: [
          Container(color: _T.border),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            width: constraints.maxWidth * progress,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ]);
      }),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.all(_T.radius),
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
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _T.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      );
}

class _DateTimeChip extends StatelessWidget {
  const _DateTimeChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.accentLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(label.toUpperCase(),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    )),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _T.accentLight : _T.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _T.accent : _T.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: selected ? _T.accent : _T.textHint),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? _T.accent : _T.textSec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBtn extends StatelessWidget {
  const _PriorityBtn({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color bgColor;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? bgColor : _T.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : _T.border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: selected ? color : _T.textHint),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : _T.textSec,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _T.textPri)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _T.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.border),
            ),
            child: Text(value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? _T.textSec)),
          ),
        ]),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : _T.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : _T.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? color : _T.textHint),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : _T.textSec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryChip extends StatelessWidget {
  const _AddCategoryChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 13, color: _T.textHint),
            SizedBox(width: 5),
            Text(
              'New',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _T.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VOICE HERO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceCard extends StatefulWidget {
  const _VoiceCard({required this.onTextCaptured, this.onParsed});

  final void Function(String text) onTextCaptured;
  final void Function(ParsedTask task)? onParsed;

  @override
  State<_VoiceCard> createState() => _VoiceCardState();
}

class _VoiceCardState extends State<_VoiceCard>
    with TickerProviderStateMixin {
  bool _listening = false;
  late AnimationController _waveCtrl;
  final VoiceService _voice = VoiceService();
  final TaskParserService _parser = TaskParserService();
  TtsLocale _currentLocale = TtsLocale.english;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _voice.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();
    if (_listening) {
      await _voice.stop();
      _waveCtrl.stop();
      if (mounted) setState(() => _listening = false);
    } else {
      if (mounted) setState(() => _listening = true);
      _waveCtrl.repeat(reverse: true);
      await _voice.startListening(
        onResult: (text) {
          if (widget.onParsed != null) {
            final parsed = _parser.parse(text);
            widget.onParsed!(parsed);
          } else {
            widget.onTextCaptured(text);
          }
        },
        onDone: () {
          if (mounted) {
            _waveCtrl.stop();
            setState(() => _listening = false);
          }
        },
      );
    }
  }

  Future<void> _switchLocale() async {
    HapticFeedback.lightImpact();
    setState(() {
      _currentLocale = _currentLocale == TtsLocale.english ? TtsLocale.arabic : TtsLocale.english;
    });
    await _voice.setLocale(_currentLocale);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _currentLocale == TtsLocale.arabic;
    return GestureDetector(
      onTap: _toggleListening,
      onLongPress: _switchLocale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _listening
                ? [const Color(0xFF4338CA), const Color(0xFF3730A3)]
                : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (_listening ? const Color(0xFF4338CA) : const Color(0xFF6366F1))
                  .withValues(alpha: 0.35),
              blurRadius: _listening ? 24 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'QUICK INPUT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAr ? 'AR' : 'EN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _listening
                  ? (isAr ? 'جاري الاستماع...' : 'Listening… speak now')
                  : (isAr ? 'انقر لتسجيل مهمة صوتياً' : 'Tap to speak your task'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            if (!_listening) ...[
              const SizedBox(height: 6),
              Text(
                isAr ? 'اضغط مطولاً لتغيير اللغة' : 'Hold to switch language',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            if (_listening)
              _WaveAnimation(controller: _waveCtrl)
            else
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.mic_rounded, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'اضغط للتحدث' : 'Tap to speak',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _WaveAnimation extends StatelessWidget {
  const _WaveAnimation({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final heights = [6.0, 14.0, 10.0, 16.0, 8.0];
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (i) {
          final delay = i * 0.15;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final t = ((controller.value + delay) % 1.0);
                final scale = 0.5 + 0.5 * (t < 0.5 ? 2 * t : 2 * (1 - t));
                return Container(
                  width: 4,
                  height: heights[i] * scale,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA BAR
// ─────────────────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  const _CtaBar({
    required this.isSubmitting,
    required this.onTap,
    required this.bottomPad,
    required this.canSubmit,
  });

  final bool isSubmitting;
  final VoidCallback? onTap;
  final double bottomPad;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_T.bg.withValues(alpha: 0), _T.bg, _T.bg],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 20),
      child: _SubmitButton(
        isSubmitting: isSubmitting,
        onTap: onTap,
        canSubmit: canSubmit,
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.isSubmitting,
    this.onTap,
    required this.canSubmit,
  });

  final bool isSubmitting;
  final VoidCallback? onTap;
  final bool canSubmit;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.canSubmit && !widget.isSubmitting;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => _pressCtrl.reverse(),
      onTapUp: disabled
          ? null
          : (_) {
              _pressCtrl.forward();
              widget.onTap?.call();
            },
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
            color: disabled ? const Color(0xFFE2E8F0) : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.isSubmitting
                ? const Center(
                    key: ValueKey('loading'),
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                    ),
                  )
                : Center(
                    key: const ValueKey('label'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          disabled ? Icons.check_rounded : Icons.add_rounded,
                          color: disabled ? _T.textHint : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          disabled ? 'Add a title to continue' : 'Create Task',
                          style: TextStyle(
                            color: disabled ? _T.textHint : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
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