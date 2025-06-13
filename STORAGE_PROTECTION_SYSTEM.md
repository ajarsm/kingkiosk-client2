# KingKiosk Storage Protection System

## Overview

The Storage Protection System is designed to prevent configuration loss and provide robust backup/recovery mechanisms for KingKiosk. This addresses the concern about losing storage configuration by implementing multiple layers of protection.

## Components

### 1. StorageBackupService
**Purpose**: Automatic and manual backup creation with recovery capabilities

**Features**:
- **Automatic Backups**: Creates backups every 30 minutes
- **Manual Backups**: On-demand backup creation with custom descriptions
- **Backup Management**: Maintains up to 10 backups (oldest are auto-deleted)
- **Recovery**: Restore from any backup with safety backup creation
- **Export/Import**: Configuration export to external files
- **Integrity Verification**: Validates backup format and content

**Usage**:
```dart
final backupService = Get.find<StorageBackupService>();

// Create manual backup
await backupService.createBackup(description: "Before major changes");

// List available backups
final backups = await backupService.listBackups();

// Restore from backup
await backupService.restoreFromBackup(backupPath);

// Export configuration
await backupService.exportConfiguration("/path/to/export.json");
```

### 2. StorageMonitorService
**Purpose**: Continuous monitoring for corruption, responsiveness, and unexpected changes

**Features**:
- **Health Checks**: Every 5 minutes
- **Responsiveness Testing**: Ensures storage service is working
- **Data Integrity Validation**: Checks for corruption and invalid values
- **Change Detection**: Monitors critical configuration keys
- **Auto Recovery**: Attempts recovery from backups when issues are detected
- **Issue Escalation**: Progressive response to storage problems

**Monitored Keys**:
- `mqtt_broker`, `mqtt_username`, `mqtt_enabled`
- `sip_enabled`, `ai_enabled`
- `settingsPin`, `window_tiles`

**Usage**:
```dart
final monitorService = Get.find<StorageMonitorService>();

// Manual health check
await monitorService.performManualHealthCheck();

// Get storage status
final status = monitorService.getStorageStatus();
```

### 3. StorageRecoveryDialog
**Purpose**: User interface for backup management and recovery

**Features**:
- **Visual Backup Management**: List, create, and manage backups
- **Preview Mode**: Inspect backup contents before restoring
- **One-Click Recovery**: Easy restoration with confirmation dialogs
- **Real-Time Status**: Shows backup dates, sizes, and descriptions
- **Safety Measures**: Creates safety backups before restoration

**Usage**:
```dart
// Show recovery dialog
Get.dialog(StorageRecoveryDialog());
```

## Protection Layers

### Layer 1: Automatic Backups
- Created every 30 minutes during operation
- No user intervention required
- Includes all configuration data
- Automatic cleanup of old backups

### Layer 2: Health Monitoring
- Continuous monitoring every 5 minutes
- Detects storage corruption, unresponsiveness, and data issues
- Automatic recovery attempts when problems are detected
- Escalation system for persistent issues

### Layer 3: Manual Recovery
- User-accessible backup/recovery interface
- Manual backup creation before risky operations
- Import/export capabilities for configuration migration
- Preview mode for backup inspection

### Layer 4: Safety Mechanisms
- Safety backups created before every restoration
- Validation of backup format and integrity
- Confirmation dialogs for destructive operations
- Detailed logging and error reporting

## Configuration Loss Prevention

### Common Scenarios Addressed:

1. **File Corruption**:
   - Detected by integrity checks
   - Auto-recovery from latest backup
   - User notification of recovery actions

2. **Accidental Deletion**:
   - Regular backups ensure data availability
   - Multiple restore points available
   - Manual recovery interface

3. **System Crashes**:
   - Frequent auto-saves minimize data loss
   - Application lock prevents concurrent access
   - Graceful shutdown handling

4. **Storage Device Issues**:
   - Multiple backup generations
   - Export capability for external storage
   - Cross-platform compatibility

5. **User Error**:
   - Safety backups before changes
   - Preview mode for verification
   - Easy rollback capabilities

## Setup and Integration

### 1. Service Registration
The services are automatically registered in `InitialBinding`:

```dart
// Core storage service
Get.put<StorageService>(await StorageService().init(), permanent: true);

// Backup and monitoring services
Get.put<StorageBackupService>(await StorageBackupService().init(), permanent: true);
Get.put<StorageMonitorService>(await StorageMonitorService().init(), permanent: true);
```

### 2. Adding Recovery UI
Add the recovery dialog to your settings or maintenance interface:

```dart
ElevatedButton(
  onPressed: () => Get.dialog(StorageRecoveryDialog()),
  child: Text('Backup & Recovery'),
)
```

### 3. Manual Health Checks
Trigger health checks from maintenance interfaces:

```dart
final monitor = Get.find<StorageMonitorService>();
await monitor.performManualHealthCheck();
```

## File Locations

**Desktop/Mobile**:
- Storage: `Documents/kingkiosk_storage/`
- Backups: `Documents/kingkiosk_storage/backups/`
- Lock file: `Documents/kingkiosk_storage/.lock`

**Web**:
- Storage: Browser localStorage
- Backups: localStorage with prefix `kingkiosk_backup_`

## MQTT Integration

### Storage Commands

```json
// Trigger manual backup
{
  "action": "system_command",
  "command": "create_backup",
  "payload": {
    "description": "Remote backup"
  }
}

// Trigger health check
{
  "action": "system_command",
  "command": "check_storage_health"
}

// Get storage status
{
  "action": "system_command",
  "command": "get_storage_status"
}
```

## Best Practices

### For Users:
1. **Monitor Notifications**: Pay attention to storage alerts
2. **Manual Backups**: Create backups before major configuration changes
3. **Regular Exports**: Export configurations for external backup
4. **Test Recovery**: Periodically test backup restoration

### For Developers:
1. **Critical Keys**: Add important configuration keys to monitoring
2. **Validation**: Implement proper validation for configuration values
3. **Error Handling**: Gracefully handle storage errors
4. **Documentation**: Document configuration changes and their impacts

## Troubleshooting

### Common Issues:

1. **Storage Unresponsive**:
   - Check disk space
   - Verify file permissions
   - Restart application

2. **Backup Creation Failed**:
   - Check available storage space
   - Verify write permissions
   - Review error logs

3. **Recovery Failed**:
   - Verify backup file integrity
   - Check available storage space
   - Try older backup files

4. **Monitoring Alerts**:
   - Review recent configuration changes
   - Check system resources
   - Consider manual recovery

### Emergency Recovery:

If all automatic recovery fails:

1. Stop the application
2. Locate backup files manually
3. Copy latest backup over corrupted files
4. Restart application
5. Verify configuration

## Monitoring and Logs

The system provides detailed logging for all operations:

- **Backup Creation**: Timestamps, file sizes, descriptions
- **Health Checks**: Status, detected issues, recovery attempts
- **Recovery Operations**: Success/failure, backup sources
- **Storage Access**: Read/write operations, errors

Monitor console output for real-time status and troubleshooting information.

## Security Considerations

- **Backup Encryption**: Secure data is encrypted in backups
- **Access Control**: Backup operations may require authentication
- **File Permissions**: Proper permissions on backup directories
- **Sensitive Data**: Secure keys are handled separately

This comprehensive system ensures that your KingKiosk configuration is protected against various failure scenarios and provides multiple recovery options when issues occur.
