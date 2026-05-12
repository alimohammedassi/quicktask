// lib/presentation/screens/add_task_screen.dart
//
// Redesign v3 — unified with HomeScreen dark theme
// • Same AppColors tokens, same card style, same border language
// • Fixed _SettingRow bug (was rendering empty)
// • Priority colors now use real semantic colors
// • Voice hero matches app palette (not violet override)
// • Stats strip at top mirrors HomeScreen language

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../../services/task_parser_service.dart';
import '../../services/voice_service.dart';
import '../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens — mirrors HomeScreen exactly
// ─────────────────────────────────────────────────────────────
const _kRadius = 20.0;
const _kRadiusSm = 12.0;
const _kPad = 20.0;

// Priority semantic colors (fixed from original)
const _kLowColor = AppColors.mint;
const _kMedColor = AppColors.yellow;
const _kHighColor = AppColors.error;

// ─────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────
enum _Priority { low, medium, high }

class _Cat {
  final String label;
  final IconData icon;
  final Color color;
  const _Cat(this.label, this.icon, this.color);
}

final _categories = [
  const _Cat('Work', Icons.work_outline_rounded, AppColors.purple),
  const _Cat('Personal', Icons.person_outline_rounded, AppColors.mint),
  const _Cat('Health', Icons.favorite_outline_rounded, AppColors.error),
  const _Cat('Study', Icons.school_outlined, AppColors.yellow),
  const _Cat('Family', Icons.home_outlined, Color(0xFFF59E0B)),
];

class _QuickSlot {
  final String label;
  final IconData icon;
  const _QuickSlot(this.label, this.icon);
}

const _quickSlots = [
  _QuickSlot('30 min', Icons.schedule_outlined),
  _QuickSlot('1 hour', Icons.schedule_outlined),
  _QuickSlot('Evening', Icons.wb_twilight_outlined),
  _QuickSlot('Tomorrow', Icons.event_outlined),
  _QuickSlot('Next week', Icons.calendar_month_outlined),
];

const _reminderOptions = ['5 min', '10 min', '15 min', '30 min', '1 hour'];

// ═══════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════
class AddTaskScreen extends StatefulWidget {
  final String? initialText;
  final ParsedTask? initialParsed;

