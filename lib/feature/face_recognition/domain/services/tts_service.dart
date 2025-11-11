import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';

/// ✅ ENHANCED: TTS with voice customization options
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  
  // ✅ Voice settings (customizable)
  String _language = "en-US";
  double _speechRate = 0.5;  // 0.0 (slow) to 1.0 (fast)
  double _volume = 1.0;      // 0.0 (silent) to 1.0 (loud)
  double _pitch = 1.0;       // 0.5 (low) to 2.0 (high)
  String? _selectedVoice;    // Specific voice name
  
  // Available voices list
List<Map<String, dynamic>> _availableVoices = [];
  /// ✅ Initialize TTS with saved settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print("🔊 Initializing Text-to-Speech...");

      // Load saved settings
      await _loadSettings();
      
      // Get available voices
      await _loadAvailableVoices();
      
      // Apply settings
      await _applySettings();

      _isInitialized = true;
      print("✅ Text-to-Speech initialized successfully");
      print("   Language: $_language");
      print("   Rate: $_speechRate");
      print("   Pitch: $_pitch");
      print("   Volume: $_volume");
      if (_selectedVoice != null) {
        print("   Voice: $_selectedVoice");
      }
    } catch (e) {
      print("❌ TTS initialization error: $e");
      _isInitialized = false;
    }
  }

  /// ✅ Load saved settings from Hive
  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox('settingsBox');
      
      _language = box.get('ttsLanguage', defaultValue: 'en-US');
      _speechRate = box.get('ttsSpeechRate', defaultValue: 0.5);
      _volume = box.get('ttsVolume', defaultValue: 1.0);
      _pitch = box.get('ttsPitch', defaultValue: 1.0);
      _selectedVoice = box.get('ttsVoice');
      
      print("📦 Loaded TTS settings from storage");
    } catch (e) {
      print("⚠️ Could not load TTS settings: $e");
    }
  }

  /// ✅ Get list of available voices
Future<void> _loadAvailableVoices() async {
  try {
    final voices = await _flutterTts.getVoices;
    if (voices is List) {
      // ✅ FIXED: Properly cast each voice map
      _availableVoices = voices.map((voice) {
        if (voice is Map) {
          return {
            'name': voice['name']?.toString() ?? '',
            'locale': voice['locale']?.toString() ?? '',
          };
        }
        return {'name': '', 'locale': ''};
      }).toList();
      
      print("🎙️ Available voices: ${_availableVoices.length}");
      
      // Print first 5 voices for debugging
      for (int i = 0; i < min(_availableVoices.length, 5); i++) {
        print("   ${i + 1}. ${_availableVoices[i]['name']} (${_availableVoices[i]['locale']})");
      }
    }
  } catch (e) {
    print("⚠️ Could not load voices: $e");
    _availableVoices = []; // Set empty list on error
  }
}

  /// ✅ Apply current settings to TTS
