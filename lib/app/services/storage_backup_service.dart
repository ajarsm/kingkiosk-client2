import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

/// Enhanced storage backup and recovery service
/// Provides automatic backups, corruption detection, and recovery mechanisms
class StorageBackupService extends GetxService {
  static const String _backupFolder = 'backups';
  static const int _maxBackups = 10;

  Directory? _backupDir;
  Timer? _autoBackupTimer;

  /// Initialize the backup service
  Future<StorageBackupService> init() async {
    try {
      print('🔄 Initializing storage backup service...');

      final docDir = await getApplicationDocumentsDirectory();
      _backupDir = Directory('${docDir.path}/kingkiosk_storage/$_backupFolder');

      if (!await _backupDir!.exists()) {
        await _backupDir!.create(recursive: true);
      }

      // Schedule automatic backups every 30 minutes
      _scheduleAutoBackup();

      // Verify current storage integrity
      await _verifyStorageIntegrity();

      print('✅ Storage backup service ready');
      return this;
    } catch (e) {
      print('❌ Failed to initialize backup service: $e');
      rethrow;
    }
  }

  /// Create a complete backup of all storage data
  Future<String?> createBackup({String? description}) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = 'backup_$timestamp.json';
      final backupFile = File('${_backupDir!.path}/$backupFileName');

      // Get current storage service
      final storageService = Get.find<StorageService>();

