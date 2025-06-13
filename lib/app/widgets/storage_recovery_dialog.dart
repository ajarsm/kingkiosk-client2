import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_backup_service.dart';

/// Storage recovery and backup management dialog
class StorageRecoveryDialog extends StatefulWidget {
  const StorageRecoveryDialog({Key? key}) : super(key: key);

  @override
  State<StorageRecoveryDialog> createState() => _StorageRecoveryDialogState();
}

class _StorageRecoveryDialogState extends State<StorageRecoveryDialog> {
  final StorageBackupService _backupService = Get.find<StorageBackupService>();
  List<Map<String, dynamic>> _backups = [];
  bool _loading = true;
  String? _selectedBackup;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _loading = true);
    try {
      final backups = await _backupService.listBackups();
      setState(() {
        _backups = backups;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Failed to load backups: $e');
    }
  }

  Future<void> _createBackup() async {
    try {
      final result = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Create Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter a description for this backup:'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Backup description',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => Get.back(result: value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: 'Manual backup'),
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (result != null) {
        final backupPath =
            await _backupService.createBackup(description: result);
        if (backupPath != null) {
          _showSuccess('Backup created successfully');
          _loadBackups();
        } else {
          _showError('Failed to create backup');
        }
      }
    } catch (e) {
      _showError('Failed to create backup: $e');
    }
  }

  Future<void> _restoreBackup(String backupPath) async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirm Restore'),
          content: const Text(
            'This will restore your configuration from the selected backup. '
            'A safety backup will be created first. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await _backupService.restoreFromBackup(backupPath);
        if (success) {
          _showSuccess('Configuration restored successfully');
          Get.back(); // Close the dialog
        } else {
          _showError('Failed to restore configuration');
        }
      }
    } catch (e) {
      _showError('Failed to restore backup: $e');
    }
  }

  Future<void> _previewBackup(String backupPath) async {
    try {
      await _backupService.restoreFromBackup(backupPath, preview: true);
      _showSuccess('Check console for backup details');
    } catch (e) {
      _showError('Failed to preview backup: $e');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup, size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                const Text(
                  'Storage Backup & Recovery',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _createBackup,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Backup'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadBackups,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Backups list
            const Text(
              'Available Backups:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _backups.isEmpty
                      ? const Center(
                          child: Text(
                            'No backups found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _backups.length,
                          itemBuilder: (context, index) {
                            final backup = _backups[index];
                            final isSelected =
                                _selectedBackup == backup['file_path'];

                            return Card(
                              color: isSelected ? Colors.blue.shade50 : null,
                              child: ListTile(
                                leading: const Icon(Icons.archive,
                                    color: Colors.blue),
                                title: Text(
                                  backup['description'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Created: ${_formatDate(backup['timestamp'])}'),
                                    Text('Size: ${backup['readable_size']}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _previewBackup(backup['file_path']),
                                      icon: const Icon(Icons.visibility),
                                      tooltip: 'Preview',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _restoreBackup(backup['file_path']),
                                      icon: const Icon(Icons.restore),
                                      tooltip: 'Restore',
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedBackup =
                                        isSelected ? null : backup['file_path'];
                                  });
                                },
                              ),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 16),

            // Info panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Backup Information',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Backups are created automatically every 30 minutes\n'
                    '• Up to 10 backups are kept (oldest are deleted)\n'
                    '• Backups include all settings and configurations\n'
                    '• A safety backup is created before every restore',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
