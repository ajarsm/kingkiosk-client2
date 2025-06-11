import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'lib/app/services/storage_service.dart';

/// Test script to verify MQTT credentials migration to secure storage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('🧪 Testing MQTT credentials migration to secure storage...');
    
    // Initialize GetStorage
    await GetStorage.init();
    
    // Create regular storage and add some test MQTT credentials
    final regularBox = GetStorage();
    regularBox.write('mqttUsername', 'test_user');
    regularBox.write('mqttPassword', 'test_password_123');
    
    print('✅ Added test credentials to regular storage');
    print('   Username: ${regularBox.read('mqttUsername')}');
    print('   Password: ${regularBox.read('mqttPassword')}');
    
    // Initialize the storage service (which should migrate credentials)
    final storageService = StorageService();
    await storageService.init();
    
    print('✅ Storage service initialized');
    
    // Check if credentials were migrated to secure storage
    if (storageService.secureStorage != null) {
      final username = await storageService.secureStorage!.getMqttUsername();
      final password = await storageService.secureStorage!.getMqttPassword();
      
      print('✅ Credentials retrieved from secure storage:');
      print('   Username: ${username ?? "null"}');
      print('   Password: ${password?.isNotEmpty == true ? "[PROTECTED]" : "null"}');
      
      // Check if credentials were removed from regular storage
      final regularUsername = regularBox.read('mqttUsername');
      final regularPassword = regularBox.read('mqttPassword');
      
      print('📋 Regular storage after migration:');
      print('   Username: ${regularUsername ?? "null"}');
      print('   Password: ${regularPassword ?? "null"}');
      
      if (username == 'test_user' && password == 'test_password_123') {
        if (regularUsername == null && regularPassword == null) {
          print('🎉 Migration test PASSED - credentials moved to secure storage');
        } else {
          print('⚠️ Migration test PARTIAL - credentials copied but not removed from regular storage');
        }
      } else {
        print('❌ Migration test FAILED - credentials not found in secure storage');
      }
      
      // Test debug functionality
      await storageService.secureStorage!.debugSecureStorageStatus();
      
    } else {
      print('❌ Secure storage not available');
    }
    
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
  
  print('\n🏁 Test completed');
}