      // Create comprehensive backup data
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'description': description ?? 'Automatic backup',
        'version': '1.0',
        'data': {
          'regular': await _getAllRegularData(storageService),
          'secure': await _getAllSecureDataKeys(), // Only keys for security
        },
        'metadata': {
          'platform': Platform.operatingSystem,
          'app_version': '1.0.0', // You can get this from package_info
          'backup_count': await _getBackupCount(),
        }
      };

      await backupFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(backupData));

      // Clean up old backups
      await _cleanupOldBackups();

      print('✅ Backup created: $backupFileName');
      print('📁 Backup location: ${backupFile.path}');

      return backupFile.path;
    } catch (e) {
      print('❌ Failed to create backup: $e');
      return null;
    }
  }

  /// Restore from a backup file
  Future<bool> restoreFromBackup(String backupFilePath,
      {bool preview = false}) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        print('❌ Backup file not found: $backupFilePath');
        return false;
      }

      final backupContent = await backupFile.readAsString();
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>;

      // Validate backup format
      if (!_validateBackupFormat(backupData)) {
        print('❌ Invalid backup format');
        return false;
      }

      if (preview) {
        _printBackupInfo(backupData);
        return true;
      }

      // Create safety backup before restore
      await createBackup(description: 'Pre-restore safety backup');

      // Get storage service
      final storageService = Get.find<StorageService>();

      // Restore regular data
      final regularData = backupData['data']['regular'] as Map<String, dynamic>;
      await _restoreRegularData(storageService, regularData);

      // Note: Secure data restoration would require user confirmation
      // and proper security measures in a production environment

      print('✅ Backup restored successfully');
      print('📅 Backup date: ${backupData['timestamp']}');
      print('📝 Description: ${backupData['description']}');

      return true;
    } catch (e) {
      print('❌ Failed to restore backup: $e');
      return false;
    }
  }

  /// List all available backups
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final backups = <Map<String, dynamic>>[];

      if (!await _backupDir!.exists()) {
        return backups;
      }

      final files = _backupDir!
          .listSync()
          .where((file) => file is File && file.path.endsWith('.json'))
          .cast<File>()
          .toList();

      // Sort by modification date (newest first)
      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      for (final file in files) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;

          backups.add({
            'file_path': file.path,
            'file_name': file.path.split('/').last,
            'timestamp': data['timestamp'],
            'description': data['description'],
            'size': await file.length(),
            'readable_size': _formatFileSize(await file.length()),
            'created': file.statSync().modified.toIso8601String(),
          });
        } catch (e) {
          print('⚠️ Skipping corrupted backup file: ${file.path}');
        }
      }

      return backups;
    } catch (e) {
      print('❌ Failed to list backups: $e');
      return [];
    }
  }

  /// Export configuration to external file
  Future<String?> exportConfiguration(String exportPath) async {
    try {
      final backupPath =
          await createBackup(description: 'Configuration export');
      if (backupPath == null) return null;

      await File(backupPath).copy(exportPath);

      print('✅ Configuration exported to: $exportPath');
      return exportPath;
    } catch (e) {
      print('❌ Failed to export configuration: $e');
      return null;
    }
  }

  /// Import configuration from external file
  Future<bool> importConfiguration(String importPath) async {
    try {
      return await restoreFromBackup(importPath);
    } catch (e) {
      print('❌ Failed to import configuration: $e');
      return false;
    }
  }

  /// Verify storage integrity and attempt auto-recovery
  Future<bool> _verifyStorageIntegrity() async {
    try {
      final storageService = Get.find<StorageService>();

      // Test basic read/write operations
      const testKey = '__integrity_test__';
      final testValue =
          'integrity_check_${DateTime.now().millisecondsSinceEpoch}';

      storageService.write(testKey, testValue);
      final readValue = storageService.read<String>(testKey);
      storageService.remove(testKey);

      if (readValue != testValue) {
        print('⚠️ Storage integrity check failed');
        return await _attemptAutoRecovery();
      }

      print('✅ Storage integrity verified');
      return true;
    } catch (e) {
      print('❌ Storage integrity check error: $e');
      return await _attemptAutoRecovery();
    }
  }

  /// Attempt automatic recovery from latest backup
  Future<bool> _attemptAutoRecovery() async {
    try {
      print('🔄 Attempting automatic storage recovery...');

      final backups = await listBackups();
      if (backups.isEmpty) {
        print('❌ No backups available for recovery');
        return false;
      }

      // Try to restore from the most recent backup
      final latestBackup = backups.first;
      final success = await restoreFromBackup(latestBackup['file_path']);

      if (success) {
        print('✅ Automatic recovery successful');
      } else {
        print('❌ Automatic recovery failed');
      }

      return success;
    } catch (e) {
      print('❌ Auto-recovery error: $e');
      return false;
    }
  }

  /// Schedule automatic backups
  void _scheduleAutoBackup() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      createBackup(description: 'Scheduled automatic backup');
    });
  }

  /// Get all regular storage data
  Future<Map<String, dynamic>> _getAllRegularData(
      StorageService storageService) async {
    // This would need to be implemented based on your storage service internals
    // For now, we'll collect known configuration keys
    final data = <String, dynamic>{};

    // Add known configuration keys
    final knownKeys = [
      'mqtt_broker',
      'mqtt_username',
      'mqtt_enabled',
      'sip_enabled',
      'ai_enabled',
      'settings_pin',
      'window_tiles',
      'display_settings',
      'audio_settings',
      'kiosk_mode',
      // Add more keys as needed
    ];

    for (final key in knownKeys) {
      final value = storageService.read(key);
      if (value != null) {
        data[key] = value;
      }
    }

    return data;
  }

  /// Get secure data keys (not values for security)
  Future<List<String>> _getAllSecureDataKeys() async {
    return [
      'secure_mqtt_broker',
      'secure_mqtt_username',
      'secure_mqtt_password',
      'settingsPin',
      // Add more secure keys as needed
    ];
  }

  /// Restore regular data
  Future<void> _restoreRegularData(
      StorageService storageService, Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      storageService.write(entry.key, entry.value);
    }
  }

  /// Validate backup format
  bool _validateBackupFormat(Map<String, dynamic> backupData) {
    return backupData.containsKey('timestamp') &&
        backupData.containsKey('data') &&
        backupData['data'].containsKey('regular');
  }

  /// Print backup information
  void _printBackupInfo(Map<String, dynamic> backupData) {
    print('📋 Backup Information:');
    print('   📅 Created: ${backupData['timestamp']}');
    print('   📝 Description: ${backupData['description']}');
    print(
        '   📊 Regular keys: ${(backupData['data']['regular'] as Map).keys.length}');
    print(
        '   🔐 Secure keys: ${(backupData['data']['secure'] as List).length}');
  }

  /// Get backup count
  Future<int> _getBackupCount() async {
    if (!await _backupDir!.exists()) return 0;

    return _backupDir!
        .listSync()
        .where((file) => file is File && file.path.endsWith('.json'))
        .length;
  }

  /// Clean up old backups
  Future<void> _cleanupOldBackups() async {
    try {
      final files = _backupDir!
          .listSync()
          .where((file) => file is File && file.path.endsWith('.json'))
          .cast<File>()
          .toList();

      if (files.length <= _maxBackups) return;

      // Sort by modification date (oldest first)
      files.sort(
          (a, b) => a.statSync().modified.compareTo(b.statSync().modified));

      // Delete oldest backups
      final filesToDelete = files.take(files.length - _maxBackups);
      for (final file in filesToDelete) {
        await file.delete();
        print('🗑️ Deleted old backup: ${file.path.split('/').last}');
      }
    } catch (e) {
      print('⚠️ Failed to cleanup old backups: $e');
    }
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  void onClose() {
    _autoBackupTimer?.cancel();
    super.onClose();
  }
}
