import 'dart:async';
import 'dart:typed_data';
import 'wyoming_messages.dart';

/// Base class for different Wyoming Satellite operation modes
abstract class WyomingSatelliteMode {
  /// Process audio from microphone
  Future<void> processAudio(Uint8List audioData);
  
  /// Start the satellite in this mode
  Future<void> start();
  
  /// Stop the satellite running in this mode
  Future<void> stop();
  
  /// Get the name of this satellite mode
  String get modeName;
}

/// Always streaming satellite mode
/// Continuously streams audio to the server without analyzing it locally
class AlwaysStreamingSatellite extends WyomingSatelliteMode {
  final Function(Uint8List) _sendAudioFunction;
  final Function(String) _startSessionFunction; 
  final Function(String) _stopSessionFunction;
  String _currentSessionId = '';
  bool _isStreaming = false;
  
  AlwaysStreamingSatellite({
    required Function(Uint8List) sendAudio,
    required Function(String) startSession,
    required Function(String) stopSession,
  }) : 
    _sendAudioFunction = sendAudio,
    _startSessionFunction = startSession,
    _stopSessionFunction = stopSession;

  @override
  Future<void> processAudio(Uint8List audioData) async {
    if (_isStreaming) {
      // Always stream all audio
      await _sendAudioFunction(audioData);
    }
  }

  @override
  Future<void> start() async {
    if (!_isStreaming) {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _startSessionFunction(_currentSessionId);
      _isStreaming = true;
    }
  }

  @override
  Future<void> stop() async {
    if (_isStreaming) {
      await _stopSessionFunction(_currentSessionId);
      _isStreaming = false;
      _currentSessionId = '';
    }
  }
  
  @override
  String get modeName => 'AlwaysStreaming';
}

/// VAD-based streaming satellite mode
/// Only streams audio when voice activity is detected
class VadStreamingSatellite extends WyomingSatelliteMode {
  final Function(Uint8List) _sendAudioFunction;
  final Function(String) _startSessionFunction; 
  final Function(String) _stopSessionFunction;
  final Function(String, bool) _sendVadFunction;
  
  String _currentSessionId = '';
  bool _isVoiceActive = false;
  bool _isSessionActive = false;
  final Duration _silenceTimeout;
  Timer? _silenceTimer;
  
  VadStreamingSatellite({
    required Function(Uint8List) sendAudio,
    required Function(String) startSession,
    required Function(String) stopSession, 
    required Function(String, bool) sendVad,
    Duration silenceTimeout = const Duration(milliseconds: 1000),
  }) : 
    _sendAudioFunction = sendAudio,
    _startSessionFunction = startSession,
    _stopSessionFunction = stopSession,
    _sendVadFunction = sendVad,
    _silenceTimeout = silenceTimeout;

  @override
  Future<void> processAudio(Uint8List audioData) async {
    // This is where you'd run VAD (Voice Activity Detection)
    // For demonstration, assume external VAD results control this class through setVoiceActive()
    
    if (_isSessionActive) {
      // Only send audio when a session is active (after VAD detected speech)
      await _sendAudioFunction(audioData);
    }
  }

  /// Set the current voice activity state from your VAD model
  Future<void> setVoiceActive(bool isActive) async {
    if (isActive == _isVoiceActive) return; // No change
    
    _isVoiceActive = isActive;
    
    if (isActive && !_isSessionActive) {
      // Voice became active, start session
      _silenceTimer?.cancel();
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _startSessionFunction(_currentSessionId);
      await _sendVadFunction(_currentSessionId, true);
      _isSessionActive = true;
    } 
    else if (!isActive && _isSessionActive) {
      // Voice became inactive, start timeout
      _silenceTimer?.cancel();
      await _sendVadFunction(_currentSessionId, false);
      
      _silenceTimer = Timer(_silenceTimeout, () async {
        // Only stop session after silence timeout
        if (_isSessionActive) {
          await _stopSessionFunction(_currentSessionId);
          _isSessionActive = false;
          _currentSessionId = '';
        }
      });
    }
  }

  @override
  Future<void> start() async {
    // Start the VAD system
    // Actual session start happens when voice becomes active
  }

  @override
  Future<void> stop() async {
    _silenceTimer?.cancel();
    if (_isSessionActive) {
      await _stopSessionFunction(_currentSessionId);
      _isSessionActive = false;
      _currentSessionId = '';
      _isVoiceActive = false;
    }
  }
  
  @override
  String get modeName => 'VadStreaming';
}

/// Wake word streaming satellite mode 
/// Only streams audio after wake word is detected
class WakeStreamingSatellite extends WyomingSatelliteMode {
  final Function(Uint8List) _sendAudioFunction;
  final Function(String) _startSessionFunction; 
  final Function(String) _stopSessionFunction;
  final Function(String, String) _sendHotwordFunction;
  final Function(String, bool) _sendVadFunction;
  
  String _currentSessionId = '';
  bool _isSessionActive = false;
  bool _isVoiceActive = false;
  final Duration _sessionTimeout;
  Timer? _sessionTimer;
  
  WakeStreamingSatellite({
    required Function(Uint8List) sendAudio,
    required Function(String) startSession,
    required Function(String) stopSession,
    required Function(String, String) sendHotword,
    required Function(String, bool) sendVad,
    Duration sessionTimeout = const Duration(seconds: 10),
  }) : 
    _sendAudioFunction = sendAudio,
    _startSessionFunction = startSession,
    _stopSessionFunction = stopSession,
    _sendHotwordFunction = sendHotword,
    _sendVadFunction = sendVad,
    _sessionTimeout = sessionTimeout;

  @override
  Future<void> processAudio(Uint8List audioData) async {
    // This is where you'd run wakeword detection
    // For demonstration, assume external wake word detection through wakeWordDetected()
    
    if (_isSessionActive) {
      // Send audio only when a wake word has activated a session
      await _sendAudioFunction(audioData);
    }
  }

  /// Call when a wake word is detected 
  Future<void> wakeWordDetected(String wakeWord) async {
    // Start a new session with the detected wake word
    _sessionTimer?.cancel();
    
    if (!_isSessionActive) {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _startSessionFunction(_currentSessionId);
      await _sendHotwordFunction(_currentSessionId, wakeWord);
      _isSessionActive = true;
      
      // Auto timeout session after a period
      _sessionTimer = Timer(_sessionTimeout, () {
        _stopSession();
      });
    }
  }
  
  /// Set voice activity state from your VAD model
  Future<void> setVoiceActive(bool isActive) async {
    if (isActive == _isVoiceActive) return; // No change
    
    _isVoiceActive = isActive;
    
    if (_isSessionActive) {
      await _sendVadFunction(_currentSessionId, isActive);
      
      if (isActive) {
        // Extend session timeout if there's voice activity
        _sessionTimer?.cancel();
        _sessionTimer = Timer(_sessionTimeout, () {
          _stopSession();
        });
      }
    }
  }
  
  Future<void> _stopSession() async {
    if (_isSessionActive) {
      await _stopSessionFunction(_currentSessionId);
      _isSessionActive = false;
      _currentSessionId = '';
    }
  }

  @override
  Future<void> start() async {
    // Start the wake word detection system
    // Actual session control happens when wake word detected
  }

  @override
  Future<void> stop() async {
    _sessionTimer?.cancel();
    if (_isSessionActive) {
      await _stopSessionFunction(_currentSessionId);
      _isSessionActive = false;
      _currentSessionId = '';
    }
  }
  
  @override
  String get modeName => 'WakeStreaming';
}
