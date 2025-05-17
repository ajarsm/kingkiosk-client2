class AppConstants {
  // App Info
  static const String appName = 'King Kiosk';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyIsDarkMode = 'isDarkMode';
  static const String keyWebsocketUrl = 'websocketUrl';
  static const String keyMediaServerUrl = 'mediaServerUrl';
  static const String keyKioskMode = 'kioskMode';
  static const String keyShowSystemInfo = 'showSystemInfo';
  static const String keyKioskStartUrl = 'kioskStartUrl';

  // MQTT Keys
  static const String keyMqttEnabled = 'mqttEnabled';
  static const String keyMqttBrokerUrl = 'mqttBrokerUrl';
  static const String keyMqttBrokerPort = 'mqttBrokerPort';
  static const String keyMqttUsername = 'mqttUsername';
  static const String keyMqttPassword = 'mqttPassword';
  static const String keyDeviceName = 'deviceName';
  static const String keyMqttHaDiscovery =
      'mqttHaDiscovery'; // Enable Home Assistant discovery
  // Wyoming Satellite Keys
  static const String keyWyomingHost = 'wyomingHost';
  static const String keyWyomingPort = 'wyomingPort';
  static const String keyWyomingEnabled = 'wyomingEnabled';

  // Screenshot Keys
  static const String keyLatestScreenshot = 'latestScreenshot';

  // Default values
  static const String defaultWebsocketUrl = 'wss://echo.websocket.org';
  static const String defaultMediaServerUrl = 'https://example.com';
  static const String defaultMqttBrokerUrl = 'broker.emqx.io';
  static const int defaultMqttBrokerPort = 1883;
  static const String defaultKioskStartUrl = 'https://flutter.dev';

  // Media Sample URLs
  static const List<Map<String, String>> sampleMediaItems = [
    {
      'name': 'Big Buck Bunny',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'type': 'video',
    },
    {
      'name': 'Elephant Dream',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'type': 'video',
    },
    {
      'name': 'Sample Audio',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'type': 'audio',
    },
  ];

  // Web Sample URLs
  static const List<Map<String, String>> sampleWebItems = [
    {
      'name': 'Google',
      'url': 'https://www.google.com',
    },
    {
      'name': 'Flutter Dev',
      'url': 'https://flutter.dev',
    },
    {
      'name': 'GitHub',
      'url': 'https://github.com',
    },
  ];

  // API endpoints
  static const String apiBase = 'https://api.example.com';
  static const String apiVersion = 'v1';
}
