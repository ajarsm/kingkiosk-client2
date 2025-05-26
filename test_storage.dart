import 'package:get_storage/get_storage.dart';
import 'dart:io';

Future<void> main() async {
  print('🔧 Testing GetStorage on Windows...');
  
  try {
    // Initialize GetStorage
    await GetStorage.init();
    await GetStorage.init('kingkiosk_storage');
    
    // Test default storage
    final defaultBox = GetStorage();
    print('📦 Testing default storage...');
    
    defaultBox.write('test_key', 'test_value_default');
    final defaultValue = defaultBox.read('test_key');
    print('   Default storage test: $defaultValue');
    
    // Test named storage
    final namedBox = GetStorage('kingkiosk_storage');
    print('📦 Testing named storage...');
    
    namedBox.write('test_key', 'test_value_named');
    final namedValue = namedBox.read('test_key');
    print('   Named storage test: $namedValue');
    
    // Test MQTT settings
    namedBox.write('mqttEnabled', true);
    namedBox.write('mqttBrokerUrl', 'test.broker.com');
    namedBox.write('kioskStartUrl', 'https://test.example.com');
    
    print('💾 Saved test settings...');
    
    // Read back settings
    final mqttEnabled = namedBox.read('mqttEnabled');
    final mqttBrokerUrl = namedBox.read('mqttBrokerUrl');
    final kioskStartUrl = namedBox.read('kioskStartUrl');
    
    print('📖 Read settings:');
    print('   MQTT Enabled: $mqttEnabled');
    print('   MQTT Broker: $mqttBrokerUrl');
    print('   Kiosk URL: $kioskStartUrl');
    
    // Check all keys
    final keys = namedBox.getKeys();
    print('🔑 All keys in named storage: $keys');
    
    // Check storage file location (if accessible)
    if (Platform.isWindows) {
      final appDataDir = Platform.environment['LOCALAPPDATA'];
      if (appDataDir != null) {
        print('📁 Checking Windows storage location...');
        final storageDir = Directory('$appDataDir\\flutter_kingkiosk');
        print('   Storage directory exists: ${await storageDir.exists()}');
        
        // List files in the storage directory
        if (await storageDir.exists()) {
          final files = await storageDir.list().toList();
          print('   Files in storage dir: ${files.map((f) => f.path).toList()}');
        }
      }
    }
    
    print('✅ Storage test completed successfully');
    
  } catch (e) {
    print('❌ Storage test failed: $e');
    print('   Stack trace: ${StackTrace.current}');
  }
}
