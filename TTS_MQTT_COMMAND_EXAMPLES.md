# TTS MQTT Command Examples

This document shows how to use the Text-to-Speech (TTS) functionality via MQTT commands in the King Kiosk app.

## TTS Service Features

The TTS service supports all platforms (Android, iOS, Windows, macOS, Linux, Web) with full MQTT-based control.

## MQTT Command Structure

Send commands to the topic: `kingkiosk/{device_name}/command`

### Basic TTS Commands

#### 1. Speak Text
```json
{
  "command": "tts",
  "text": "Hello, this is a test message from King Kiosk"
}
```

#### 2. Alternative Command Names
```json
{
  "command": "speak",
  "text": "You can also use 'speak' as the command"
}
```

```json
{
  "command": "say",
  "text": "Or use 'say' as the command"
}
```

### Advanced TTS Commands

#### 3. Speak with Custom Voice Settings
```json
{
  "command": "tts",
  "text": "This message has custom voice settings",
  "language": "en-US",
  "voice": "com.apple.ttsbundle.Samantha-compact",
  "volume": 0.8,
  "speechRate": 0.6,
  "pitch": 1.2
}
```

#### 4. Queue Multiple Messages
```json
{
  "command": "tts",
  "text": "This message will be queued",
  "queue": true
}
```

### TTS Control Commands

#### 5. Stop Speaking
```json
{
  "command": "tts",
  "action": "stop"
}
```

#### 6. Pause Speaking
```json
{
  "command": "tts",
  "action": "pause"
}
```

#### 7. Resume Speaking
```json
{
  "command": "tts",
  "action": "resume"
}
```

### TTS Configuration Commands

#### 8. Set Volume
```json
{
  "command": "tts",
  "action": "setvolume",
  "volume": 0.7
}
```

#### 9. Set Speech Rate
```json
{
  "command": "tts",
  "action": "setrate",
  "rate": 0.5
}
```

#### 10. Set Pitch
```json
{
  "command": "tts",
  "action": "setpitch",
  "pitch": 1.0
}
```

#### 11. Set Language
```json
{
  "command": "tts",
  "action": "setlanguage",
  "language": "en-GB"
}
```

#### 12. Set Voice
```json
{
  "command": "tts",
  "action": "setvoice",
  "voice": "com.apple.ttsbundle.Daniel-compact"
}
```

### TTS Status Commands

#### 13. Get TTS Status
```json
{
  "command": "tts",
  "action": "status",
  "response_topic": "kingkiosk/{device_name}/tts/status"
}
```

#### 14. Get Available Languages
```json
{
  "command": "tts",
  "action": "getlanguages",
  "response_topic": "kingkiosk/{device_name}/tts/languages"
}
```

#### 15. Get Available Voices
```json
{
  "command": "tts",
  "action": "getvoices",
  "response_topic": "kingkiosk/{device_name}/tts/voices"
}
```

### TTS Enable/Disable

#### 16. Enable TTS
```json
{
  "command": "tts",
  "action": "enable"
}
```

#### 17. Disable TTS
```json
{
  "command": "tts",
  "action": "disable"
}
```

#### 18. Clear Queue
```json
{
  "command": "tts",
  "action": "clearqueue"
}
```

### Batch Commands

#### 19. Multiple TTS Commands in One Message
```json
{
  "command": "batch",
  "commands": [
    {
      "command": "tts",
      "action": "setvolume",
      "volume": 0.8,
      "id": "volume_cmd"
    },
    {
      "command": "tts",
      "text": "Volume set to 80 percent",
      "id": "confirm_volume"
    },
    {
      "command": "tts",
      "text": "This is a second message",
      "queue": true,
      "id": "second_msg"
    }
  ]
}
```

#### 20. TTS Sequence with Configuration
```json
{
  "command": "batch",
  "commands": [
    {
      "command": "tts",
      "action": "setlanguage",
      "language": "en-US",
      "id": "set_lang"
    },
    {
      "command": "tts",
      "action": "setrate",
      "rate": 0.6,
      "id": "set_rate"
    },
    {
      "command": "tts",
      "text": "Welcome to the King Kiosk system",
      "id": "welcome_msg"
    },
    {
      "command": "tts",
      "text": "All systems are operational",
      "queue": true,
      "id": "status_msg"
    }
  ]
}
```

#### 21. Mixed Command Batch (TTS + Other Commands)
```json
{
  "command": "batch",
  "commands": [
    {
      "command": "notify",
      "message": "System starting TTS announcement",
      "tier": "info"
    },
    {
      "command": "tts",
      "text": "System announcement starting",
      "volume": 0.8
    },
    {
      "command": "set_brightness",
      "value": 0.9
    },
    {
      "command": "tts",
      "text": "Screen brightness adjusted",
      "queue": true
    }
  ]
}
```

