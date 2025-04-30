import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;

  Future<bool> initialize() async {
    bool available = await _speechToText.initialize();
    if (available) {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    }
    return available;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function() onError,
  }) async {
    if (!_isListening) {
      _isListening = true;
      try {
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              onResult(result.recognizedWords);
              _isListening = false;
            }
          },
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          partialResults: false,
        );
      } catch (e) {
        onError();
        _isListening = false;
      }
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  bool get isListening => _isListening;
} 