  const AddTaskScreen({this.initialText, this.initialParsed, super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen>
    with TickerProviderStateMixin {
  // Form state
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  _Priority _priority = _Priority.medium;
  int _reminderIdx = 2;
  bool _calSync = true;
  bool _isSubmitting = false;
  int? _activeQuickIdx;
  final Set<String> _selectedCats = {'Work'};

  // Animations
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  static const _sectionCount = 5;

  @override
  void initState() {
    super.initState();

    _titleCtrl.text = widget.initialText ?? widget.initialParsed?.title ?? '';
    if (widget.initialParsed?.scheduledAt != null) {
      _scheduledAt = widget.initialParsed!.scheduledAt!;
    }

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fades = List.generate(_sectionCount, (i) {
      final s = (i * 0.10).clamp(0.0, 0.8);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, (s + 0.45).clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      );
    });

    _slides = List.generate(_sectionCount, (i) {
      final s = (i * 0.10).clamp(0.0, 0.8);
      return Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve:
            Interval(s, (s + 0.45).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      ));
    });

    _entranceCtrl.forward();
    _titleCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────

  Widget _anim(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  double get _progress {
    int s = 0;
    if (_titleCtrl.text.trim().isNotEmpty) s += 55;
    if (_descCtrl.text.trim().isNotEmpty) s += 15;
    if (_activeQuickIdx != null) s += 15;
    if (_selectedCats.isNotEmpty) s += 15;
    return (s / 100).clamp(0.0, 1.0);
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

  void _applyQuick(int idx) {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    DateTime r;
    switch (idx) {
      case 0:
        r = now.add(const Duration(minutes: 30));
        break;
      case 1:
        r = now.add(const Duration(hours: 1));
        break;
      case 2:
        r = DateTime(now.year, now.month, now.day, 19, 0);
        if (r.isBefore(now)) r = r.add(const Duration(days: 1));
        break;
      case 3:
        r = DateTime(now.year, now.month, now.day + 1, _scheduledAt.hour,
            _scheduledAt.minute);
        break;
      default:
        r = now.add(const Duration(days: 7));
    }
    setState(() {
      _scheduledAt = r;
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
      builder: _darkPickerTheme,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: _darkPickerTheme,
    );
    if (time == null || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _activeQuickIdx = null;
    });
  }

  Widget _darkPickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.mint,
            onPrimary: AppColors.textDark,
            surface: AppColors.cardBg,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        child: child!,
      );

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      HapticFeedback.vibrate();
      _toast('Please enter a task title', AppColors.error);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      await context.read<TasksNotifier>().addTask(
            title: title,
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            scheduledAt: _scheduledAt,
            categories: _selectedCats.toList(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _toast('Failed to save: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child:
                Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Top progress strip
              _ProgressStrip(progress: _progress),

              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ── App bar ──────────────────────────────
                      SliverToBoxAdapter(child: _buildAppBar()),

                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            _kPad, 16, _kPad, bottomPad + 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // 0 ── Voice hero ──────────────────
                            _anim(
                                0,
                                _VoiceHero(
                                  onTextCaptured: (t) =>
                                      setState(() => _titleCtrl.text = t),
                                  onParsed: (task) => setState(() {
                                    _titleCtrl.text = task.title;
                                    if (task.scheduledAt != null) {
                                      _scheduledAt = task.scheduledAt!;
                                      _activeQuickIdx = null;
                                    }
                                  }),
                                )),
                            const SizedBox(height: 16),

                            // 1 ── Title + description ─────────
                            _anim(
                                1,
                                _TitleCard(
                                  titleCtrl: _titleCtrl,
                                  descCtrl: _descCtrl,
                                )),
                            const SizedBox(height: 12),

                            // 2 ── When ─────────────────────────
                            _anim(
                                2,
                                _WhenCard(
                                  scheduledAt: _scheduledAt,
                                  dateLabel: _dateLabel,
                                  activeQuickIdx: _activeQuickIdx,
                                  onPickTap: _pickDateTime,
                                  onQuickTap: _applyQuick,
                                )),
                            const SizedBox(height: 12),

                            // 3 ── Priority ─────────────────────
                            _anim(
                                3,
                                _PriorityCard(
                                  priority: _priority,
                                  onChange: (p) =>
                                      setState(() => _priority = p),
                                )),
                            const SizedBox(height: 12),

                            // 4 ── Settings + Category ──────────
                            _anim(
                                4,
                                _SettingsCard(
                                  reminderIdx: _reminderIdx,
                                  calSync: _calSync,
                                  selectedCats: _selectedCats,
                                  onReminderTap: () => setState(() =>
                                      _reminderIdx = (_reminderIdx + 1) %
                                          _reminderOptions.length),
                                  onCalTap: () =>
                                      setState(() => _calSync = !_calSync),
                                  onCatTap: (label) => setState(() {
                                    if (_selectedCats.contains(label)) {
                                      _selectedCats.remove(label);
                                    } else {
                                      _selectedCats.add(label);
                                    }
                                  }),
                                  reminderLabel: _reminderOptions[_reminderIdx],
                                )),
                            const SizedBox(height: 24),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed CTA ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CtaBar(
              isSubmitting: _isSubmitting,
              canSubmit: _titleCtrl.text.trim().isNotEmpty,
              bottomPad: MediaQuery.of(context).padding.bottom,
              onTap: _isSubmitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // Back button — matches HomeScreen _IconBtn style
          _NavBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          const Spacer(),
          const Text('New Task',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              )),
          const Spacer(),
          _NavBtn(icon: Icons.more_horiz_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NAV BUTTON (matches HomeScreen _IconBtn)
// ─────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// PROGRESS STRIP
// ─────────────────────────────────────────────────────────────
class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 3,
        child: LayoutBuilder(
            builder: (_, c) => Stack(children: [
                  Container(color: AppColors.divider),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    width: c.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.mint, AppColors.purple],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ])),
      );
}

// ─────────────────────────────────────────────────────────────
// BASE CARD — same style as home screen cards
// ─────────────────────────────────────────────────────────────
class _SCard extends StatelessWidget {
  const _SCard(
      {required this.children, this.padding = const EdgeInsets.all(20)});
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(color: AppColors.divider),
        ),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  const _Label(this.text, {this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.mint),
            const SizedBox(width: 6),
          ],
          Text(text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              )),
        ],
      );
}

// ─────────────────────────────────────────────────────────────
// VOICE HERO — matches app palette now
// ─────────────────────────────────────────────────────────────
class _VoiceHero extends StatefulWidget {
  const _VoiceHero({required this.onTextCaptured, this.onParsed});
  final void Function(String) onTextCaptured;
  final void Function(ParsedTask)? onParsed;