Future<void> _applySettings() async {
  try {
    await _flutterTts.setLanguage(_language);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);
    
    // Set specific voice if selected
    if (_selectedVoice != null && _selectedVoice!.isNotEmpty) {
      await _flutterTts.setVoice({
        "name": _selectedVoice!, // ✅ Add ! to assert non-null
        "locale": _language
      });
    }

    // Platform-specific settings
    if (await _flutterTts.isLanguageAvailable(_language)) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
      await _flutterTts.awaitSpeakCompletion(true);
    }
  } catch (e) {
    print("⚠️ Error applying TTS settings: $e");
  }
}
  /// ✅ Update voice settings and save
  Future<void> updateSettings({
    String? language,
    double? speechRate,
    double? volume,
    double? pitch,
    String? voice,
  }) async {
    final box = await Hive.openBox('settingsBox');
    
    if (language != null) {
      _language = language;
      await box.put('ttsLanguage', language);
    }
    
    if (speechRate != null) {
      _speechRate = speechRate;
      await box.put('ttsSpeechRate', speechRate);
    }
    
    if (volume != null) {
      _volume = volume;
      await box.put('ttsVolume', volume);
    }
    
    if (pitch != null) {
      _pitch = pitch;
      await box.put('ttsPitch', pitch);
    }
    
    if (voice != null) {
      _selectedVoice = voice;
      await box.put('ttsVoice', voice);
    }
    
    // Re-apply settings
    await _applySettings();
    
    print("✅ TTS settings updated");
  }

  /// ✅ Get available voices
  List<Map<String, dynamic>> getAvailableVoices() {
    return _availableVoices;
  }

  /// ✅ Get current settings
  Map<String, dynamic> getCurrentSettings() {
    return {
      'language': _language,
      'speechRate': _speechRate,
      'volume': _volume,
      'pitch': _pitch,
      'voice': _selectedVoice,
    };
  }

  /// ✅ Speak greeting for clock-in
  Future<void> speakClockIn(String name) async {
    await _ensureInitialized();
    
    String cleanName = _cleanName(name);
    String message = "Hello $cleanName. You are clocked in.";
    print("🔊 Speaking: $message");
    
    try {
      await _flutterTts.speak(message);
    } catch (e) {
      print("❌ TTS speak error: $e");
    }
  }

  /// ✅ Speak greeting for clock-out
  Future<void> speakClockOut(String name) async {
    await _ensureInitialized();
    
    String cleanName = _cleanName(name);
    String message = "Goodbye $cleanName. You are clocked out.";
    print("🔊 Speaking: $message");
    
    try {
      await _flutterTts.speak(message);
    } catch (e) {
      print("❌ TTS speak error: $e");
    }
  }

  /// ✅ Speak custom message
  Future<void> speak(String message) async {
    await _ensureInitialized();
    print("🔊 Speaking: $message");
    
    try {
      await _flutterTts.speak(message);
    } catch (e) {
      print("❌ TTS speak error: $e");
    }
  }

  /// ✅ Stop current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print("❌ TTS stop error: $e");
    }
  }

  /// ✅ Check if currently speaking
  Future<bool> isSpeaking() async {
    try {
      final result = await _flutterTts.awaitSpeakCompletion(true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// ✅ Clean name for better pronunciation
  String _cleanName(String name) {
    String cleaned = name.replaceAll(RegExp(r'[^\w\s]'), '');
    cleaned = cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');
    return cleaned;
  }

  /// ✅ Ensure initialized before use
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// ✅ Dispose resources
  void dispose() {
    _flutterTts.stop();
  }
  
  // Helper for min function
  int min(int a, int b) => a < b ? a : b;
}

// import 'package:flutter_tts/flutter_tts.dart';

// /// ✅ TEXT-TO-SPEECH SERVICE
// /// Speaks person's name when they clock in/out
// class TTSService {
//   static final TTSService _instance = TTSService._internal();
//   factory TTSService() => _instance;
//   TTSService._internal();

//   final FlutterTts _flutterTts = FlutterTts();
//   bool _isInitialized = false;
 

//   /// ✅ Initialize TTS with settings
//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     try {
//       print("🔊 Initializing Text-to-Speech...");

//       // Set language
//       await _flutterTts.setLanguage("en-US");

//       // Set speech rate (0.0 to 1.0, default 0.5)
//       await _flutterTts.setSpeechRate(0.5);

//       // Set volume (0.0 to 1.0, default 1.0)
//       await _flutterTts.setVolume(1.1);

//       // Set pitch (0.5 to 2.0, default 1.0)
//       await _flutterTts.setPitch(1.0);

//       // Platform-specific settings
//       if (await _flutterTts.isLanguageAvailable("en-US")) {
//         // iOS specific
//         await _flutterTts.setSharedInstance(true);
//         await _flutterTts.setIosAudioCategory(
//           IosTextToSpeechAudioCategory.playback,
//           [
//             IosTextToSpeechAudioCategoryOptions.allowBluetooth,
//             IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
//             IosTextToSpeechAudioCategoryOptions.mixWithOthers,
//           ],
//           IosTextToSpeechAudioMode.voicePrompt,
//         );

// // Wait for speech to complete:
//       await _flutterTts.awaitSpeakCompletion(true);
//       }

//       _isInitialized = true;
//       print("✅ Text-to-Speech initialized successfully");
//     } catch (e) {
//       print("❌ TTS initialization error: $e");
//       _isInitialized = false;
//     }
//   }

//   /// ✅ Speak greeting for clock-in
//   Future<void> speakClockIn(String name) async {
//     await _ensureInitialized();
    
//     // Clean name (remove special characters)
//     String cleanName = _cleanName(name);
    
//     String message = "Hello $cleanName. You are clocked in.";
//     print("🔊 Speaking: $message");
    
//     try {
//       await _flutterTts.speak(message);
//     } catch (e) {
//       print("❌ TTS speak error: $e");
//     }
//   }

//   /// ✅ Speak greeting for clock-out
//   Future<void> speakClockOut(String name) async {
//     await _ensureInitialized();
    
//     String cleanName = _cleanName(name);
//     String message = "Goodbye $cleanName. You are clocked out.";
//     print("🔊 Speaking: $message");
    
//     try {
//       await _flutterTts.speak(message);
//     } catch (e) {
//       print("❌ TTS speak error: $e");
//     }
//   }

//   /// ✅ Speak custom message
//   Future<void> speak(String message) async {
//     await _ensureInitialized();
//     print("🔊 Speaking: $message");
    
//     try {
//       await _flutterTts.speak(message);
//     } catch (e) {
//       print("❌ TTS speak error: $e");
//     }
//   }

//   /// ✅ Stop current speech
//   Future<void> stop() async {
//     try {
//       await _flutterTts.stop();
//     } catch (e) {
//       print("❌ TTS stop error: $e");
//     }
//   }

//   /// ✅ Check if currently speaking
//   Future<bool> isSpeaking() async {
//     try {
//       final result = await _flutterTts.awaitSpeakCompletion(true);
//       return result ?? false;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// ✅ Clean name for better pronunciation
//   String _cleanName(String name) {
//     // Remove special characters but keep spaces
//     String cleaned = name.replaceAll(RegExp(r'[^\w\s]'), '');
    
//     // Remove extra spaces
//     cleaned = cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');
    
//     return cleaned;
//   }

//   /// ✅ Ensure initialized before use
//   Future<void> _ensureInitialized() async {
//     if (!_isInitialized) {
//       await initialize();
//     }
//   }

//   /// ✅ Dispose resources
//   void dispose() {
//     _flutterTts.stop();
//   }
// }