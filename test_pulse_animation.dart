import 'package:flutter/material.dart';
import 'app/controllers/halo_effect_controller.dart';
import 'app/widgets/halo_effect/halo_effect_overlay.dart';
import 'app/widgets/halo_effect/app_halo_wrapper.dart';
import 'dart:async';

/// Standalone test app for verifying the halo effect pulse animations
void main() {
  runApp(const HaloEffectPulseTest());
}

class HaloEffectPulseTest extends StatelessWidget {
  const HaloEffectPulseTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Halo Effect Pulse Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const HaloPulseTestPage(),
    );
  }
}

class HaloPulseTestPage extends StatefulWidget {
  const HaloPulseTestPage({Key? key}) : super(key: key);

  @override
  State<HaloPulseTestPage> createState() => _HaloPulseTestPageState();
}

class _HaloPulseTestPageState extends State<HaloPulseTestPage> {
  final HaloEffectControllerGetx controller = HaloEffectControllerGetx();
  int currentPulseMode = 0;
  int currentColor = 0;
  bool isEnabled = true;
  String statusText = "Starting...";
  Timer? _cycleTimer;

  final List<Color> testColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];

  final List<Map<String, dynamic>> pulseModes = [
    {
      'name': 'No Pulse',
      'mode': HaloPulseMode.none,
      'duration': const Duration(milliseconds: 0),
    },
    {
      'name': 'Gentle',
      'mode': HaloPulseMode.gentle,
      'duration': const Duration(milliseconds: 2000),
    },
    {
      'name': 'Moderate',
      'mode': HaloPulseMode.moderate,
      'duration': const Duration(milliseconds: 2000),
    },
    {
      'name': 'Alert',
      'mode': HaloPulseMode.alert,
      'duration': const Duration(milliseconds: 1000),
    },
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with the first pulse mode
    _applyCurrentSettings();

    // Set up cycle timer
    _cycleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        // Cycle to next pulse mode
        currentPulseMode = (currentPulseMode + 1) % pulseModes.length;

        // If we've gone through all pulse modes, change the color
        if (currentPulseMode == 0) {
          currentColor = (currentColor + 1) % testColors.length;
        }

        _applyCurrentSettings();
      });
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  void _applyCurrentSettings() {
    final pulseSettings = pulseModes[currentPulseMode];
    final color = testColors[currentColor];

    if (isEnabled) {
      try {
        controller.enableHaloEffect(
          color: color,
          pulseMode: pulseSettings['mode'],
          pulseDuration: pulseSettings['duration'],
          intensity: 0.7,
          width: 60.0,
        );

        statusText =
            "Color: ${_colorName(color)} - Mode: ${pulseSettings['name']}";
        if (pulseSettings['mode'] != HaloPulseMode.none) {
          statusText +=
              " - Duration: ${pulseSettings['duration'].inMilliseconds}ms";
        }

        print('✅ Applied settings: $statusText');
      } catch (e) {
        print('❌ Error applying settings: $e');
        statusText = "Error: $e";
      }
    } else {
      controller.disableHaloEffect();
      statusText = "Halo Effect disabled";
    }
  }

  String _colorName(Color color) {
    if (color == Colors.red) return "Red";
    if (color == Colors.green) return "Green";
    if (color == Colors.blue) return "Blue";
    if (color == Colors.orange) return "Orange";
    if (color == Colors.purple) return "Purple";
    return "Unknown";
  }

  void _toggleEnabled() {
    setState(() {
      isEnabled = !isEnabled;
      _applyCurrentSettings();
    });
  }

  void _manualCycle() {
    setState(() {
      currentPulseMode = (currentPulseMode + 1) % pulseModes.length;
      _applyCurrentSettings();
    });
  }

  void _changeColor() {
    setState(() {
      currentColor = (currentColor + 1) % testColors.length;
      _applyCurrentSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppHaloWrapper(
      controller: controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Halo Effect Pulse Test'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Testing Halo Effect Pulse Animations',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  statusText,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _toggleEnabled,
                    child: Text(isEnabled ? 'Disable' : 'Enable'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _manualCycle,
                    child: const Text('Next Pulse Mode'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _changeColor,
                    child: const Text('Next Color'),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              const Text(
                'Automatic cycling every 5 seconds',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
