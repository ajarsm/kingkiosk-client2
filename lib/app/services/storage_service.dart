import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  late final GetStorage _box;
    Future<StorageService> init() async {
    try {
      // Use default storage container for simplicity and better Windows compatibility
      _box = GetStorage();
      
      // Wait for storage to be fully initialized
      await _box.initStorage;
      
      // Test storage functionality
      await _testStorageOperations();
      
      print('✅ Storage service initialized successfully with default container');
      return this;
    } catch (e) {
      print('❌ Failed to initialize storage service: $e');
      rethrow;
    }  }
  
  Future<void> _testStorageOperations() async {
    try {
      const testKey = 'storage_test_key';
      const testValue = 'storage_test_value';
      
      // Test write
      _box.write(testKey, testValue);
      
      // Test read
      final readValue = _box.read(testKey);
      
      if (readValue == testValue) {
        print('✅ Storage test passed');
        // Clean up test key
        _box.remove(testKey);
      } else {
        print('❌ Storage test failed: expected $testValue, got $readValue');
      }
    } catch (e) {
      print('❌ Storage test error: $e');
    }
  }

  // Store any type of data
  void write(String key, dynamic value) {
    try {
      _box.write(key, value);
      print('✅ Storage write successful: $key = $value');
    } catch (e) {
      print('❌ Storage write failed for $key: $e');
    }
  }

  // Read data
  T? read<T>(String key) {
    try {
      final value = _box.read<T>(key);
      print('📖 Storage read: $key = $value');
      return value;
    } catch (e) {
      print('❌ Storage read failed for $key: $e');
      return null;
    }
  }

  // Remove a single key
  void remove(String key) {
    _box.remove(key);
  }

  // Clear all storage
  Future<void> erase() async {
    await _box.erase();
  }

  // Listen to changes on a specific key
  void listenKey(String key, Function(dynamic) callback) {
    _box.listenKey(key, callback);
  }

  // Debug method to check storage status
  void debugStorageStatus() {
    try {
      print('🔍 Storage Debug Info:');
      print('   - GetStorage instance: $_box');
      print('   - Has data: ${_box.hasData('test')}');
      
      // Test write/read
      _box.write('debug_test', 'test_value');
      final testValue = _box.read('debug_test');
      print('   - Test write/read: $testValue');
      
      // Show all keys
      final keys = _box.getKeys();
      print('   - All keys: $keys');
      
      // Show values for all keys
      for (final key in keys) {
        final value = _box.read(key);
        print('   - $key: $value');
      }
    } catch (e) {
      print('❌ Storage debug failed: $e');
    }
  }
}