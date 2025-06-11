# Batch Kill Implementation

## Overview
Implemented a robust batch execution and cancellation system for MQTT commands that ensures only one batch script runs at a time and provides the ability to kill running batches.

## Features Implemented

### 1. Batch State Tracking
- **Single batch execution**: Only one batch script can run at a time
- **Batch ID tracking**: Each batch gets a unique timestamp-based ID
- **Running state**: Tracks if a batch is currently executing
- **Cancellation flag**: Provides mechanism to stop ongoing batches

### 2. Batch Control Variables
```dart
// Added to MqttService class
bool _isBatchRunning = false;
bool _shouldCancelBatch = false;
String? _currentBatchId;
```

### 3. Batch Execution Logic
- **Prevention of concurrent batches**: New batch commands are ignored if one is already running
- **Cancellation checks**: Each command in a batch checks for cancellation before executing
- **Clean state management**: Batch state is properly reset after completion or cancellation

### 4. Kill Commands

#### A. `kill_batch` Command
```json
{
  "command": "kill_batch"
}
```
- Simple command to cancel the currently running batch
- Sets the `_shouldCancelBatch` flag to true
- Provides console feedback about batch status

#### B. `kill_batch_script` Command  
```json
{
  "command": "kill_batch_script",
  "response_topic": "kingkiosk/device/response"
}
```
- More comprehensive kill command with response capability
- Publishes success/failure status to specified response topic
- Returns batch ID and detailed status information

### 5. Batch Execution Flow
1. **Batch Start**: Check if another batch is running → Set running state → Generate batch ID
2. **Command Processing**: For each command, check cancellation flag → Execute if not cancelled
3. **Cancellation**: Kill command sets flag → Next command check stops execution
4. **Cleanup**: Reset all batch state variables when batch completes or is cancelled

## Usage Examples

### Running a Batch with Wait Commands
```json
{
  "commands": [
    {"command": "show_window", "window": "calendar"},
    {"command": "wait", "seconds": 3},
    {"command": "hide_window", "window": "calendar"},
    {"command": "wait", "seconds": 2},
    {"command": "tts", "text": "Batch complete"}
  ]
}
```

### Killing a Running Batch
```json
{
  "command": "kill_batch"
}
```

### Killing with Response Confirmation
```json
{
  "command": "kill_batch_script",
  "response_topic": "kingkiosk/rajofficemac/batch/status"
}
```

## Response Format (for kill_batch_script)
```json
{
  "success": true,
  "message": "Batch script cancelled",
  "killed_batch_id": "1671234567890",
  "command": "kill_batch_script", 
  "timestamp": "2023-12-17T10:30:00.000Z"
}
```

## Safety Features
- **No concurrent batches**: Prevents multiple scripts from interfering with each other
- **Graceful cancellation**: Commands check for cancellation before executing
- **State cleanup**: Ensures batch state is properly reset
- **Error handling**: Batch execution continues even if individual commands fail
- **Response topics**: Provides feedback for monitoring batch execution

## Integration with Existing Commands
- **TTS optimization**: TTS commands are still batched together for efficiency
- **Wait command**: Works seamlessly within batches for timing control
- **All MQTT commands**: Any existing MQTT command can be used in batches
- **Window commands**: Perfect for coordinated UI sequences

This implementation provides a clean, safe way to run complex MQTT command sequences while maintaining full control over execution flow.
