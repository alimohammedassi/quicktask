import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/voice_button.dart';
import '../../services/task_parser_service.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final String? initialText;
  final ParsedTask? initialParsed;
  const AddTaskScreen({this.initialText, this.initialParsed, super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen>
    with TickerProviderStateMixin {
  late TextEditingController _titleCtrl;
  final TextEditingController _descCtrl = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  bool _isSubmitting = false;

  late AnimationController _entranceController;
  late AnimationController _pulseController;

  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;
  late Animation<double> _pulse;

  int _selectedPriority = 1;

  static const _priorities = [
    _PriorityData(label: 'Low', emoji: '🟢', colorHex: 0xFF22C55E),
    _PriorityData(label: 'Medium', emoji: '🟡', colorHex: 0xFFF59E0B),
    _PriorityData(label: 'High', emoji: '🔴', colorHex: 0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
        text: widget.initialText ?? widget.initialParsed?.title ?? '');
    if (widget.initialParsed?.scheduledAt != null) {
      _scheduledAt = widget.initialParsed!.scheduledAt!;
    }

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Staggered card animations — 5 cards
    _cardFades = List.generate(5, (i) {
      final start = i * 0.12;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve:
              Interval(start, (start + 0.4).clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });

    _cardSlides = List.generate(5, (i) {
      final start = i * 0.12;
      return Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve:
              Interval(start, (start + 0.4).clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildCard({required int index, required Widget child}) {
    return FadeTransition(
      opacity: _cardFades[index],
      child: SlideTransition(
        position: _cardSlides[index],
        child: child,
      ),
    );
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.selectionClick();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
          timePickerTheme: TimePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      HapticFeedback.vibrate();
      _showErrorSnack('Please enter a task title');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(tasksNotifierProvider.notifier).addTask(
            title: _titleCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            scheduledAt: _scheduledAt,
          );
    } catch (e) {
      if (mounted) _showErrorSnack('Failed to save task: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Is the scheduled date today? ────────────────────────────────────────
  bool get _isToday {
    final now = DateTime.now();
    return _scheduledAt.year == now.year &&
        _scheduledAt.month == now.month &&
        _scheduledAt.day == now.day;
  }

  bool get _isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _scheduledAt.year == tomorrow.year &&
        _scheduledAt.month == tomorrow.month &&
        _scheduledAt.day == tomorrow.day;
  }

  String get _dateLabel {
    if (_isToday) return 'Today';
    if (_isTomorrow) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(_scheduledAt);
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.bgLight;
    const surface = Colors.white;
    const surfaceElevated = Colors.white;
    const border = AppColors.cardBorder;
    const accent = AppColors.primary;
    const accentLight = AppColors.accent;
    const textPrimary = AppColors.textPrimary;
    const textSecondary = AppColors.textSecondary;
    const textHint = AppColors.textHint;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ─── Ambient gradient orbs ──────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withOpacity(0.18),
                    accent.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── Main scroll content ────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 44, // Slightly larger touch target
                            height: 44, // Slightly larger touch target
                            decoration: BoxDecoration(
                              color: surfaceElevated,
                              borderRadius:
                                  BorderRadius.circular(14), // Rounded corners
                              border: Border.all(
                                  color:
                                      border.withOpacity(0.7)), // Subtle border
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: textSecondary,
                              size: 18, // Slightly larger icon
                            ),
                          ),
                        ),
                        const SizedBox(width: 16), // Increased spacing
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New Task',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 28, // Larger title
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4), // Adjusted spacing
                            Text(
                              DateFormat('EEEE, MMMM d').format(DateTime.now()),
                              style: const TextStyle(
                                color: textHint,
                                fontSize: 14, // Slightly larger date text
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Completion step indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7), // Adjusted padding
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(22), // More rounded
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: const Text(
                            '✦ New',
                            style: TextStyle(
                              color: accentLight,
                              fontSize: 13, // Slightly larger text
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 32, // Increased top padding
                    bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Card 0: Voice input ──────────────────────
                      _buildCard(
                        index: 0,
                        child: _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _IconBadge(
                                    icon: Icons.mic_rounded, // Changed icon
                                    color: accent,
                                  ),
                                  const SizedBox(
                                      width: 16), // Increased spacing
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Voice Input',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17, // Increased font size
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      SizedBox(height: 4), // Adjusted spacing
                                      Text(
                                        "Speak and we'll fill the form",
                                        style: TextStyle(
                                          color: textHint,
                                          fontSize: 14, // Increased font size
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28), // Increased spacing
                              Center(
                                child: VoiceButton(
                                  onTextCaptured: (text) {
                                    HapticFeedback.lightImpact();
                                    setState(() => _titleCtrl.text = text);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18), // Adjusted spacing

                      // ── Card 1: Title + Description ──────────────
                      _buildCard(
                        index: 1,
                        child: _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DarkTextField(
                                controller: _titleCtrl,
                                label: 'What needs doing?',
                                hint: 'e.g. Review the quarterly report…',
                                maxLines: 1,
                                autofocus: false,
                              ),
                              const SizedBox(height: 24), // Adjusted spacing
                              const _Divider(),
                              const SizedBox(height: 24), // Adjusted spacing
                              _DarkTextField(
                                controller: _descCtrl,
                                label: 'Notes',
                                hint: 'Any extra context or details…',
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18), // Adjusted spacing

                      // ── Card 2: Priority ─────────────────────────
                      _buildCard(
                        index: 2,
                        child: _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _IconBadge(
                                    icon: Icons.flag_rounded, // Changed icon
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(
                                      width: 16), // Increased spacing
                                  const Text(
                                    'Priority',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17, // Increased font size
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22), // Adjusted spacing
                              Row(
                                children: List.generate(3, (i) {
                                  final p = _priorities[i];
                                  final isSelected = _selectedPriority == i;
                                  final color = Color(p.colorHex);
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: i < 2
                                              ? 12
                                              : 0), // Adjusted spacing
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _selectedPriority = i);
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 220),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 18), // Adjusted padding
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? color.withOpacity(0.15)
                                                : surfaceElevated,
                                            borderRadius: BorderRadius.circular(
                                                18), // More rounded
                                            border: Border.all(
                                              color: isSelected
                                                  ? color.withOpacity(0.6)
                                                  : border,
                                              width: isSelected ? 1.8 : 1,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: color
                                                          .withOpacity(0.15),
                                                      blurRadius: 12,
                                                      spreadRadius: 2,
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: Column(
                                            children: [
                                              Text(p.emoji,
                                                  style: const TextStyle(
                                                      fontSize:
                                                          24)), // Increased emoji size
                                              const SizedBox(
                                                  height:
                                                      10), // Adjusted spacing
                                              Text(
                                                p.label,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? color
                                                      : textHint,
                                                  fontSize:
                                                      14, // Increased font size
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18), // Adjusted spacing

                      // ── Card 3: Date & Time ──────────────────────
                      _buildCard(
                        index: 3,
                        child: GestureDetector(
                          onTap: _pickDateTime,
                          child: _GlassCard(
                            child: Row(
                              children: [
                                _IconBadge(
                                  icon: Icons
                                      .calendar_month_rounded, // Changed icon
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dateLabel,
                                        style: const TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18, // Increased font size
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: 6), // Adjusted spacing
                                      Text(
                                        DateFormat('h:mm a  •  yyyy')
                                            .format(_scheduledAt),
                                        style: const TextStyle(
                                          color: textHint,
                                          fontSize: 15, // Increased font size
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9), // Adjusted padding
                                  decoration: BoxDecoration(
                                    color: border.withOpacity(
                                        0.7), // Slightly more visible
                                    borderRadius: BorderRadius.circular(
                                        14), // More rounded
                                  ),
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 14, // Increased font size
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40), // Increased spacing

                      // ── Card 4: Submit ───────────────────────────
                      _buildCard(
                        index: 4,
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 68, // Increased height
                              child: _SubmitButton(
                                isSubmitting: _isSubmitting,
                                onTap: _isSubmitting ? null : _submit,
                              ),
                            ),
                            const SizedBox(height: 20), // Adjusted spacing
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8, // Increased size
                                  height: 8, // Increased size
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12), // Adjusted spacing
                                const Text(
                                  'Syncs to Google Calendar automatically',
                                  style: TextStyle(
                                    color: textHint,
                                    fontSize: 14, // Increased font size
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ]),
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

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens & Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Increased border radius
        border: Border.all(
            color: AppColors.cardBorder.withOpacity(0.7)), // Subtle border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // Slightly stronger shadow
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, // Increased size for better visual weight
      height: 48, // Increased size
      decoration: BoxDecoration(
        color: color.withOpacity(0.18), // Slightly more opaque
        borderRadius: BorderRadius.circular(16), // Adjusted border radius
        border: Border.all(
            color: color.withOpacity(0.3)), // Slightly more opaque border
      ),
      child: Icon(icon, color: color, size: 24), // Increased icon size
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.cardBorder.withOpacity(0.8), // More visible divider
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool autofocus;

  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12, // Increased font size
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5, // Increased letter spacing
          ),
        ),
        const SizedBox(height: 12), // Adjusted spacing
        TextField(
          controller: controller,
          maxLines: maxLines,
          autofocus: autofocus,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16, // Increased font size
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          cursorColor: AppColors.primary,
          cursorWidth: 2, // Increased cursor width
          cursorRadius: const Radius.circular(2),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textHint,
              fontSize: 15, // Increased font size
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor:
                AppColors.bgLight.withOpacity(0.7), // Slightly transparent fill
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 16), // Adjusted padding
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16), // Increased border radius
              borderSide: BorderSide.none, // No border by default
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: AppColors.cardBorder, width: 1), // Subtle border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2), // More prominent focus border
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final bool isSubmitting;
  final VoidCallback? onTap;
  const _SubmitButton({required this.isSubmitting, this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressCtrl;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22), // Increased border radius
            gradient: widget.isSubmitting
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary, // Using primary
                      AppColors.accent, // Using accent
                    ],
                  ),
            color: widget.isSubmitting
                ? AppColors.cardBorder
                    .withOpacity(0.7) // Greyed out when submitting
                : null,
            boxShadow: widget.isSubmitting
                ? null
                : [
                    BoxShadow(
                      color:
                          AppColors.primary.withOpacity(0.5), // Stronger shadow
                      blurRadius: 28, // Increased blur
                      offset: const Offset(0, 10), // Adjusted offset
                      spreadRadius: -6, // Adjusted spread
                    ),
                  ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: widget.isSubmitting
                ? const Center(
                    key: ValueKey('loading'),
                    child: SizedBox(
                      width: 24, // Increased size
                      height: 24, // Increased size
                      child: CircularProgressIndicator(
                        color:
                            Colors.white, // White spinner for better contrast
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : const Row(
                    key: ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_task_rounded, // Changed icon
                          color: Colors.white,
                          size: 24), // Increased icon size
                      SizedBox(width: 10), // Adjusted spacing
                      Text(
                        'Create Task', // Changed text
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18, // Increased font size
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
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

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityData {
  final String label;
  final String emoji;
  final int colorHex;
  const _PriorityData(
      {required this.label, required this.emoji, required this.colorHex});
}
