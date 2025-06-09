import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lib/app/modules/home/widgets/clock_widget.dart';
import 'lib/app/modules/home/controllers/clock_window_controller.dart';
import 'lib/app/services/window_manager_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Clock Tile Test',
      home: ClockTestPage(),
      onInit: () {
        // Initialize the WindowManagerService
        Get.put(WindowManagerService());
      },
    );
  }
}

class ClockTestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clock Tile Test'),
      ),
      body: Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClockWidget(
            windowId: 'test-clock-1',
            showControls: true,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "analog",
            onPressed: () {
              final controller =
                  Get.find<ClockWindowController>(tag: 'test-clock-1');
              controller.handleCommand('configure', {
                'mode': 'analog',
                'network_image_url': 'https://picsum.photos/300/300',
                'show_numbers': true,
                'show_second_hand': true,
                'theme': 'auto'
              });
            },
            child: Icon(Icons.access_time),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "digital",
            onPressed: () {
              final controller =
                  Get.find<ClockWindowController>(tag: 'test-clock-1');
              controller.handleCommand('configure', {
                'mode': 'digital',
                'network_image_url': 'https://picsum.photos/300/300?blur=2',
                'theme': 'dark'
              });
            },
            child: Icon(Icons.watch),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "clear",
            onPressed: () {
              final controller =
                  Get.find<ClockWindowController>(tag: 'test-clock-1');
              controller.handleCommand('configure', {
                'mode': 'analog',
                'network_image_url': '',
                'show_numbers': false,
                'show_second_hand': true,
                'theme': 'light'
              });
            },
            child: Icon(Icons.clear),
          ),
        ],
      ),
    );
  }
}
