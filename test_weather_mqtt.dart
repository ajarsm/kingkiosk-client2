import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  // MQTT Configuration
  final String mqttServer = '192.168.0.199';
  final int mqttPort = 1883;
  final String username = 'alarmpanelgarage';
  final String password = 'alarmpanelgarage';
  final String topic = 'kingkiosk/rajofficemac/command';

  // Create MQTT client
  final client = MqttServerClient(mqttServer, 'weather_test_client');
  client.port = mqttPort;
  client.logging(on: true);
  client.keepAlivePeriod = 20;
  client.onDisconnected = onDisconnected;
  client.onConnected = onConnected;

  // Connect with credentials
  final connMessage = MqttConnectMessage()
      .withClientIdentifier('weather_test_client')
      .authenticateAs(username, password)
      .startClean()
      .withWillQos(MqttQos.atMostOnce);

  client.connectionMessage = connMessage;

  try {
    print('Connecting to MQTT broker at $mqttServer:$mqttPort...');
    await client.connect();
  } catch (e) {
    print('Error connecting to MQTT broker: $e');
    client.disconnect();
    exit(1);
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('✅ Connected to MQTT broker successfully!');

    // Create weather widget command
    final weatherCommand = {
      'command': 'open_weather_client',
      'payload': {
        'window_id': 'weather_test_${DateTime.now().millisecondsSinceEpoch}',
        'window_name': 'Test Weather Widget',
        'api_key': 'YOUR_OPENWEATHER_API_KEY', // You'll need to replace this
        'units': 'metric',
        'language': 'en',
        'show_forecast': true,
        'auto_refresh': true,
        'refresh_interval': 300,
        // Optional: specify location, otherwise it will use device location
        // 'location': 'London,UK',
        // 'latitude': 51.5074,
        // 'longitude': -0.1278,
      }
    };

    final jsonCommand = jsonEncode(weatherCommand);
    print('📤 Sending weather command:');
    print(jsonCommand);

    // Publish the command
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonCommand);

    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print('✅ Weather command sent successfully!');

    // Wait a moment then disconnect
    await Future.delayed(Duration(seconds: 2));
    client.disconnect();
    print('👋 Disconnected from MQTT broker');
  } else {
    print('❌ Failed to connect to MQTT broker');
    client.disconnect();
    exit(1);
  }
}

void onConnected() {
  print('🔗 MQTT client connected');
}

void onDisconnected() {
  print('📤 MQTT client disconnected');
}
