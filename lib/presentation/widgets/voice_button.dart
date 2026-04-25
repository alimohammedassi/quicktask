// lib/presentation/widgets/voice_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../services/voice_service.dart';
import '../../services/task_parser_service.dart';

class VoiceButton extends ConsumerStatefulWidget {
  final Function(String text)? onTextCaptured;
  final Function(ParsedTask task)? onParsed;
  final bool enableParsing;

  const VoiceButton({
    this.onTextCaptured,
    this.onParsed,
    this.enableParsing = true,
    super.key,
  });

  @override
  ConsumerState<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends ConsumerState<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isListening = false;
  bool _isPrompting = false;
  String _statusText = 'Tap to speak';
  final VoiceService _voice = VoiceService();
  final TaskParserService _parser = TaskParserService();
  TtsLocale _currentLocale = TtsLocale.english;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseController.stop();
  }

  void _setStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voice.stop();
      _pulseController.stop();
      setState(() => _isListening = false);
      _setStatus('Tap to speak');
    } else {
      await _playPromptAndListen();
    }
  }

  Future<void> _playPromptAndListen() async {
    setState(() {
      _isListening = true;
      _isPrompting = false;
    });
    _setStatus(_currentLocale == TtsLocale.arabic ? 'جاري التسجيل...' : 'Recording...');

    _pulseController.repeat(reverse: true);

    await _voice.startListening(
      onResult: (text) {
        if (widget.enableParsing && widget.onParsed != null) {
          final parsed = _parser.parse(text);
          widget.onParsed!(parsed);
        } else {
          widget.onTextCaptured?.call(text);
        }
      },
      onDone: () {
        if (mounted) {
          _pulseController.stop();
          setState(() {
            _isListening = false;
            _statusText = 'Tap to speak';
          });
        }
      },
    );
  }

  Future<void> _switchLocale() async {
    setState(() {
      _currentLocale = _currentLocale == TtsLocale.english
          ? TtsLocale.arabic
          : TtsLocale.english;
      _statusText = _currentLocale == TtsLocale.arabic
          ? 'انقر للتحدث'
          : 'Tap to speak';
    });
    await _voice.setLocale(_currentLocale);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = _isListening
                ? 1.0 + (_pulseController.value * 0.15)
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring while listening
                  if (_isListening)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _toggleListening,
                    onLongPress: _switchLocale,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? AppColors.error
                            : _isPrompting
                                ? AppColors.accent
                                : AppColors.primary,
                        gradient: _isListening || _isPrompting
                            ? null
                            : AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening
                                    ? AppColors.error
                                    : AppColors.primary)
                                .withValues(alpha: 0.5),
                            blurRadius: _isListening ? 28 : 12,
                            spreadRadius: _isListening ? 6 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening
                            ? Icons.stop_rounded
                            : _isPrompting
                                ? Icons.volume_up_rounded
                                : Icons.mic_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: _isListening ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _switchLocale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentLocale == TtsLocale.arabic ? 'EN' : 'ع',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _voice.stop();
    _pulseController.dispose();
    super.dispose();
  }
}
