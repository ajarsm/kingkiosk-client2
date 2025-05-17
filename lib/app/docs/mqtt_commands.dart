// MQTT Commands Reference for King Kiosk
// This file documents all available MQTT commands in a structured format.
// It is intended as a reference for developers and integration with external systems.

/// A documentation class that provides information about all supported MQTT commands.
/// T  /// System control commands
  static const Map<String, dynamic> systemCommands = {
    'notify': {
      'description': 'Send a notification to the kiosk',
      'parameters': {
        'command': 'notify (required)',
        'title': 'Notification title (optional, defaults to "MQTT Notification")',
        'message': 'Notification message content (required)',
        'priority': 'Priority level: "high", "normal", or "low" (optional, defaults to "normal")',
        'is_html': 'Boolean, whether message contains HTML content (optional, defaults to false)',
        'html': 'Alternative to is_html, same functionality',
        'thumbnail': 'URL to thumbnail image for the notification (optional)'
      },
      'examples': [
        {
          'description': 'Send a basic notification',
          'payload': {
            'command': 'notify',
            'title': 'System Alert',
            'message': 'System update completed successfully.'
          }
        },
        {
          'description': 'Send an HTML notification with high priority',
          'payload': {
            'command': 'notify',
            'title': 'Important Update',
            'message': '<h3>New Feature Available</h3><p>Click <a href=\"https://example.com\">here</a> to learn more.</p>',
            'is_html': true,
            'priority': 'high',
            'thumbnail': 'https://example.com/notification-icon.png'
          }
        }
      ]
    },
    'set_volume': {
      'description': 'Set system volume',
      'parameters': {
        'command': 'set_volume (required)',
        'value': 'Float between 0.0 and 1.0 (required)'
      },
      'examples': [
        {
          'description': 'Set volume to 50%',
          'payload': {
            'command': 'set_volume',
            'value': 0.5
          }
        }
      ]
    }, the application logic but serves as a reference.
class MqttCommandsReference {
  
  /// Media playback commands for audio, video and images
  static const Map<String, dynamic> mediaCommands = {
    'play_media': {
      'description': 'Play various media types (video, audio, image)',
      'parameters': {
        'command': 'play_media (required)',
        'type': 'video, audio, or image (required)',
        'url': 'URL to the media file or list of URLs for image carousel (required)',
        'style': 'window, fullscreen, or background (default)',
        'title': 'Optional title for the window',
        'loop': 'true/false - Whether to loop the media (default: false)',
        'window_id': 'Optional ID to identify window for further control'
      },
      'examples': [
        {
          'description': 'Play video in window',
          'payload': {
            'command': 'play_media',
            'type': 'video',
            'url': 'https://example.com/video.mp4',
            'style': 'window',
            'title': 'My Video',
            'loop': true,
            'window_id': 'video1'
          }
        },
        {
          'description': 'Play audio in window',
          'payload': {
            'command': 'play_media',
            'type': 'audio',
            'url': 'https://example.com/audio.mp3',
            'style': 'window',
            'title': 'Music Track',
            'window_id': 'audio1'
          }
        },
        {
          'description': 'Display image in window',
          'payload': {
            'command': 'play_media',
            'type': 'image',
            'url': 'https://example.com/image.jpg',
            'title': 'My Image',
            'window_id': 'image1'
          }
        },
        {
          'description': 'Play video fullscreen',
          'payload': {
            'command': 'play_media',
            'type': 'video',
            'url': 'https://example.com/video.mp4',
            'style': 'fullscreen',
            'loop': false
          }
        },
        {
          'description': 'Display multiple images as carousel',
          'payload': {
            'command': 'play_media',
            'type': 'image',
            'url': [
              'https://example.com/image1.jpg',
              'https://example.com/image2.jpg',
              'https://example.com/image3.jpg'
            ],
            'title': 'Image Gallery',
            'window_id': 'gallery1'
          }
        }
      ]
    }
  };

  /// Web browser commands
  static const Map<String, dynamic> webCommands = {
    'open_browser': {
      'description': 'Open a web page in a window',
      'parameters': {
        'command': 'open_browser (required)',
        'url': 'The website URL to open (required)',
        'title': 'Optional title for the window',
        'window_id': 'Optional ID to identify window for further control'
      },
      'examples': [
        {
          'description': 'Open website',
          'payload': {
            'command': 'open_browser',
            'url': 'https://example.com',
            'title': 'Example Website',
            'window_id': 'web1'
          }
        }
      ]
    },
    'evaljs': {
      'description': 'Execute JavaScript code in a web window',
      'parameters': {
        'command': 'evaljs (required)',
        'window_id': 'ID of the web window (required)',
        'code': 'JavaScript code to execute (required)'
      },
      'examples': [
        {
          'description': 'Change background color',
          'payload': {
            'command': 'evaljs',
            'window_id': 'web1',
            'code': 'document.body.style.backgroundColor = "red";'
          }
        }
      ]
    },
    'loadurl': {
      'description': 'Load a new URL in an existing web window',
      'parameters': {
        'command': 'loadurl (required)',
        'window_id': 'ID of the web window (required)',
        'url': 'The new URL to load (required)'
      },
      'examples': [
        {
          'description': 'Navigate to new page',
          'payload': {
            'command': 'loadurl',
            'window_id': 'web1',
            'url': 'https://example.com/new-page'
          }
        }
      ]
    },
    'refresh': {
      'description': 'Refresh a web window',
      'parameters': {
        'command': 'refresh (required)',
        'window_id': 'ID of the web window to refresh (required)'
      },
      'examples': [
        {
          'description': 'Refresh web page',
          'payload': {
            'command': 'refresh',
            'window_id': 'web1'
          }
        }
      ]
    },
    'restart': {
      'description': 'Restart a web window',
      'parameters': {
        'command': 'restart (required)',
        'window_id': 'ID of the web window to restart (required)'
      },
      'examples': [
        {
          'description': 'Restart web window',
          'payload': {
            'command': 'restart',
            'window_id': 'web1'
          }
        }
      ]
    }
  };

  /// Window management commands
  static const Map<String, dynamic> windowCommands = {
    'close_window': {
      'description': 'Close a specific window by ID',
      'parameters': {
        'command': 'close_window (required)',
        'window_id': 'ID of the window to close (required)'
      },
      'examples': [
        {
          'description': 'Close a window',
          'payload': {
            'command': 'close_window',
            'window_id': 'video1'
          }
        }
      ]
    },
    'maximize_window': {
      'description': 'Maximize a specific window by ID',
      'parameters': {
        'command': 'maximize_window (required)',
        'window_id': 'ID of the window to maximize (required)'
      },
      'examples': [
        {
          'description': 'Maximize a window',
          'payload': {
            'command': 'maximize_window',
            'window_id': 'web1'
          }
        }
      ]
    },
    'minimize_window': {
      'description': 'Minimize a specific window by ID',
      'parameters': {
        'command': 'minimize_window (required)',
        'window_id': 'ID of the window to minimize (required)'
      },
      'examples': [
        {
          'description': 'Minimize a window',
          'payload': {
            'command': 'minimize_window',
            'window_id': 'video1'
          }
        }
      ]
    }
  };

  /// Media player control commands
  static const Map<String, dynamic> mediaControlCommands = {
    'play': {
      'description': 'Resume playback of a paused media window',
      'parameters': {
        'command': 'play (required)',
        'window_id': 'ID of the media window to resume (required)'
      },
      'examples': [
        {
          'description': 'Play media',
          'payload': {
            'command': 'play',
            'window_id': 'video1'
          }
        }
      ]
    },
    'pause': {
      'description': 'Pause playback of a media window',
      'parameters': {
        'command': 'pause (required)',
        'window_id': 'ID of the media window to pause (required)'
      },
      'examples': [
        {
          'description': 'Pause media',
          'payload': {
            'command': 'pause',
            'window_id': 'video1'
          }
        }
      ]
    },
    'close': {
      'description': 'Close a media window',
      'parameters': {
        'command': 'close (required)',
        'window_id': 'ID of the media window to close (required)'
      },
      'examples': [
        {
          'description': 'Close media window',
          'payload': {
            'command': 'close',
            'window_id': 'video1'
          }
        }
      ]
    },
    'pause_media': {
      'description': 'Pause playback of a media window (legacy, deprecated)',
      'parameters': {
        'command': 'pause_media (required)',
        'window_id': 'ID of the media window to pause (required)'
      },
      'deprecated': true,
      'replacement': 'use "pause" command instead',
      'examples': [
        {
          'description': 'Pause media (legacy)',
          'payload': {
            'command': 'pause_media',
            'window_id': 'video1'
          }
        }
      ]
    }
  };

  /// System control commands
  static const Map<String, dynamic> systemCommands = {
    'set_volume': {
      'description': 'Set the system volume level',
      'parameters': {
        'command': 'set_volume (required)',
        'value': 'Volume level from 0.0 (muted) to 1.0 (maximum) (required)'
      },
      'examples': [
        {
          'description': 'Set volume to 50%',
          'payload': {
            'command': 'set_volume',
            'value': 0.5
          }
        }
      ]
    },
    'mute': {
      'description': 'Mute the system audio',
      'parameters': {
        'command': 'mute (required)'
      },
      'examples': [
        {
          'description': 'Mute audio',
          'payload': {
            'command': 'mute'
          }
        }
      ]
    },
    'unmute': {
      'description': 'Unmute the system audio',
      'parameters': {
        'command': 'unmute (required)'
      },
      'examples': [
        {
          'description': 'Unmute audio',
          'payload': {
            'command': 'unmute'
          }
        }
      ]
    },
    'set_brightness': {
      'description': 'Set the system screen brightness',
      'parameters': {
        'command': 'set_brightness (required)',
        'value': 'Brightness level from 0.0 (dim) to 1.0 (brightest) (required)'
      },
      'examples': [
        {
          'description': 'Set brightness to 80%',
          'payload': {
            'command': 'set_brightness',
            'value': 0.8
          }
        }
      ]
    },
    'get_brightness': {
      'description': 'Get the current system brightness level',
      'parameters': {
        'command': 'get_brightness (required)',
        'response_topic': 'Optional topic where brightness value will be published'
      },
      'examples': [
        {
          'description': 'Get current brightness',
          'payload': {
            'command': 'get_brightness',
            'response_topic': 'kiosk/brightness/response'
          }
        }
      ]
    },
    'restore_brightness': {
      'description': 'Restore system brightness to default level',
      'parameters': {
        'command': 'restore_brightness (required)'
      },
      'examples': [
        {
          'description': 'Restore brightness to default',
          'payload': {
            'command': 'restore_brightness'
          }
        }
      ]
    }
  };

  /// Batch command format
  static const Map<String, dynamic> batchCommands = {
    'commands': {
      'description': 'Execute multiple commands in a single MQTT message',
      'format': {
        'commands': '[Array of command objects]'
      },
      'examples': [
        {
          'description': 'Open video and set volume',
          'payload': {
            'commands': [
              {
                'command': 'play_media',
                'type': 'video',
                'url': 'https://example.com/video.mp4',
                'style': 'window',
                'window_id': 'video1'
              },
              {
                'command': 'set_volume',
                'value': 0.7
              }
            ]
          }
        }
      ]
    }
  };

  /// Best practices for MQTT commands
  static const List<String> bestPractices = [
    'Always use window_id for windows to make it easier to control them later',
    'Use descriptive titles to help identify what each window contains',
    'Use batch commands for related operations',
    'Consider device capabilities (some may not support brightness control, etc.)',
    'For multiple related commands, use batch format to ensure they execute in order',
    'Avoid deprecated commands like pause_media in favor of newer alternatives'
  ];
  
  /// Notification commands
  static const Map<String, dynamic> notificationCommands = {
    'notify': {
      'description': 'Send a notification to the kiosk',
      'parameters': {
        'command': 'notify (required)',
        'title': 'Notification title (optional, defaults to "MQTT Notification")',
        'message': 'Notification message content (required)',
        'priority': 'Priority level: "high", "normal", or "low" (optional, defaults to "normal")',
        'is_html': 'Boolean, whether message contains HTML content (optional, defaults to false)',
        'html': 'Alternative to is_html, same functionality',
        'thumbnail': 'URL to thumbnail image for the notification (optional)'
      },
      'examples': [
        {
          'description': 'Send a basic notification',
          'payload': {
            'command': 'notify',
            'title': 'System Alert',
            'message': 'System update completed successfully.'
          }
        },
        {
          'description': 'Send an HTML notification with high priority',
          'payload': {
            'command': 'notify',
            'title': 'Important Update',
            'message': '<h3>New Feature Available</h3><p>Click <a href=\"https://example.com\">here</a> to learn more.</p>',
            'is_html': true,
            'priority': 'high',
            'thumbnail': 'https://example.com/notification-icon.png'
          }
        }
      ]
    }
  };
}
