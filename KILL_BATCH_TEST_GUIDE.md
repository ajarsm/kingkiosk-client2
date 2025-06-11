# Batch Kill Commands Test

## Available Commands

### 1. Simple Kill Batch
```json
{
  "command": "kill_batch"
}
```
- Simple command that sets the kill flag for any running batch
- No response, just sets internal flags to stop batch execution

### 2. Kill Batch Script (with response)
```json
{
  "command": "kill_batch_script", 
  "response_topic": "kingkiosk/device/response"
}
```
- Kills running batch and publishes result to response topic
- Returns success/failure status and batch ID

### 3. Check Batch Status
```json
{
  "command": "batch_status",
  "response_topic": "kingkiosk/device/status"
}
```
- Returns current batch execution status
- Shows if batch is running, killed, or idle

## Test Sequence

1. **Start a batch with wait commands:**
```json
{
  "commands": [
    {"command": "tts", "text": "Starting batch test"},
    {"command": "wait", "seconds": 5},
    {"command": "tts", "text": "Middle of batch"},
    {"command": "wait", "seconds": 5}, 
    {"command": "tts", "text": "End of batch"}
  ]
}
```

2. **While batch is running, send kill command:**
```json
{"command": "kill_batch"}
```

3. **Check status:**
```json
{
  "command": "batch_status",
  "response_topic": "kingkiosk/test/status"
}
```

## Expected Behavior

- Batch should stop executing after receiving kill command
- Status should show "killed" 
- No further TTS or wait commands should execute
- New batches should be able to start after kill

## Implementation Status

✅ **Batch state variables added**: `_batchScriptRunning`, `_batchKillRequested`, `batchStatus`
✅ **kill_batch command added**: Simple kill command that sets flags
✅ **kill_batch_script command exists**: With response capability  
⚠️ **File has structural issues**: Some try-catch blocks are malformed
⚠️ **Missing helper methods**: Some color and utility methods need to be restored

**Recommendation**: The basic kill functionality is implemented but the file needs cleanup to resolve compilation errors.
