import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crypto/crypto.dart';

// Platform-specific imports
import 'package:path_provider/path_provider.dart' if (dart.library.html) '';
import 'package:universal_html/html.dart' as universal_html;

// Universal imports for File and Directory access on non-web platforms
import 'dart:io' show File, Directory if (dart.library.html) '';

/// Cross-platform unified storage service
/// - Desktop/Mobile: File-based storage with JSON files
/// - Web: HTML5 localStorage with JSON serialization
/// - Encryption: Applied only to sensitive data across all platforms
class StorageService extends GetxService {
  File? _regularFile;
  File? _secureFile;
  late final String _encryptionKey;

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

        // Initialize storage files
        _regularFile = File('${storageDir.path}/regular.json');
        _secureFile = File('${storageDir.path}/secure.json');

        // Load existing data
        await _loadData();
        print('✅ File-based storage initialized (Desktop/Mobile)');
      } else {
        // Web: Use localStorage for persistent storage
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

  @override
  void onClose() {
    _saveData();
    super.onClose();
  }
}