#### 22. TTS Playlist (Multiple Messages with Response Topics)
```json
{
  "command": "batch",
  "commands": [
    {
      "command": "tts",
      "text": "Playing message one of three",
      "response_topic": "kingkiosk/{device_name}/tts/msg1",
      "id": "msg1"
    },
    {
      "command": "tts",
      "text": "Playing message two of three",
      "queue": true,
      "response_topic": "kingkiosk/{device_name}/tts/msg2",
      "id": "msg2"
    },
    {
      "command": "tts",
      "text": "Playing final message three of three",
      "queue": true,
      "response_topic": "kingkiosk/{device_name}/tts/msg3",
      "id": "msg3"
    }
  ]
}
```

## Response Topics

When you include a `response_topic` in your command, the TTS service will publish the result to that topic:

### Success Response
```json
{
  "success": true,
  "action": "speak",
  "text": "Hello, this is a test message"
}
```

### Error Response
```json
{
  "success": false,
  "error": "TTS service not available: Service not initialized"
}
```

### Batch Command Response
```json
[
  {
    "success": true,
    "action": "setVolume",
    "volume": 0.8,
    "batchIndex": 0,
    "commandId": "volume_cmd"
  },
  {
    "success": true,
    "action": "speak",
    "text": "Volume set to 80 percent",
    "batchIndex": 1,
    "commandId": "confirm_volume"
  },
  {
    "success": true,
    "action": "speak",
    "text": "This is a second message",
    "batchIndex": 2,
    "commandId": "second_msg"
  }
]
```

## Platform-Specific Notes

### Android
- Supports Google Text-to-Speech engine
- Large selection of voices and languages
- Hardware acceleration supported

### iOS
- Uses AVSpeechSynthesizer
- High-quality voices
- Seamless integration with system settings

### Windows
- Uses SAPI (Speech API)
- Multiple voice engines supported
- Respects system speech settings

### macOS
- Uses NSSpeechSynthesizer
- High-quality system voices
- Excellent language support

### Linux
- Uses espeak or festival
- May require additional voice packages
- Good multilingual support

### Web
- Uses Web Speech API
- Browser-dependent voice quality
- Limited voice selection

## Testing TTS

To test TTS functionality:

1. Ensure your MQTT broker is running
2. Connect the King Kiosk app to MQTT
3. Use an MQTT client (like MQTT Explorer) to send commands
4. Send a simple test command:

```bash
# Using mosquitto_pub
mosquitto_pub -h your-broker-ip -t "kingkiosk/your-device/command" -m '{"command":"tts","text":"TTS test successful"}'
```

## Integration Examples

### Home Assistant
```yaml
# Example Home Assistant service call
service: mqtt.publish
data:
  topic: "kingkiosk/main-kiosk/command"
  payload: |
    {
      "command": "tts",
      "text": "{{ message }}",
      "volume": 0.8
    }
```

### Node-RED
```javascript
// Example Node-RED function node
msg.topic = "kingkiosk/main-kiosk/command";
msg.payload = {
    "command": "tts",
    "text": msg.payload.message,
    "language": msg.payload.language || "en-US"
};
return msg;
```

## Troubleshooting

1. **TTS not working**: Ensure TTS service is initialized in app bindings
2. **No audio**: Check device volume and TTS volume settings
3. **Wrong language**: Use `getlanguages` action to see available languages
4. **Voice issues**: Use `getvoices` action to see available voices
5. **MQTT issues**: Verify MQTT connection and topic permissions

## Performance and Batch Processing

### Enhanced Batch Command Optimization

The TTS service includes state-of-the-art batch processing with the following optimizations:

1. **Intelligent Command Separation**: In batch commands, TTS commands are automatically separated and processed using the optimized `handleBatchMqttCommands` method
2. **Reduced Latency**: TTS commands in batches are processed directly without JSON re-encoding overhead
3. **Better Error Handling**: Individual command errors don't stop the entire batch
4. **Command Tracking**: Each command in a batch gets a unique ID and index for comprehensive tracking
5. **Audio Sequencing**: Automatic small delays between speech commands prevent audio overlap
6. **Response Management**: Individual response topics are handled for each command in the batch

### Batch Processing Architecture

#### Standard Processing (Individual Commands)
```
MQTT → Parse → Individual TTS Command → TTS Service → Response
```

#### Optimized Batch Processing (Multiple TTS Commands)
```
MQTT → Parse → Separate TTS Commands → Batch TTS Service → Multiple Responses
```

#### Mixed Batch Processing (TTS + Other Commands)
```
MQTT → Parse → Separate Commands → TTS Batch + Individual Others → Multiple Responses
```

### Advanced Batch Response Structure

When processing batch commands with TTS, responses include enhanced tracking information:

```json
[
  {
    "success": true,
    "action": "speak",
    "text": "First message",
    "batchIndex": 0,
    "commandId": "msg1",
    "timestamp": 1672531200000,
    "processingTime": 150
  },
  {
    "success": true,
    "action": "speak", 
    "text": "Second message",
    "batchIndex": 1,
    "commandId": "msg2",
    "timestamp": 1672531201000,
    "processingTime": 120
  }
]
```

### Batch Performance Metrics

#### Optimal Batch Configurations
- **Small Batches (1-3 commands)**: Best for interactive responses
- **Medium Batches (4-8 commands)**: Ideal for announcements and sequences
- **Large Batches (9+ commands)**: Best for playlists and extended content

