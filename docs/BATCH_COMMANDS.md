# Batch Commands Feature

This document describes the batch commands feature in King Kiosk, which allows sending multiple commands at once via a single MQTT message.

## Overview

The batch commands feature enables you to send multiple commands in a single MQTT message. This is useful for:

- Setting up multiple windows at once
- Reducing network traffic when multiple operations are needed
- Creating complex layouts with a single API call
- Orchestrating multi-step operations

## Format

To send batch commands, use the following format:

```json
{
  "commands": [
    {
      "command": "command1",
      ...command1 parameters...
    },
    {
      "command": "command2",
      ...command2 parameters...
    },
    ...
  ]
}
```

The `commands` array can contain any valid King Kiosk command objects. Each command in the batch will be processed in sequence.

## Example

Here's an example of a batch command that opens multiple windows at once:

```json
{
  "commands": [
    {
      "command": "play_media",
      "type": "image", 
      "url": "https://example.com/image.jpg",
      "style": "window",
      "title": "Image Window"
    },
    {
      "command": "play_media",
      "type": "video",
      "url": "https://example.com/video.mp4",
      "style": "window",
      "title": "Video Window",
      "loop": true
    },
    {
      "command": "open_browser",
      "url": "https://www.example.com",
      "title": "Web Browser"
    }
  ]
}
```

This single message will create three windows: an image window, a video window, and a web browser window.

## Testing

To test the batch commands feature, use the provided test script:

```bash
./test_batch_commands.sh
```

This script demonstrates opening multiple windows with a single MQTT command.

## Error Handling

Each command in the batch is processed independently. If one command fails, the system will continue processing the remaining commands. Errors for individual commands will be logged but won't stop the execution of the batch.

## Limitations

- There is no guaranteed timing between the execution of commands
- There is no dependency management between commands (all commands are treated as independent)
- Very large batches may impact performance
