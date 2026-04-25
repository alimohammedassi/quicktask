// lib/services/voice_service.dart
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsLocale { english, arabic }

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  TtsLocale _locale = TtsLocale.english;

  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    return _isInitialized;
  }

  Future<void> setLocale(TtsLocale locale) async {
    _locale = locale;
    if (locale == TtsLocale.arabic) {
      await _tts.setLanguage('ar-SA');
    } else {
      await _tts.setLanguage('en-US');
    }
  }

  Future<void> speakPrompt(String text) async {
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _speech.stop();
    await _tts.stop();
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
  }) async {
    if (!_isInitialized) await initialize();

    final localeId = _locale == TtsLocale.arabic ? 'ar-SA' : 'en-US';

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
      listenOptions: SpeechListenOptions(cancelOnError: true),
    );
  }

  bool get isListening => _speech.isListening;
}
