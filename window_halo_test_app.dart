import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lib/app/controllers/halo_effect_controller.dart';
import 'lib/app/controllers/window_halo_controller.dart';
import 'lib/app/widgets/window_halo_wrapper.dart';
import 'lib/app/widgets/halo_effect/halo_effect_overlay.dart';

/// A simplified test app for window-specific halo effects
void main() {
  runApp(const WindowHaloTestApp());
}

class WindowHaloTestApp extends StatelessWidget {
  const WindowHaloTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Window Halo Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      initialBinding: BindingsBuilder(() {
        // Register controllers
        if (!Get.isRegistered<HaloEffectControllerGetx>()) {
          Get.put<HaloEffectControllerGetx>(HaloEffectControllerGetx(),
              permanent: true);
        }
        if (!Get.isRegistered<WindowHaloController>()) {
          Get.put<WindowHaloController>(WindowHaloController(),
              permanent: true);
        }
      }),
      home: const WindowHaloTestScreen(),
    );
  }
}

class WindowHaloTestScreen extends StatefulWidget {
  const WindowHaloTestScreen({Key? key}) : super(key: key);

  @override
  State<WindowHaloTestScreen> createState() => _WindowHaloTestScreenState();
}

class _WindowHaloTestScreenState extends State<WindowHaloTestScreen> {
  // Track which windows have halos
  final Map<String, bool> _windowHalos = {};
  final Map<String, Color> _windowColors = {};
  final Map<String, HaloPulseMode> _windowPulseModes = {};

  // Window IDs
  final List<String> windowIds = [
    'window_1',
    'window_2',
    'window_3',
    'window_4'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize window states
    for (final id in windowIds) {
      _windowHalos[id] = false;
      _windowColors[id] = Colors.red;
      _windowPulseModes[id] = HaloPulseMode.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Window Halo Test App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            tooltip: 'Enable app-wide halo',
            onPressed: _toggleAppHalo,
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        children: windowIds.map((id) => _buildWindowTile(id)).toList(),
      ),
    );
  }

  Widget _buildWindowTile(String windowId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: WindowHaloWrapper(
        windowId: windowId,
        child: Card(
          elevation: 8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Window $windowId',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Color selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildColorButton(windowId, Colors.red),
                  _buildColorButton(windowId, Colors.blue),
                  _buildColorButton(windowId, Colors.green),
                  _buildColorButton(windowId, Colors.purple),
                ],
              ),
              const SizedBox(height: 16),
              // Pulse mode selection
              DropdownButton<HaloPulseMode>(
                value: _windowPulseModes[windowId],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _windowPulseModes[windowId] = value;
                      _updateWindowHalo(windowId);
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: HaloPulseMode.none,
                    child: Text('No Pulse'),
                  ),
                  DropdownMenuItem(
                    value: HaloPulseMode.gentle,
                    child: Text('Gentle Pulse'),
                  ),
                  DropdownMenuItem(
                    value: HaloPulseMode.moderate,
                    child: Text('Moderate Pulse'),
                  ),
                  DropdownMenuItem(
                    value: HaloPulseMode.alert,
                    child: Text('Alert Pulse'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Toggle halo for this window
              ElevatedButton.icon(
                icon: Icon(_windowHalos[windowId]!
                    ? Icons.visibility
                    : Icons.visibility_off),
                label: Text(
                    _windowHalos[windowId]! ? 'Disable Halo' : 'Enable Halo'),
                onPressed: () => _toggleWindowHalo(windowId),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _windowHalos[windowId]! ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(String windowId, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _windowColors[windowId] = color;
          _updateWindowHalo(windowId);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _windowColors[windowId] == color
                ? Colors.white
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _toggleWindowHalo(String windowId) {
    final windowController = Get.find<WindowHaloController>();
    final newState = !_windowHalos[windowId]!;

    setState(() {
      _windowHalos[windowId] = newState;
    });

    if (newState) {
      windowController.enableHaloForWindow(
        windowId: windowId,
        color: _windowColors[windowId]!,
        pulseMode: _windowPulseModes[windowId],
        pulseDuration: const Duration(milliseconds: 2000),
      );
    } else {
      windowController.disableHaloForWindow(windowId);
    }
  }

  void _updateWindowHalo(String windowId) {
    if (_windowHalos[windowId]!) {
      final windowController = Get.find<WindowHaloController>();
      windowController.enableHaloForWindow(
        windowId: windowId,
        color: _windowColors[windowId]!,
        pulseMode: _windowPulseModes[windowId],
        pulseDuration: const Duration(milliseconds: 2000),
      );
    }
  }

  void _toggleAppHalo() {
    final haloController = Get.find<HaloEffectControllerGetx>();

    if (haloController.enabled.value) {
      haloController.disableHaloEffect();
    } else {
      haloController.enableHaloEffect(
        color: Colors.purple,
        pulseMode: HaloPulseMode.gentle,
        pulseDuration: const Duration(milliseconds: 3000),
      );
    }
  }
}
