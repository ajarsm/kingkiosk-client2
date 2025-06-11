import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crypto/crypto.dart';

// Platform-specific imports
import 'package:path_provider/path_provider.dart' if (dart.library.html) '';
import 'package:universal_html/html.dart' as universal_html;

// Universal imports for File and Directory access on non-web platforms
import 'dart:io' show File, Directory, pid, ProcessSignal, exit if (dart.library.html) '';

/// Cross-platform unified storage service
/// - Desktop/Mobile: File-based storage with JSON files
/// - Web: HTML5 localStorage with JSON serialization
/// - Encryption: Applied only to sensitive data across all platforms
class StorageService extends GetxService {
  File? _regularFile;
  File? _secureFile;
  File? _lockFile;
  late final String _encryptionKey;
  StreamSubscription? _sigintSubscription;
  StreamSubscription? _sigtermSubscription;

  Map<String, dynamic> _regularData = {};
  Map<String, String> _secureData = {};

  /// Initialize the storage service
  Future<StorageService> init() async {
    try {
      print('🔄 Initializing cross-platform storage service...');

      // Initialize encryption key
      _encryptionKey = _generateEncryptionKey();

      if (!kIsWeb) {
        // Desktop/Mobile: Use file-based storage
        final dir = await getApplicationDocumentsDirectory();
        final storageDir = Directory('${dir.path}/kingkiosk_storage');
        if (!await storageDir.exists()) {
          await storageDir.create(recursive: true);
        }

        // Check for application lock to prevent multiple instances
        await _acquireApplicationLock(storageDir);

        // Set up signal handling for graceful shutdown
        _setupSignalHandling();

        // Initialize storage files
        _regularFile = File('${storageDir.path}/regular.json');
        _secureFile = File('${storageDir.path}/secure.json');

        // Load existing data
        await _loadData();
        print('✅ File-based storage initialized (Desktop/Mobile)');
      } else {
        // Web: Use localStorage for persistent storage
        // Check for application lock to prevent multiple instances (Web)
        await _acquireWebApplicationLock();
        
        await _loadWebData();
        print('✅ localStorage initialized (Web)');
        print('ℹ️  Web storage uses HTML5 localStorage for persistence.');
      }

      print('✅ Cross-platform storage service ready');
      return this;
    } catch (e) {
      print('❌ Failed to initialize storage service: $e');
      rethrow;
    }
  }

  /// Load data from web localStorage
  Future<void> _loadWebData() async {
    if (!kIsWeb) return;

    try {
      // On web, use universal_html or direct localStorage access
      if (kIsWeb) {
        // Use dynamic import to access localStorage
        final storage = _getWebStorage();

        // Load regular data from localStorage
        final regularJson = storage?['kingkiosk_regular'];
        if (regularJson != null && regularJson.isNotEmpty) {
          _regularData = Map<String, dynamic>.from(jsonDecode(regularJson));
        } else {
          _regularData = {};
        }

        // Load secure data from localStorage
        final secureJson = storage?['kingkiosk_secure'];
        if (secureJson != null && secureJson.isNotEmpty) {
          _secureData = Map<String, String>.from(jsonDecode(secureJson));
        } else {
          _secureData = {};
        }
      }
    } catch (e) {
      print('⚠️ Failed to load web data: $e');
      _regularData = {};
      _secureData = {};
    }
  }

  /// Save data to web localStorage
  Future<void> _saveWebData() async {
    if (!kIsWeb) return;

    try {
      if (kIsWeb) {
        final storage = _getWebStorage();

        // Save regular data to localStorage
        storage?['kingkiosk_regular'] = jsonEncode(_regularData);

        // Save secure data to localStorage
        storage?['kingkiosk_secure'] = jsonEncode(_secureData);
      }
    } catch (e) {
      print('⚠️ Failed to save web data: $e');
    }
  }

  /// Get web storage (localStorage) - returns null on non-web platforms
  dynamic _getWebStorage() {
    if (!kIsWeb) return null;

    try {
      // Use universal_html to access localStorage on web
      if (kIsWeb) {
        return universal_html.window.localStorage;
      }
      return null;
    } catch (e) {
      print('⚠️ localStorage not available: $e');
      return null;
    }
  }

