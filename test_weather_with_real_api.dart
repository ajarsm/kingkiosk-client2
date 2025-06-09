import 'dart:io';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  print('🌤️ Testing Weather Widget with Real API Key');
  print(
      '📝 NOTE: You need a valid OpenWeatherMap API key from https://openweathermap.org/api');
  print(
      '🔑 Replace "YOUR_REAL_OPENWEATHER_API_KEY" below with your actual API key\n');

  // MQTT Configuration
  final client = MqttServerClient('192.168.0.199', 'dart_weather_test_client');
  client.port = 1883;
  client.logging(on: true);
  client.keepAlivePeriod = 20;
  client.onDisconnected = () => print('❌ MQTT Client disconnected');
  client.onConnected = () => print('✅ MQTT Client connected');

  // Set credentials
  client.connectionMessage = MqttConnectMessage()
      .withClientIdentifier('dart_weather_test_client')
      .withWillTopic('willtopic')
      .withWillMessage('My Will message')
      .startClean()
      .authenticateAs('alarmpanelgarage', 'alarmpanelgarage')
      .withWillQos(MqttQos.atLeastOnce);

  try {
    print('🔄 Connecting to MQTT broker at 192.168.0.199:1883...');
    await client.connect();

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('✅ Connected to MQTT broker successfully!');

      // Weather command with real location (using coordinates for better results)
      final weatherCommand = {
        "command": "open_weather_client",
        "payload": {
          "window_id":
              "weather_with_location_${DateTime.now().millisecondsSinceEpoch}",
          "window_name": "San Francisco Weather",
          "api_key":
              "YOUR_REAL_OPENWEATHER_API_KEY", // 🔑 REPLACE THIS WITH YOUR REAL API KEY
          "latitude": 37.7749, // San Francisco coordinates
          "longitude": -122.4194,
          "units": "metric",
          "language": "en",
          "show_forecast": true,
          "auto_refresh": true,
          "refresh_interval": 300
        }
      };

      // Alternative command using city name
      final weatherCommandByCity = {
        "command": "open_weather_client",
        "payload": {
          "window_id": "weather_city_${DateTime.now().millisecondsSinceEpoch}",
          "window_name": "London Weather",
          "api_key":
              "YOUR_REAL_OPENWEATHER_API_KEY", // 🔑 REPLACE THIS WITH YOUR REAL API KEY
          "location": "London,UK",
          "units": "metric",
          "language": "en",
          "show_forecast": false,
          "auto_refresh": true,
          "refresh_interval": 600
        }
      };

      final topic = 'kingkiosk/rajofficemac/command';

      print('📤 Sending weather command (by coordinates) to topic: $topic');
      final payload1 = MqttClientPayloadBuilder();
      payload1.addString(jsonEncode(weatherCommand));
      client.publishMessage(topic, MqttQos.atLeastOnce, payload1.payload!);

      // Wait a moment before sending the second command
      await Future.delayed(Duration(seconds: 2));

      print('📤 Sending weather command (by city name) to topic: $topic');
      final payload2 = MqttClientPayloadBuilder();
      payload2.addString(jsonEncode(weatherCommandByCity));
      client.publishMessage(topic, MqttQos.atLeastOnce, payload2.payload!);

      print('✅ Weather commands sent successfully!');
      print('');
      print('🔍 What to check next:');
      print('1. Look at the Flutter app - you should see weather tiles');
      print(
          '2. If you see "API key is required" errors, get a real API key from:');
      print('   https://openweathermap.org/api');
      print('3. Replace "YOUR_REAL_OPENWEATHER_API_KEY" in this script');
      print('4. Check the Flutter console for error messages');
    } else {
      print('❌ Failed to connect to MQTT broker');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.disconnect();
    print('🔌 Disconnected from MQTT broker');
  }
}