#### Performance Tips

1. **Use Command IDs**: Include unique `id` fields for tracking batch command results
2. **Queue Sequential Messages**: Use `queue: true` for messages that should play in sequence
3. **Audio Sequencing**: The system automatically prevents overlap with intelligent timing
4. **Monitor Response Topics**: Use response topics to track batch command completion
5. **Optimal Batch Size**: Keep batches under 15 commands for best performance
6. **Error Recovery**: Use individual response topics to handle partial batch failures

### Enhanced Batch Examples

#### 23. Optimized TTS Announcement Sequence
```json
{
  "command": "batch",
  "commands": [
    {
      "command": "tts",
      "action": "setvolume",
      "volume": 0.9,
      "id": "prep_volume",
      "response_topic": "kingkiosk/{device_name}/tts/batch/prep"
    },
    {
      "command": "tts",
      "text": "Attention: System announcement",
      "language": "en-US",
      "speechRate": 0.6,
      "id": "announcement_start",
      "response_topic": "kingkiosk/{device_name}/tts/batch/start"
    },
    {
      "command": "tts",
      "text": "All systems operating normally",
      "queue": true,
      "id": "status_update",
      "response_topic": "kingkiosk/{device_name}/tts/batch/status"
    },
    {
      "command": "tts",
      "text": "Thank you for your attention",
      "queue": true,
      "volume": 0.7,
      "id": "announcement_end",
      "response_topic": "kingkiosk/{device_name}/tts/batch/end"
    }
  ],
  "batch_response_topic": "kingkiosk/{device_name}/tts/batch/complete"
}
```

#### 24. Multi-Language Batch Sequence
```json
{
  "command": "batch",
  "commands": [
    {
      "command": "tts",
      "text": "Welcome to our service",
      "language": "en-US",
      "id": "welcome_en",
      "response_topic": "kingkiosk/{device_name}/tts/multilang/en"
    },
    {
      "command": "tts",
      "text": "Bienvenido a nuestro servicio",
      "language": "es-ES", 
      "queue": true,
      "id": "welcome_es",
      "response_topic": "kingkiosk/{device_name}/tts/multilang/es"
    },
    {
      "command": "tts",
      "text": "Bienvenue à notre service",
      "language": "fr-FR",
      "queue": true,
      "id": "welcome_fr",
      "response_topic": "kingkiosk/{device_name}/tts/multilang/fr"
    }
  ]
}
```

#### 25. Emergency Alert with Fallback
```json
{
  "command": "batch",
  "commands": [
    {
      "command": "tts",
      "action": "stop",
      "id": "stop_current",
      "response_topic": "kingkiosk/{device_name}/emergency/stop"
    },
    {
      "command": "tts",
      "action": "clearqueue",
      "id": "clear_queue",
      "response_topic": "kingkiosk/{device_name}/emergency/clear"
    },
    {
      "command": "tts",
      "action": "setvolume",
      "volume": 1.0,
      "id": "max_volume",
      "response_topic": "kingkiosk/{device_name}/emergency/volume"
    },
    {
      "command": "tts",
      "text": "EMERGENCY ALERT: Please evacuate immediately",
      "language": "en-US",
      "speechRate": 0.8,
      "pitch": 1.3,
      "id": "emergency_alert",
      "response_topic": "kingkiosk/{device_name}/emergency/alert"
    }
  ]
}
```

### Batch vs Individual Commands

#### When to Use Batch Commands
- **Complex Sequences**: Multiple TTS messages with configuration changes
- **Synchronized Operations**: TTS combined with other system commands
- **Performance Critical**: Reducing MQTT overhead for multiple commands
- **Error Tracking**: When you need detailed success/failure reporting
- **Audio Playlists**: Sequential speech content delivery

#### When to Use Individual Commands
- **Simple Messages**: Single TTS announcements
- **Real-time Interactive**: Immediate response scenarios
- **Emergency Override**: Priority announcements that bypass queues
- **Testing and Debugging**: Isolated command verification

### Performance Monitoring

#### Batch Processing Metrics
Monitor these values for optimal performance:

1. **Batch Processing Time**: Total time to process all TTS commands in batch
2. **Individual Command Latency**: Time per command within the batch
3. **Audio Queue Length**: Number of commands waiting in TTS queue
4. **Error Rate**: Percentage of failed commands in batches
5. **Response Topic Activity**: Success rate of response deliveries

#### Optimization Strategies

1. **Command Grouping**: Group related TTS commands together
2. **Response Topic Usage**: Use selective response topics to reduce MQTT traffic
3. **Queue Management**: Clear queues before important announcements
4. **Language Caching**: Group commands by language to reduce switching overhead
5. **Voice Optimization**: Minimize voice changes within batches

## Performance Tips

1. Use `queue: true` for multiple messages to avoid interruption
2. Set appropriate speech rate for your content
3. Use response topics for debugging and status monitoring
4. Clear queue when switching contexts to avoid outdated messages
5. Use batch commands for complex sequences
6. Include command IDs for better tracking and debugging
