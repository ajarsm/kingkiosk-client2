import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_backup_service.dart';
import '../services/storage_monitor_service.dart';
import '../widgets/storage_recovery_dialog.dart';

/// Storage management widget for settings page
class StorageManagementWidget extends StatelessWidget {
  const StorageManagementWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Storage Protection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Automatic backups and monitoring protect your configuration.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // Action buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Get.dialog(StorageRecoveryDialog()),
                  icon: Icon(Icons.backup),
                  label: Text('Backup & Recovery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _performHealthCheck,
                  icon: Icon(Icons.health_and_safety),
                  label: Text('Health Check'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _createQuickBackup,
                  icon: Icon(Icons.save),
                  label: Text('Quick Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showStorageStatus,
                  icon: Icon(Icons.info),
                  label: Text('Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _performHealthCheck() async {
    try {
      final monitor = Get.find<StorageMonitorService>();
      await monitor.performManualHealthCheck();

      Get.snackbar(
        'Health Check',
        'Storage health check completed successfully',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Health check failed: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void _createQuickBackup() async {
    try {
      final backup = Get.find<StorageBackupService>();
      final path =
          await backup.createBackup(description: 'Manual quick backup');

      if (path != null) {
        Get.snackbar(
          'Success',
          'Backup created successfully',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to create backup',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Backup creation failed: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void _showStorageStatus() async {
    try {
      final monitor = Get.find<StorageMonitorService>();
      final backup = Get.find<StorageBackupService>();

      final status = monitor.getStorageStatus();
      final backups = await backup.listBackups();

      Get.dialog(
        AlertDialog(
          title: Text('Storage Status'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusItem('Monitoring Active',
                    status['monitoring_active'].toString()),
                _buildStatusItem('Inconsistency Count',
                    '${status['inconsistency_count']}/${status['max_inconsistencies']}'),
                _buildStatusItem('Critical Keys Monitored',
                    status['critical_keys_monitored'].toString()),
                _buildStatusItem(
                    'Available Backups', backups.length.toString()),
                _buildStatusItem(
                    'Last Check', _formatDateTime(status['last_check'])),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get storage status: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
