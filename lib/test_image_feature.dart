// A simple test script to verify the image display feature
// Run with: flutter run -t lib/test_image_feature.dart

// import 'dart:convert'; // No longer needed
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/services/background_media_service.dart';
import 'app/services/mqtt_service_consolidated.dart';
import 'app/services/storage_service.dart';
import 'app/services/platform_sensor_service.dart';
import 'app/modules/home/controllers/tiling_window_controller.dart';

void main() {
  runApp(const TestImageFeatureApp());
}

class TestImageFeatureApp extends StatelessWidget {
  const TestImageFeatureApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Image Feature Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const TestImageScreen(),
    );
  }
}

class TestImageScreen extends StatefulWidget {
  const TestImageScreen({Key? key}) : super(key: key);

  @override
  State<TestImageScreen> createState() => _TestImageScreenState();
}

class _TestImageScreenState extends State<TestImageScreen> {
  late BackgroundMediaService mediaService;
  late MqttService mqttService;
  late TilingWindowController windowController;
  bool mqttConnected = false;
  
  // Test image URLs
  final List<String> testImages = [
    'https://picsum.photos/800/600',
    'https://picsum.photos/800/600?random=1',
    'https://picsum.photos/800/600?random=2',
    'https://via.placeholder.com/800x600.png?text=Test+Image',
    'https://http.cat/404', // Error case
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    // Initialize the storage service first (needed by MQTT)
    final storageService = await StorageService().init();
    Get.put(storageService);
    
    // Initialize sensor service (needed by MQTT)
    final sensorService = await PlatformSensorService().init();
    Get.put(sensorService);
    
    // Initialize media service
    mediaService = BackgroundMediaService();
    Get.put(mediaService);
    
    // Initialize window controller
    windowController = TilingWindowController();
    Get.put(windowController);
    
    // Initialize MQTT service
    mqttService = MqttService(storageService, sensorService);
    Get.put(mqttService);
    
    // Set a default device name if not already set
    if (mqttService.deviceName.value.isEmpty) {
      mqttService.deviceName.value = 'test_kiosk';
      await storageService.writeData('device_name', 'test_kiosk');
    }
    
    // Listen for MQTT connection status
    mqttService.isConnected.listen((connected) {
      setState(() {
        mqttConnected = connected;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Display Feature Test'),
        actions: [
          // MQTT connection status indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Obx(() => Icon(
              Icons.cloud,
              color: mqttService.isConnected.value ? Colors.green : Colors.red,
            )),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Test the image display feature',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            // Device name and MQTT status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Obx(() => Text('Device: ${mqttService.deviceName.value}')),
                  const Spacer(),
                  Text('MQTT: ${mqttConnected ? "Connected" : "Disconnected"}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: testImages.length,
                itemBuilder: (context, index) {
                  final imageUrl = testImages[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.error_outline),
                        ),
                      ),
                      title: Text('Test Image ${index + 1}'),
                      subtitle: Text(imageUrl),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showTestOptions(imageUrl);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showTestOptions(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to display image?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL: $imageUrl'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                mediaService.displayImageFullscreen(imageUrl);
              },
              child: const Text('Display Fullscreen'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                mediaService.displayImageWindowed(imageUrl, title: 'Test Image');
              },
              child: const Text('Display Windowed'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Create MQTT command for windowed image
                final mqttCommand = {
                  'command': 'play_media',
                  'url': imageUrl,
                  'type': 'image',
                  'style': 'window',
                  'title': 'MQTT Test Image',
                };
                _sendMqttCommand(mqttCommand);
              },
              child: const Text('Send MQTT Window Command'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Create MQTT command for fullscreen image
                final mqttCommand = {
                  'command': 'play_media',
                  'url': imageUrl,
                  'type': 'image',
                  'style': 'fullscreen',
                };
                _sendMqttCommand(mqttCommand);
              },
              child: const Text('Send MQTT Fullscreen Command'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _sendMqttCommand(Map<String, dynamic> command) {
    if (!mqttService.isConnected.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MQTT not connected. Command not sent.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final deviceName = mqttService.deviceName.value;
    final topic = 'kiosk/$deviceName/command';
    // We're sending the JSON map directly to publishJsonToTopic
    
    try {
      mqttService.publishJsonToTopic(topic, command);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MQTT command sent to $topic'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send MQTT command: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