  @override
  State<_VoiceHero> createState() => _VoiceHeroState();
}

class _VoiceHeroState extends State<_VoiceHero> with TickerProviderStateMixin {
  bool _listening = false;
  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final VoiceService _voice = VoiceService();
  final TaskParserService _parser = TaskParserService();
  TtsLocale _locale = TtsLocale.english;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    _voice.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    HapticFeedback.mediumImpact();
    if (_listening) {
      await _voice.stop();
      _waveCtrl.stop();
      setState(() => _listening = false);
    } else {
      setState(() => _listening = true);
      _waveCtrl.repeat(reverse: true);
      await _voice.startListening(
        onResult: (text) {
          if (widget.onParsed != null) {
            widget.onParsed!(_parser.parse(text));
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
      _locale =
          _locale == TtsLocale.english ? TtsLocale.arabic : TtsLocale.english;
    });
    await _voice.setLocale(_locale);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _locale == TtsLocale.arabic;

    return GestureDetector(
      onTap: _toggle,
      onLongPress: _switchLocale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(
            color: _listening
                ? AppColors.mint.withOpacity(0.5)
                : AppColors.divider,
            width: _listening ? 1.5 : 1.0,
          ),
          boxShadow: _listening
              ? [
                  BoxShadow(
                    color: AppColors.mint.withOpacity(0.12),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // ── Mic button ───────────────────────────────
            ScaleTransition(
              scale:
                  _listening ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening ? AppColors.mint : AppColors.innerCard,
                  border: Border.all(
                    color: _listening ? AppColors.mint : AppColors.divider,
                    width: 1.5,
                  ),
                  boxShadow: _listening
                      ? [
                          BoxShadow(
                            color: AppColors.mint.withOpacity(0.35),
                            blurRadius: 16,
                            spreadRadius: -2,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color:
                      _listening ? AppColors.textDark : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // ── Text + wave ──────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              (_listening ? AppColors.mint : AppColors.purple)
                                  .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                (_listening ? AppColors.mint : AppColors.purple)
                                    .withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          _listening ? 'LISTENING' : 'VOICE INPUT',
                          style: TextStyle(
                            color:
                                _listening ? AppColors.mint : AppColors.purple,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Language toggle
                      GestureDetector(
                        onTap: _switchLocale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.innerCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            isAr ? 'AR' : 'EN',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _listening
                        ? (isAr ? 'جاري الاستماع...' : 'Listening… speak now')
                        : (isAr ? 'اضغط للتحدث' : 'Tap to speak your task'),
                    style: TextStyle(
                      color:
                          _listening ? AppColors.mint : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'اضغط مطولاً لتغيير اللغة'
                        : 'Hold to switch language',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                  if (_listening) ...[
                    const SizedBox(height: 10),
                    _WaveBar(controller: _waveCtrl),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    const heights = [5.0, 12.0, 8.0, 14.0, 7.0, 10.0, 5.0];
    return SizedBox(
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(heights.length, (i) {
          final delay = i * 0.12;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final t = ((controller.value + delay) % 1.0);
                final scale = 0.4 + 0.6 * (t < 0.5 ? 2 * t : 2 * (1 - t));
                return Container(
                  width: 3,
                  height: heights[i] * scale,
                  decoration: BoxDecoration(
                    color: AppColors.mint.withOpacity(0.8),
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

// ─────────────────────────────────────────────────────────────
// TITLE CARD
// ─────────────────────────────────────────────────────────────
class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.titleCtrl, required this.descCtrl});
  final TextEditingController titleCtrl, descCtrl;

  @override
  Widget build(BuildContext context) {
    return _SCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        // Section label row
        Row(
          children: [
            const _Label('Task title', icon: Icons.edit_outlined),
            const Spacer(),
            // Required dot
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Required',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Title field
        _DarkField(
          controller: titleCtrl,
          hint: 'What needs to be done?',
          maxLines: 1,
          textInputAction: TextInputAction.next,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 14),

        // Description label + char counter
        Row(
          children: [
            const _Label('Notes', icon: Icons.notes_rounded),
            const Spacer(),
            Text('${titleCtrl.text.length}/80',
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                )),
          ],
        ),
        const SizedBox(height: 10),

        // Description field
        _DarkField(
          controller: descCtrl,
          hint: 'Add details or context…',
          maxLines: 2,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DARK TEXT FIELD — consistent with home screen
// ─────────────────────────────────────────────────────────────
class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.textInputAction,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w400,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputAction? textInputAction;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        textInputAction: textInputAction,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.5,
        ),
        cursorColor: AppColors.mint,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textHint,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: AppColors.innerCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kRadiusSm),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kRadiusSm),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kRadiusSm),
            borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// WHEN CARD
// ─────────────────────────────────────────────────────────────
class _WhenCard extends StatelessWidget {
  const _WhenCard({
    required this.scheduledAt,
    required this.dateLabel,
    required this.activeQuickIdx,
    required this.onPickTap,
    required this.onQuickTap,
  });
  final DateTime scheduledAt;
  final String dateLabel;
  final int? activeQuickIdx;
  final VoidCallback onPickTap;
  final void Function(int) onQuickTap;

  @override
  Widget build(BuildContext context) {
    return _SCard(children: [
      const _Label('When', icon: Icons.calendar_today_outlined),
      const SizedBox(height: 14),

      // Date + Time chips
      Row(
        children: [
          Expanded(
              child: _DateChip(
            label: 'DATE',
            value: dateLabel,
            icon: Icons.event_outlined,
            onTap: onPickTap,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _DateChip(
            label: 'TIME',
            value: DateFormat('h:mm a').format(scheduledAt),
            icon: Icons.access_time_rounded,
            onTap: onPickTap,
          )),
        ],
      ),
      const SizedBox(height: 16),

      // Quick picks label
      const Text('Quick pick',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          )),
      const SizedBox(height: 8),

      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
            _quickSlots.length,
            (i) => _QuickChip(
                  label: _quickSlots[i].label,
                  icon: _quickSlots[i].icon,
                  selected: activeQuickIdx == i,
                  onTap: () => onQuickTap(i),
                )),
      ),
    ]);
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.innerCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 11, color: AppColors.mint),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    )),
              ]),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                    color: AppColors.mint,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
      );
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.mint.withOpacity(0.1)
                : AppColors.innerCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.mint : AppColors.divider,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 12,
                  color: selected ? AppColors.mint : AppColors.textHint),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.mint : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// PRIORITY CARD — fixed colors
// ─────────────────────────────────────────────────────────────
class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.priority, required this.onChange});
  final _Priority priority;
  final void Function(_Priority) onChange;

  @override
  Widget build(BuildContext context) => _SCard(children: [
        const _Label('Priority', icon: Icons.flag_outlined),
        const SizedBox(height: 14),
        Row(children: [
          _PrioBtn(
            label: 'Low',
            icon: Icons.arrow_downward_rounded,
            color: _kLowColor,
            selected: priority == _Priority.low,
            onTap: () {
              HapticFeedback.selectionClick();
              onChange(_Priority.low);
            },
          ),
          const SizedBox(width: 8),
          _PrioBtn(
            label: 'Medium',
            icon: Icons.remove_rounded,
            color: _kMedColor,
            selected: priority == _Priority.medium,
            onTap: () {
              HapticFeedback.selectionClick();
              onChange(_Priority.medium);
            },
          ),
          const SizedBox(width: 8),
          _PrioBtn(
            label: 'High',
            icon: Icons.arrow_upward_rounded,
            color: _kHighColor,
            selected: priority == _Priority.high,
            onTap: () {
              HapticFeedback.selectionClick();
              onChange(_Priority.high);
            },
          ),
        ]),
      ]);
}

class _PrioBtn extends StatelessWidget {
  const _PrioBtn({
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
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.12) : AppColors.innerCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : AppColors.divider,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 16, color: selected ? color : AppColors.textHint),
                const SizedBox(height: 5),
                Text(label,
                    style: TextStyle(
                      color: selected ? color : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    )),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// SETTINGS CARD — FIXED (was rendering empty before)
// ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.reminderIdx,
    required this.calSync,
    required this.selectedCats,
    required this.onReminderTap,
    required this.onCalTap,
    required this.onCatTap,
    required this.reminderLabel,
  });
  final int reminderIdx;
  final bool calSync;
  final Set<String> selectedCats;
  final VoidCallback onReminderTap, onCalTap;
  final void Function(String) onCatTap;
  final String reminderLabel;

  @override
  Widget build(BuildContext context) => _SCard(children: [
        // ── Reminder ─────────────────────────────────────
        _SettingRow(
          icon: Icons.notifications_outlined,
          iconColor: AppColors.purple,
          label: 'Reminder',
          value: reminderLabel,
          valueColor: AppColors.purple,
          onTap: () {
            HapticFeedback.selectionClick();
            onReminderTap();
          },
        ),

        Container(
            height: 1,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(vertical: 4)),

        // ── Google Calendar ───────────────────────────────
        _SettingRow(
          icon: Icons.calendar_month_outlined,
          iconColor: calSync ? AppColors.mint : AppColors.textHint,
          label: 'Google Calendar',
          value: calSync ? 'On' : 'Off',
          valueColor: calSync ? AppColors.mint : AppColors.textHint,
          onTap: () {
            HapticFeedback.selectionClick();
            onCalTap();
          },
          trailing: _ToggleSwitch(value: calSync, onTap: onCalTap),
        ),

        const SizedBox(height: 16),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 16),

        // ── Category ─────────────────────────────────────
        const _Label('Category', icon: Icons.category_outlined),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._categories.map((cat) => _CatChip(
                  label: cat.label,
                  icon: cat.icon,
                  color: cat.color,
                  selected: selectedCats.contains(cat.label),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCatTap(cat.label);
                  },
                )),
            _AddCatChip(onTap: () {}),
          ],
        ),
      ]);
}

