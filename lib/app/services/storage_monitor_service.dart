import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../services/storage_backup_service.dart';

/// Storage monitoring service to detect and prevent configuration loss
class StorageMonitorService extends GetxService {
  Timer? _monitorTimer;
  final Map<String, dynamic> _lastKnownState = {};
  final List<String> _criticalKeys = [
    'mqtt_broker',
    'mqtt_username',
    'mqtt_enabled',
    'sip_enabled',
    'ai_enabled',
    'settingsPin',
    'window_tiles',
  ];

  int _inconsistencyCount = 0;
  static const int _maxInconsistencies = 3;

  /// Initialize the storage monitor
  Future<StorageMonitorService> init() async {
    try {
      print('🔄 Initializing storage monitor service...');

      // Take initial snapshot
      await _takeSnapshot();

      // Start monitoring
      _startMonitoring();

      print('✅ Storage monitor service ready');
      return this;
    } catch (e) {
      print('❌ Failed to initialize storage monitor: $e');
      rethrow;
    }
  }

  /// Start monitoring storage for changes and corruption
  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performHealthCheck();
    });
  }

  /// Perform comprehensive health check
  Future<void> _performHealthCheck() async {
    try {
      final storageService = Get.find<StorageService>();

      // Check if storage service is responsive
      if (!await _isStorageResponsive(storageService)) {
        print('⚠️ Storage service is not responsive');
        await _handleStorageIssue('Storage service unresponsive');
        return;
      }

      // Check for data corruption
      if (!await _checkDataIntegrity(storageService)) {
        print('⚠️ Data integrity check failed');
        await _handleStorageIssue('Data integrity failure');
        return;
      }

      // Check for unexpected changes
      if (await _detectUnexpectedChanges(storageService)) {
        print('⚠️ Unexpected configuration changes detected');
        await _handleStorageIssue('Unexpected configuration changes');
        return;
      }

      // Update snapshot if all checks pass
      await _takeSnapshot();

      // Reset inconsistency counter on successful check
      _inconsistencyCount = 0;
    } catch (e) {
      print('❌ Storage health check error: $e');
      await _handleStorageIssue('Health check exception: $e');
    }
  }

  /// Check if storage service is responsive
  Future<bool> _isStorageResponsive(StorageService storageService) async {
    try {
      const testKey = '__monitor_test__';
      final testValue = DateTime.now().millisecondsSinceEpoch.toString();

      // Test write
      storageService.write(testKey, testValue);

      // Test read
      final readValue = storageService.read<String>(testKey);

      // Cleanup
      storageService.remove(testKey);

      return readValue == testValue;
    } catch (e) {
      print('❌ Storage responsiveness test failed: $e');
      return false;
    }
  }

  /// Check data integrity
  Future<bool> _checkDataIntegrity(StorageService storageService) async {
    try {
      // Check if critical configuration keys exist and have valid values
      for (final key in _criticalKeys) {
        final value = storageService.read(key);

        if (key == 'mqtt_enabled' ||
            key == 'sip_enabled' ||
            key == 'ai_enabled') {
          if (value != null && value is! bool) {
            print('⚠️ Invalid type for boolean key: $key');
            return false;
          }
        }

        if (key == 'mqtt_broker' && value is String && value.isNotEmpty) {
          // Basic URL validation for MQTT broker
          if (!_isValidBrokerUrl(value)) {
            print('⚠️ Invalid MQTT broker URL format: $value');
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('❌ Data integrity check error: $e');
      return false;
    }
  }

  /// Detect unexpected changes in critical configuration
  Future<bool> _detectUnexpectedChanges(StorageService storageService) async {
    try {
      for (final key in _criticalKeys) {
        final currentValue = storageService.read(key);
        final lastValue = _lastKnownState[key];

        if (currentValue != lastValue) {
          print('📝 Configuration change detected: $key');
          print('   Previous: $lastValue');
          print('   Current: $currentValue');

          // For now, just log changes. In production, you might want to
          // implement change validation or require authentication for certain changes
        }
      }

      return false; // For now, don't treat changes as issues
    } catch (e) {
      print('❌ Change detection error: $e');
      return false;
    }
  }

  /// Take a snapshot of current storage state
  Future<void> _takeSnapshot() async {
    try {
      final storageService = Get.find<StorageService>();
      _lastKnownState.clear();

      for (final key in _criticalKeys) {
        _lastKnownState[key] = storageService.read(key);
      }

      print('📸 Storage snapshot taken: ${_lastKnownState.length} keys');
    } catch (e) {
      print('❌ Failed to take storage snapshot: $e');
    }
  }

  /// Handle storage issues
  Future<void> _handleStorageIssue(String issue) async {
    try {
      _inconsistencyCount++;
      print(
          '⚠️ Storage issue detected: $issue (Count: $_inconsistencyCount/$_maxInconsistencies)');

      // Create emergency backup
      final backupService = Get.find<StorageBackupService>();
      await backupService.createBackup(
          description: 'Emergency backup - $issue');

      if (_inconsistencyCount >= _maxInconsistencies) {
        print('🚨 Critical storage issues detected - attempting recovery');
        await _attemptRecovery();
      }
    } catch (e) {
      print('❌ Failed to handle storage issue: $e');
    }
  }

  /// Attempt automatic recovery
  Future<void> _attemptRecovery() async {
    try {
      print('🔄 Attempting automatic storage recovery...');

      final backupService = Get.find<StorageBackupService>();
      final backups = await backupService.listBackups();

      if (backups.isEmpty) {
        print('❌ No backups available for recovery');
        _notifyUser('Critical storage issue detected but no backups available');
        return;
      }

      // Try to restore from the most recent backup
      final latestBackup = backups.first;
      final success =
          await backupService.restoreFromBackup(latestBackup['file_path']);

      if (success) {
        print('✅ Automatic recovery successful');
        _inconsistencyCount = 0;
        await _takeSnapshot();
        _notifyUser('Storage recovered from backup');
      } else {
        print('❌ Automatic recovery failed');
        _notifyUser('Critical storage issue - manual intervention required');
      }
    } catch (e) {
      print('❌ Recovery attempt failed: $e');
      _notifyUser('Storage recovery failed - contact support');
    }
  }

  /// Notify user of storage issues
  void _notifyUser(String message) {
    Get.snackbar(
      'Storage Alert',
      message,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
      duration: const Duration(seconds: 10),
      isDismissible: true,
    );
  }

  /// Validate broker URL format
  bool _isValidBrokerUrl(String url) {
    try {
      if (url.isEmpty) return false;

      // Basic validation - could be enhanced
      return url.contains(':') &&
          (url.startsWith('mqtt://') ||
              url.startsWith('mqtts://') ||
              url.startsWith('tcp://') ||
              url.startsWith('ssl://') ||
              !url.contains('://'));
    } catch (e) {
      return false;
    }
  }

  /// Force a manual health check
  Future<void> performManualHealthCheck() async {
    print('🔍 Performing manual storage health check...');
    await _performHealthCheck();
  }

  /// Get current storage status
  Map<String, dynamic> getStorageStatus() {
    return {
      'monitoring_active': _monitorTimer?.isActive ?? false,
      'inconsistency_count': _inconsistencyCount,
      'max_inconsistencies': _maxInconsistencies,
      'critical_keys_monitored': _criticalKeys.length,
      'last_snapshot_size': _lastKnownState.length,
      'last_check': DateTime.now().toIso8601String(),
    };
  }

  @override
  void onClose() {
    _monitorTimer?.cancel();
    super.onClose();
  }
}

/// Extension to add storage monitoring features to existing services
extension StorageMonitoring on GetxService {
  /// Manually trigger a storage health check
  void checkStorageHealth() {
    try {
      final monitor = Get.find<StorageMonitorService>();
      monitor.performManualHealthCheck();
    } catch (e) {
      print('⚠️ Storage monitor not available: $e');
    }
  }
}
