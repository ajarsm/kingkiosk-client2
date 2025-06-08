import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

class TtsService extends GetxService {
  static TtsService get to => Get.find();

  FlutterTts? _flutterTts;

  // Observable properties
  final RxBool isInitialized = false.obs;
  final RxBool isSpeaking = false.obs;
  final RxBool isPaused = false.obs;
  final RxDouble volume = 1.0.obs;
  final RxDouble speechRate = 0.5.obs;
  final RxDouble pitch = 1.0.obs;
  final RxString currentLanguage = 'en-US'.obs;
  final RxList<String> availableLanguages = <String>[].obs;
  final RxList<String> availableVoices = <String>[].obs;
  final RxString currentVoice = ''.obs;
  final RxString lastError = ''.obs;
  final RxBool isEnabled = true.obs;

  // MQTT Command Queue
  final RxList<Map<String, dynamic>> commandQueue =
      <Map<String, dynamic>>[].obs;
  final RxBool isProcessingQueue = false.obs;

  // TTS Engine Info
  final RxString engineName = ''.obs;
  final RxBool isAndroid = false.obs;
  final RxBool isIOS = false.obs;
  final RxBool isWeb = false.obs;
  final RxBool isDesktop = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _detectPlatform();
    await _initializeTts();
  }

  @override
  void onClose() {
    _flutterTts?.stop();
    super.onClose();
  }

  void _detectPlatform() {
    isAndroid.value = Platform.isAndroid;
    isIOS.value = Platform.isIOS;
    isWeb.value = kIsWeb;
    isDesktop.value =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  Future<void> _initializeTts() async {
    try {
      _flutterTts = FlutterTts();

      if (_flutterTts != null) {
        // Set up event handlers
        _setupEventHandlers();

        // Initialize default settings
        await _setDefaultSettings();

        // Get available languages and voices
        await _loadAvailableLanguages();
        await _loadAvailableVoices();

        // Get engine information
        await _getEngineInfo();

        isInitialized.value = true;
        print('TtsService: Initialized successfully');
      }
    } catch (e) {
      lastError.value = 'Initialization failed: $e';
      print('TtsService: Initialization error: $e');
    }
  }

  void _setupEventHandlers() {
    _flutterTts?.setStartHandler(() {
      isSpeaking.value = true;
      isPaused.value = false;
      print('TtsService: Speech started');
    });

    _flutterTts?.setCompletionHandler(() {
      isSpeaking.value = false;
      isPaused.value = false;
      print('TtsService: Speech completed');
      _processNextInQueue();
    });

    _flutterTts?.setPauseHandler(() {
      isPaused.value = true;
      print('TtsService: Speech paused');
    });

    _flutterTts?.setContinueHandler(() {
      isPaused.value = false;
      print('TtsService: Speech continued');
    });

    _flutterTts?.setCancelHandler(() {
      isSpeaking.value = false;
      isPaused.value = false;
      print('TtsService: Speech cancelled');
      _processNextInQueue();
    });

    _flutterTts?.setErrorHandler((msg) {
      lastError.value = 'TTS Error: $msg';
      isSpeaking.value = false;
      isPaused.value = false;
      print('TtsService: Error occurred: $msg');
      _processNextInQueue();
    });

    // Platform specific handlers
    if (isAndroid.value || isIOS.value) {
      _flutterTts?.setProgressHandler(
          (String text, int startOffset, int endOffset, String word) {
        // Handle speech progress if needed
      });
    }
  }

  Future<void> _setDefaultSettings() async {
    await setVolume(volume.value);
    await setSpeechRate(speechRate.value);
    await setPitch(pitch.value);
    await setLanguage(currentLanguage.value);
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      final languages = await _flutterTts?.getLanguages;
      if (languages != null) {
        availableLanguages.value = List<String>.from(languages);
        print('TtsService: Loaded ${availableLanguages.length} languages');
      }
    } catch (e) {
      print('TtsService: Error loading languages: $e');
    }
  }

  Future<void> _loadAvailableVoices() async {
    try {
      final voices = await _flutterTts?.getVoices;
      if (voices != null) {
        availableVoices.value =
            voices.map((voice) => voice['name'] as String).toList();
        print('TtsService: Loaded ${availableVoices.length} voices');
      }
    } catch (e) {
      print('TtsService: Error loading voices: $e');
    }
  }

  Future<void> _getEngineInfo() async {
    try {
      if (isAndroid.value) {
        final engines = await _flutterTts?.getEngines;
        if (engines != null && engines.isNotEmpty) {
          engineName.value = engines.first;
        }
      }
    } catch (e) {
      print('TtsService: Error getting engine info: $e');
    }
  }

  // Public API Methods

  /// Main speak method with full configuration support
  Future<bool> speak(
    String text, {
    String? language,
    String? voice,
    double? volume,
    double? speechRate,
    double? pitch,
    bool queue = false,
  }) async {
    if (!isInitialized.value || !isEnabled.value) {
      print('TtsService: Not initialized or disabled');
      return false;
    }

    if (text.trim().isEmpty) {
      print('TtsService: Empty text provided');
      return false;
    }

    final command = {
      'action': 'speak',
      'text': text,
      'language': language,
      'voice': voice,
      'volume': volume,
      'speechRate': speechRate,
      'pitch': pitch,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (queue || isSpeaking.value) {
      commandQueue.add(command);
      print('TtsService: Added to queue. Queue size: ${commandQueue.length}');
      return true;
    }

    return await _executeSpeakCommand(command);
  }

  Future<bool> _executeSpeakCommand(Map<String, dynamic> command) async {
    try {
      isProcessingQueue.value = true;

      // Apply temporary settings if provided
      if (command['language'] != null) {
        await _flutterTts?.setLanguage(command['language']);
      }
      if (command['voice'] != null) {
        await _flutterTts?.setVoice({
          'name': command['voice'],
          'locale': command['language'] ?? currentLanguage.value
        });
      }
      if (command['volume'] != null) {
        await _flutterTts?.setVolume(command['volume']);
      }
      if (command['speechRate'] != null) {
        await _flutterTts?.setSpeechRate(command['speechRate']);
      }
      if (command['pitch'] != null) {
        await _flutterTts?.setPitch(command['pitch']);
      }

      // Speak the text
      final result = await _flutterTts?.speak(command['text']);

      // Restore default settings
      await _setDefaultSettings();

      isProcessingQueue.value = false;
      return result == 1;
    } catch (e) {
      lastError.value = 'Speech execution failed: $e';
      print('TtsService: Execution error: $e');
      isProcessingQueue.value = false;
      return false;
    }
  }

  /// Stop current speech
  Future<bool> stop() async {
    if (!isInitialized.value) return false;

    try {
      final result = await _flutterTts?.stop();
      clearQueue();
      return result == 1;
    } catch (e) {
      lastError.value = 'Stop failed: $e';
      return false;
    }
  }

  /// Pause current speech
  Future<bool> pause() async {
    if (!isInitialized.value || !isSpeaking.value) return false;

    try {
      final result = await _flutterTts?.pause();
      return result == 1;
    } catch (e) {
      lastError.value = 'Pause failed: $e';
      return false;
    }
  }

  /// Resume paused speech
  Future<bool> resume() async {
    if (!isInitialized.value || !isPaused.value) return false;

    try {
      // Note: Not all platforms support resume
      if (isAndroid.value || isIOS.value) {
        // For mobile platforms, we might need to re-speak from where we paused
        // This is a limitation of the TTS engines
        return await _flutterTts?.speak('') == 1;
      }
      return false;
    } catch (e) {
      lastError.value = 'Resume failed: $e';
      return false;
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<bool> setVolume(double vol) async {
    if (!isInitialized.value) return false;

    try {
      final clampedVolume = vol.clamp(0.0, 1.0);
      final result = await _flutterTts?.setVolume(clampedVolume);
      if (result == 1) {
        volume.value = clampedVolume;
        return true;
      }
      return false;
    } catch (e) {
      lastError.value = 'Set volume failed: $e';
      return false;
    }
  }

  /// Set speech rate (0.0 to 1.0, where 0.5 is normal)
  Future<bool> setSpeechRate(double rate) async {
    if (!isInitialized.value) return false;

    try {
      final clampedRate = rate.clamp(0.0, 1.0);
      final result = await _flutterTts?.setSpeechRate(clampedRate);
      if (result == 1) {
        speechRate.value = clampedRate;
        return true;
      }
      return false;
    } catch (e) {
      lastError.value = 'Set speech rate failed: $e';
      return false;
    }
  }

  /// Set pitch (0.5 to 2.0, where 1.0 is normal)
  Future<bool> setPitch(double p) async {
    if (!isInitialized.value) return false;

    try {
      final clampedPitch = p.clamp(0.5, 2.0);
      final result = await _flutterTts?.setPitch(clampedPitch);
      if (result == 1) {
        pitch.value = clampedPitch;
        return true;
      }
      return false;
    } catch (e) {
      lastError.value = 'Set pitch failed: $e';
      return false;
    }
  }

  /// Set language
  Future<bool> setLanguage(String lang) async {
    if (!isInitialized.value) return false;

    try {
      final result = await _flutterTts?.setLanguage(lang);
      if (result == 1) {
        currentLanguage.value = lang;
        await _loadAvailableVoices(); // Reload voices for new language
        return true;
      }
      return false;
    } catch (e) {
      lastError.value = 'Set language failed: $e';
      return false;
    }
  }

  /// Set voice
  Future<bool> setVoice(String voiceName) async {
    if (!isInitialized.value) return false;

    try {
      final result = await _flutterTts
          ?.setVoice({'name': voiceName, 'locale': currentLanguage.value});
      if (result == 1) {
        currentVoice.value = voiceName;
        return true;
      }
      return false;
    } catch (e) {
      lastError.value = 'Set voice failed: $e';
      return false;
    }
  }

  /// Clear the command queue
  void clearQueue() {
    commandQueue.clear();
    print('TtsService: Queue cleared');
  }

  /// Process next command in queue
  void _processNextInQueue() {
    if (commandQueue.isNotEmpty && !isProcessingQueue.value) {
      final nextCommand = commandQueue.removeAt(0);
      print(
          'TtsService: Processing next in queue. Remaining: ${commandQueue.length}');
      _executeSpeakCommand(nextCommand);
    }
  }

  /// Enable/disable TTS
  void setEnabled(bool enabled) {
    isEnabled.value = enabled;
    if (!enabled) {
      stop();
    }
    print('TtsService: ${enabled ? 'Enabled' : 'Disabled'}');
  }

  /// Get current status as a map
  Map<String, dynamic> getStatus() {
    return {
      'initialized': isInitialized.value,
      'speaking': isSpeaking.value,
      'paused': isPaused.value,
      'enabled': isEnabled.value,
      'volume': volume.value,
      'speechRate': speechRate.value,
      'pitch': pitch.value,
      'language': currentLanguage.value,
      'voice': currentVoice.value,
      'queueSize': commandQueue.length,
      'lastError': lastError.value,
      'platform': {
        'android': isAndroid.value,
        'ios': isIOS.value,
        'web': isWeb.value,
        'desktop': isDesktop.value,
      },
      'engine': engineName.value,
    };
  }

  /// Handle MQTT TTS commands
  Future<Map<String, dynamic>> handleMqttCommand(
      Map<String, dynamic> command) async {
    try {
      final action = command['action'] ?? command['command'] ?? 'speak';

      switch (action.toString().toLowerCase()) {
        case 'speak':
        case 'say':
          final text = command['text'] ?? command['message'] ?? '';
          final success = await speak(
            text,
            language: command['language'],
            voice: command['voice'],
            volume: command['volume']?.toDouble(),
            speechRate: command['speechRate']?.toDouble() ??
                command['rate']?.toDouble(),
            pitch: command['pitch']?.toDouble(),
            queue: command['queue'] == true,
          );
          return {'success': success, 'action': 'speak', 'text': text};

        case 'stop':
          final success = await stop();
          return {'success': success, 'action': 'stop'};

        case 'pause':
          final success = await pause();
          return {'success': success, 'action': 'pause'};

        case 'resume':
          final success = await resume();
          return {'success': success, 'action': 'resume'};

        case 'setvolume':
        case 'volume':
          final vol = (command['volume'] ?? command['value'] ?? volume.value)
              .toDouble();
          final success = await setVolume(vol);
          return {'success': success, 'action': 'setVolume', 'volume': vol};

        case 'setrate':
        case 'rate':
        case 'speed':
          final rate = (command['rate'] ??
                  command['speechRate'] ??
                  command['value'] ??
                  speechRate.value)
              .toDouble();
          final success = await setSpeechRate(rate);
          return {'success': success, 'action': 'setRate', 'rate': rate};

        case 'setpitch':
        case 'pitch':
          final p =
              (command['pitch'] ?? command['value'] ?? pitch.value).toDouble();
          final success = await setPitch(p);
          return {'success': success, 'action': 'setPitch', 'pitch': p};

        case 'setlanguage':
        case 'language':
          final lang =
              command['language'] ?? command['value'] ?? currentLanguage.value;
          final success = await setLanguage(lang);
          return {
            'success': success,
            'action': 'setLanguage',
            'language': lang
          };

        case 'setvoice':
        case 'voice':
          final voice =
              command['voice'] ?? command['value'] ?? currentVoice.value;
          final success = await setVoice(voice);
          return {'success': success, 'action': 'setVoice', 'voice': voice};

        case 'enable':
          setEnabled(true);
          return {'success': true, 'action': 'enable', 'enabled': true};

        case 'disable':
          setEnabled(false);
          return {'success': true, 'action': 'disable', 'enabled': false};

        case 'status':
        case 'getstatus':
          return {'success': true, 'action': 'status', 'status': getStatus()};

        case 'getlanguages':
          return {
            'success': true,
            'action': 'getLanguages',
            'languages': availableLanguages.toList()
          };

        case 'getvoices':
          return {
            'success': true,
            'action': 'getVoices',
            'voices': availableVoices.toList()
          };

        case 'clearqueue':
          clearQueue();
          return {'success': true, 'action': 'clearQueue'};

        default:
          return {'success': false, 'error': 'Unknown TTS command: $action'};
      }
    } catch (e) {
      return {'success': false, 'error': 'TTS command execution failed: $e'};
    }
  }

  /// Handle batch MQTT TTS commands with optimized processing
  Future<List<Map<String, dynamic>>> handleBatchMqttCommands(
      List<Map<String, dynamic>> commands) async {
    final results = <Map<String, dynamic>>[];

    try {
      print('🔊 [TTS] Processing batch of ${commands.length} TTS commands');

      for (int i = 0; i < commands.length; i++) {
        final command = commands[i];
        try {
          final result = await handleMqttCommand(command);
          results.add({
            ...result,
            'batchIndex': i,
            'commandId': command['id'] ?? 'batch_$i'
          });

          // Add small delay between commands to prevent audio overlap
          if (i < commands.length - 1) {
            final action = command['action'] ?? command['command'] ?? 'speak';
            if (action.toString().toLowerCase() == 'speak' ||
                action.toString().toLowerCase() == 'say') {
              await Future.delayed(const Duration(milliseconds: 100));
            }
          }
        } catch (e) {
          results.add({
            'success': false,
            'error': 'Batch command $i failed: $e',
            'batchIndex': i,
            'commandId': command['id'] ?? 'batch_$i'
          });
        }
      }

      print('🔊 [TTS] Batch processing complete: ${results.length} results');
      return results;
    } catch (e) {
      print('❌ [TTS] Batch processing error: $e');
      return [{
        'success': false,
        'error': 'Batch processing failed: $e',
        'totalCommands': commands.length
      }];
    }
  }
}