// ─────────────────────────────────────────────────────────────
// SETTING ROW — FIXED (original was returning empty Container)
// ─────────────────────────────────────────────────────────────
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String label, value;
  final Color? valueColor;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),

              // Label
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ),

              // Value or trailing
              if (trailing != null)
                trailing!
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value,
                        style: TextStyle(
                          color: valueColor ?? AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.textHint),
                  ],
                ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// TOGGLE SWITCH
// ─────────────────────────────────────────────────────────────
class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, required this.onTap});
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AppColors.mint : AppColors.innerCard,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: value ? AppColors.mint : AppColors.divider,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? AppColors.textDark : AppColors.textHint,
              ),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// CATEGORY CHIP
// ─────────────────────────────────────────────────────────────
class _CatChip extends StatelessWidget {
  const _CatChip({
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : AppColors.innerCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : AppColors.divider,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13, color: selected ? color : AppColors.textHint),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : AppColors.textSecondary,
                  )),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_rounded, size: 11, color: color),
              ],
            ],
          ),
        ),
      );
}

class _AddCatChip extends StatelessWidget {
  const _AddCatChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.innerCard,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.divider, style: BorderStyle.solid),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 13, color: AppColors.textHint),
              SizedBox(width: 4),
              Text('New',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  )),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// CTA BAR