  /// Generate a simple encryption key
  String _generateEncryptionKey() {
    const deviceInfo = 'kingkiosk_app_cross_platform_v1';
    return sha256.convert(utf8.encode(deviceInfo)).toString().substring(0, 32);
  }

  /// Simple XOR encryption
  String _encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    final keyBytes = utf8.encode(_encryptionKey);
    final textBytes = utf8.encode(plainText);
    final encryptedBytes = <int>[];

    for (int i = 0; i < textBytes.length; i++) {
      final keyIndex = i % keyBytes.length;
      encryptedBytes.add(textBytes[i] ^ keyBytes[keyIndex]);
    }

    return base64.encode(encryptedBytes);
  }

  /// Simple XOR decryption
  String _decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';
    try {
      final encryptedBytes = base64.decode(encryptedText);
      final keyBytes = utf8.encode(_encryptionKey);
      final decryptedBytes = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        final keyIndex = i % keyBytes.length;
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[keyIndex]);
      }

      return utf8.decode(decryptedBytes);
    } catch (e) {
      print('⚠️ Decryption failed: $e');
      return '';
    }
  }

  /// Load data from files (Desktop/Mobile) or localStorage (Web)
  Future<void> _loadData() async {
    if (kIsWeb) {
      await _loadWebData();
      return;
    }

    try {
      // Load regular data
      if (_regularFile != null && await _regularFile!.exists()) {
        final content = await _regularFile!.readAsString();
        _regularData = Map<String, dynamic>.from(jsonDecode(content));
      }

      // Load secure data
      if (_secureFile != null && await _secureFile!.exists()) {
        final content = await _secureFile!.readAsString();
        _secureData = Map<String, String>.from(jsonDecode(content));
      }
    } catch (e) {
      print('⚠️ Failed to load data: $e');
      _regularData = {};
      _secureData = {};
    }
  }

  /// Save data to files (Desktop/Mobile) or localStorage (Web)
  Future<void> _saveData() async {
    if (kIsWeb) {
      await _saveWebData();
      return;
    }

    try {
      // Save regular data
      if (_regularFile != null) {
        print('💾 Saving regular data: ${_regularData.length} keys');
        await _regularFile!.writeAsString(jsonEncode(_regularData));
      }

      // Save secure data
      if (_secureFile != null) {
        print('🔐 Saving secure data: ${_secureData.length} keys');
        print('🔐 Secure data keys: ${_secureData.keys.toList()}');
        await _secureFile!.writeAsString(jsonEncode(_secureData));
      }
    } catch (e) {
      print('⚠️ Failed to save data: $e');
    }
  }

  // ============================================================================
  // PUBLIC API (GetStorage compatibility)
  // ============================================================================

  /// Read a value from regular storage
  T? read<T>(String key) {
    try {
      final value = _regularData[key];
      if (value == null) return null;
      if (value is T) return value;
      return value as T?;
    } catch (e) {
      print('⚠️ Failed to read key $key: $e');
      return null;
    }
  }

  /// Write a value to regular storage
  void write<T>(String key, T value) {
    try {
      _regularData[key] = value;
      _saveData(); // Save immediately for desktop/mobile
    } catch (e) {
      print('⚠️ Failed to write key $key: $e');
    }
  }

  /// Remove a key from regular storage
  void remove(String key) {
    try {
      _regularData.remove(key);
      _saveData();
    } catch (e) {
      print('⚠️ Failed to remove key $key: $e');
    }
  }

  /// Clear all regular storage
  Future<void> erase() async {
    try {
      _regularData.clear();
      await _saveData();
    } catch (e) {
      print('⚠️ Failed to clear storage: $e');
    }
  }

  /// Flush storage (compatibility method)
  Future<void> flush() async {
    await _saveData();
  }

  /// Listen to key changes (basic implementation)
  Stream<T?> listenKey<T>(String key) async* {
    T? lastValue = read<T>(key);
    yield lastValue;

    // Simple polling implementation
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      final currentValue = read<T>(key);
      if (currentValue != lastValue) {
        lastValue = currentValue;
        yield currentValue;
      }
    }
  }

  // ============================================================================
  // SECURE STORAGE METHODS (FlutterSecureStorage API compatibility)
  // ============================================================================

  /// Read a secure value from storage
  Future<T?> readSecure<T>(String key) async {
    try {
      print('🔓 Reading secure key: $key');
      final encryptedValue = _secureData[key];
      if (encryptedValue == null) {
        print('🔓 No encrypted value found for key: $key');
        return null;
      }

      final decryptedValue = _decrypt(encryptedValue);
      if (decryptedValue.isEmpty) {
        print('🔓 Decrypted value is empty for key: $key');
        return null;
      }

      print('🔓 Decrypted value length: ${decryptedValue.length}');

      if (T == String) return decryptedValue as T;

      try {
        return jsonDecode(decryptedValue) as T;
      } catch (e) {
        if (T == String) return decryptedValue as T;
        return null;
      }
    } catch (e) {
      print('⚠️ Failed to read secure key $key: $e');
      return null;
    }
  }

  /// Write a secure value to storage
  Future<void> writeSecure(String key, dynamic value) async {
    try {
      final stringValue = value is String ? value : jsonEncode(value);
      final encryptedValue = _encrypt(stringValue);

      print('🔐 Writing secure key: $key');
      print('🔐 Value length: ${stringValue.length}');
      print('🔐 Value empty: ${stringValue.isEmpty}');

      _secureData[key] = encryptedValue;
      await _saveData();
      
      print('✅ Secure data saved for key: $key');
    } catch (e) {
      print('⚠️ Failed to write secure key $key: $e');
    }
  }

  /// Delete a secure key from storage
  Future<void> deleteSecure(String key) async {
    try {
      _secureData.remove(key);
      await _saveData();
    } catch (e) {
      print('⚠️ Failed to delete secure key $key: $e');
    }
  }

  // ============================================================================
  // SPECIALIZED METHODS (Previous API compatibility)
  // ============================================================================

  /// Get MQTT credentials (secure)
  Future<Map<String, String>> getMqttCredentialsSecure() async {
    try {
      final broker = await readSecure<String>('secure_mqtt_broker') ?? '';
      final username = await readSecure<String>('secure_mqtt_username') ?? '';
      final password = await readSecure<String>('secure_mqtt_password') ?? '';

      return {
        'broker': broker,
        'username': username,
        'password': password,
      };
    } catch (e) {
      print('⚠️ Failed to get MQTT credentials: $e');
      return {'broker': '', 'username': '', 'password': ''};
    }
  }

  /// Save MQTT credentials (secure)
  Future<void> saveMqttCredentialsSecure(String broker, String username,
      [String? password]) async {
    try {
      await writeSecure('secure_mqtt_broker', broker);
      await writeSecure('secure_mqtt_username', username);
      if (password != null) {
        await writeSecure('secure_mqtt_password', password);
      }
    } catch (e) {
      print('⚠️ Failed to save MQTT credentials: $e');
    }
  }

  /// Get settings PIN (secure)
  Future<String?> getSettingsPin() async {
    return await readSecure<String>('secure_settings_pin');
  }

  /// Save settings PIN (secure)
  Future<void> saveSettingsPin(String pin) async {
    await writeSecure('secure_settings_pin', pin);
  }

  /// Get MQTT username (secure)
  Future<String?> getMqttUsername() async {
    return await readSecure<String>('secure_mqtt_username');
  }

  /// Get MQTT password (secure)
  Future<String?> getMqttPassword() async {
    return await readSecure<String>('secure_mqtt_password');
  }

  /// Save MQTT username (secure)
  Future<void> saveMqttUsername(String username) async {
    await writeSecure('secure_mqtt_username', username);
  }

  /// Save MQTT password (secure)
  Future<void> saveMqttPassword(String password) async {
    await writeSecure('secure_mqtt_password', password);
  }

  /// Debug secure storage status
  Future<void> debugSecureStorageStatus() async {
    await debugStorageStatus();
  }

  /// Debug storage status
  Future<void> debugStorageStatus() async {
    try {
      print('📊 Cross-Platform Storage Statistics:');
      print(
          '   Platform: ${kIsWeb ? "Web (localStorage)" : "Desktop/Mobile (Files)"}');
      print('   Regular entries: ${_regularData.length}');
      print('   Secure entries: ${_secureData.length}');

      if (!kIsWeb && _regularFile != null && _secureFile != null) {
        print('   Regular file: ${_regularFile!.path}');
        print('   Secure file: ${_secureFile!.path}');
      } else if (kIsWeb) {
        print('   Storage: HTML5 localStorage');
        print('   Keys: kingkiosk_regular, kingkiosk_secure');
      }
    } catch (e) {
      print('⚠️ Failed to debug storage status: $e');
    }
  }

  /// Compatibility property for services that check this
  StorageService? get secureStorage => this;

  // ============================================================================
  // APPLICATION LOCK METHODS
  // ============================================================================

  /// Manually release application lock (useful for graceful shutdown)
  Future<void> releaseApplicationLock() async {
    if (kIsWeb) {
      await _releaseWebApplicationLock();
    } else {
      await _releaseApplicationLock();
    }
  }

  /// Acquire application lock to prevent multiple instances
  Future<void> _acquireApplicationLock(Directory storageDir) async {
    _lockFile = File('${storageDir.path}/app.lock');
    
    // Check if lock file exists and is still valid
    if (await _lockFile!.exists()) {
      try {
        final lockContent = await _lockFile!.readAsString();
        final lockData = jsonDecode(lockContent);
        final lockTime = DateTime.parse(lockData['timestamp']);
        final lockPid = lockData['pid'];
        
        // Check if lock is stale (older than 5 minutes) or from same process
        final now = DateTime.now();
        final lockAge = now.difference(lockTime);
        
        if (lockAge.inMinutes > 5) {
          print('⚠️ Stale application lock found (${lockAge.inMinutes} minutes old), removing...');
          await _lockFile!.delete();
        } else if (lockPid == getCurrentProcessId()) {
          print('⚠️ Lock file belongs to current process, removing...');
          await _lockFile!.delete();
        } else {
          print('❌ Another KingKiosk instance is running (PID: $lockPid, started: ${lockTime.toLocal()})');
          print('❌ Please close the other instance before starting a new one');
          print('❌ If you believe this is an error, delete the lock file: ${_lockFile!.path}');
          throw Exception('Another instance of KingKiosk is already running');
        }
      } catch (e) {
        if (e.toString().contains('Another instance')) {
          rethrow;
        }
        // Lock file is corrupted, remove it
        print('⚠️ Corrupted lock file found, removing...');
        await _lockFile!.delete();
      }
    }
    
    // Create new lock file
    final lockData = {
      'timestamp': DateTime.now().toIso8601String(),
      'pid': getCurrentProcessId(),
      'app': 'KingKiosk',
      'version': '1.0.0',
      'platform': kIsWeb ? 'web' : 'desktop',
    };
    
    await _lockFile!.writeAsString(jsonEncode(lockData));
    print('🔒 Application lock acquired (PID: ${lockData['pid']})');
  }

  /// Get current process ID (platform-specific)
  int getCurrentProcessId() {
    try {
      if (!kIsWeb) {
        return pid;
      }
    } catch (e) {
      // Fallback for platforms that don't support pid
    }
    return DateTime.now().millisecondsSinceEpoch % 100000; // Fallback ID
  }

  /// Release application lock
  Future<void> _releaseApplicationLock() async {
    if (_lockFile != null && await _lockFile!.exists()) {
      try {
        await _lockFile!.delete();
        print('🔓 Application lock released');
      } catch (e) {
        print('⚠️ Failed to release application lock: $e');
      }
    }
  }

  /// Acquire application lock for Web platform using localStorage
  Future<void> _acquireWebApplicationLock() async {
    const lockKey = 'kingkiosk_app_lock';
    
    try {
      final storage = _getWebStorage();
      if (storage == null) {
        print('⚠️ localStorage not available, skipping Web lock mechanism');
        return;
      }

      // Check if lock exists
      final existingLockData = storage[lockKey];
      if (existingLockData != null) {
        try {
          final lock = jsonDecode(existingLockData);
          final lockTime = DateTime.parse(lock['timestamp']);
          final tabId = lock['tab_id'];
          
          // Check if lock is stale (older than 5 minutes)
          final now = DateTime.now();
          final lockAge = now.difference(lockTime);
          
          if (lockAge.inMinutes > 5) {
            print('⚠️ Stale Web application lock found (${lockAge.inMinutes} minutes old), removing...');
            storage.remove(lockKey);
          } else {
            print('❌ Another KingKiosk Web instance is running (Tab: $tabId, started: ${lockTime.toLocal()})');
            print('❌ Please close the other browser tab before opening a new one');
            print('❌ If you believe this is an error, clear your browser\'s localStorage for this site');
            throw Exception('Another instance of KingKiosk is already running in another tab');
          }
        } catch (e) {
          if (e.toString().contains('Another instance')) {
            rethrow;
          }
          // Lock data is corrupted, remove it
          print('⚠️ Corrupted Web lock found, removing...');
          storage.remove(lockKey);
        }
      }
      
      // Create new lock
      final tabId = _generateWebTabId();
      final newLockData = {
        'timestamp': DateTime.now().toIso8601String(),
        'tab_id': tabId,
        'app': 'KingKiosk',
        'version': '1.0.0',
        'platform': 'web',
      };
      
      storage[lockKey] = jsonEncode(newLockData);
      print('🔒 Web application lock acquired (Tab: $tabId)');
      
      // Set up periodic lock refresh to keep it alive
      _setupWebLockRefresh(lockKey, tabId);
    } catch (e) {
      if (e.toString().contains('Another instance')) {
        rethrow;
      }
      print('⚠️ Failed to acquire Web application lock: $e');
      // Don't throw here, allow app to continue for Web compatibility
    }
  }

  /// Generate a unique tab identifier for Web
  String _generateWebTabId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = (now * 0.123456789).floor() % 10000;
    return 'tab_${now}_$random';
  }

  /// Set up periodic refresh of Web lock
  void _setupWebLockRefresh(String lockKey, String tabId) {
    // Refresh lock every 30 seconds to keep it alive
    Timer.periodic(const Duration(seconds: 30), (timer) {
      try {
        final storage = _getWebStorage();
        if (storage == null) {
          timer.cancel();
          return;
        }
        
        final currentLock = storage[lockKey];
        if (currentLock != null) {
          final lock = jsonDecode(currentLock);
          if (lock['tab_id'] == tabId) {
            // This is our lock, refresh it
            lock['timestamp'] = DateTime.now().toIso8601String();
            storage[lockKey] = jsonEncode(lock);
          } else {
            // Someone else has the lock, stop refreshing
            timer.cancel();
          }
        }
      } catch (e) {
        print('⚠️ Error refreshing Web lock: $e');
        timer.cancel();
      }
    });
  }

  /// Release Web application lock
  Future<void> _releaseWebApplicationLock() async {
    const lockKey = 'kingkiosk_app_lock';
    
    try {
      final storage = _getWebStorage();
      if (storage != null) {
        storage.remove(lockKey);
        print('🔓 Web application lock released');
      }
    } catch (e) {
      print('⚠️ Failed to release Web application lock: $e');
    }
  }

  /// Set up signal handling for graceful shutdown (non-web platforms)
  void _setupSignalHandling() {
    if (kIsWeb) return;

    try {
      // Handle SIGINT (Ctrl+C)
      _sigintSubscription = ProcessSignal.sigint.watch().listen((signal) {
        print('⚠️ Received SIGINT signal, performing graceful shutdown...');
        _handleShutdownSignal();
      });

      // Handle SIGTERM (termination request)
      _sigtermSubscription = ProcessSignal.sigterm.watch().listen((signal) {
        print('⚠️ Received SIGTERM signal, performing graceful shutdown...');
        _handleShutdownSignal();
      });

      print('🔧 Signal handlers set up for graceful shutdown');
    } catch (e) {
      print('⚠️ Failed to set up signal handlers: $e');
    }
  }

  /// Handle shutdown signals by releasing the lock and exiting
  void _handleShutdownSignal() async {
    try {
      print('🔄 Releasing application lock due to signal...');
      await releaseApplicationLock();
      print('✅ Application lock released successfully');
    } catch (e) {
      print('❌ Error releasing lock during shutdown: $e');
    } finally {
      exit(0);
    }
  }

  @override
  void onClose() {
    // Cancel signal subscriptions
    _sigintSubscription?.cancel();
    _sigtermSubscription?.cancel();

    // Release lock in background - don't await to avoid blocking
    if (kIsWeb) {
      _releaseWebApplicationLock();
    } else {
      _releaseApplicationLock();
    }
    _saveData();
    super.onClose();
  }
}