// ─────────────────────────────────────────────────────────────
class _CtaBar extends StatelessWidget {
  const _CtaBar({
    required this.isSubmitting,
    required this.canSubmit,
    required this.bottomPad,
    this.onTap,
  });
  final bool isSubmitting, canSubmit;
  final double bottomPad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.92),
              border: const Border(top: BorderSide(color: AppColors.divider)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
            child: _SubmitBtn(
              isSubmitting: isSubmitting,
              canSubmit: canSubmit,
              onTap: onTap,
            ),
          ),
        ),
      );
}

class _SubmitBtn extends StatefulWidget {
  const _SubmitBtn({
    required this.isSubmitting,
    required this.canSubmit,
    this.onTap,
  });
  final bool isSubmitting, canSubmit;
  final VoidCallback? onTap;

  @override
  State<_SubmitBtn> createState() => _SubmitBtnState();
}

class _SubmitBtnState extends State<_SubmitBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.97,
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
          height: 56,
          decoration: BoxDecoration(
            color: disabled ? AppColors.innerCard : null,
            gradient: disabled
                ? null
                : const LinearGradient(
                    colors: [AppColors.mint, Color(0xFF22A99A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: disabled ? AppColors.divider : Colors.transparent,
            ),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.mint.withOpacity(0.3),
                      blurRadius: 20,
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
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: AppColors.textDark, strokeWidth: 2.5),
                    ))
                : Center(
                    key: const ValueKey('label'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          disabled ? Icons.edit_outlined : Icons.add_rounded,
                          color: disabled
                              ? AppColors.textHint
                              : AppColors.textDark,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          disabled ? 'Add a title to continue' : 'Create Task',
                          style: TextStyle(
                            color: disabled
                                ? AppColors.textHint
                                : AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
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
