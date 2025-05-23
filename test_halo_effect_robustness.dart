import 'package:flutter/material.dart';
import 'app/controllers/halo_effect_controller.dart';
import 'app/widgets/halo_effect/halo_effect_overlay.dart';
import 'app/widgets/halo_effect/app_halo_wrapper.dart';
import 'dart:async';

/// Test script to verify the robustness of halo effect implementation
/// This test deliberately introduces edge cases to verify error handling
void main() {
  runApp(const HaloEffectRobustnessTest());
}

class HaloEffectRobustnessTest extends StatelessWidget {
  const HaloEffectRobustnessTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Halo Effect Robustness Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const HaloEffectTestPage(),
    );
  }
}

class HaloEffectTestPage extends StatefulWidget {
  const HaloEffectTestPage({Key? key}) : super(key: key);

  @override
  State<HaloEffectTestPage> createState() => _HaloEffectTestPageState();
}

class _HaloEffectTestPageState extends State<HaloEffectTestPage> {
  final HaloEffectControllerGetx controller = HaloEffectControllerGetx();
  String testStatus = 'Ready to start tests';
  int currentTestIndex = -1;
  late Timer testTimer;

  // Define test cases that intentionally test edge cases
  final List<Map<String, dynamic>> tests = [
    {
      'name': 'Standard Red',
      'config': {'color': Colors.red, 'width': 60.0, 'intensity': 0.7},
      'description': 'Basic test with standard parameters'
    },
    {
      'name': 'Invalid Width (negative)',
      'config': {'color': Colors.blue, 'width': -10.0, 'intensity': 0.5},
      'description': 'Testing with invalid negative width'
    },
    {
      'name': 'Invalid Width (zero)',
      'config': {'color': Colors.green, 'width': 0.0, 'intensity': 0.6},
      'description': 'Testing with invalid zero width'
    },
    {
      'name': 'Invalid Width (NaN)',
      'config': {'color': Colors.yellow, 'width': double.nan, 'intensity': 0.5},
      'description': 'Testing with NaN width'
    },
    {
      'name': 'Invalid Intensity (negative)',
      'config': {'color': Colors.purple, 'width': 80.0, 'intensity': -0.3},
      'description': 'Testing with invalid negative intensity'
    },
    {
      'name': 'Invalid Intensity (too high)',
      'config': {'color': Colors.orange, 'width': 70.0, 'intensity': 1.5},
      'description': 'Testing with invalid high intensity'
    },
    {
      'name': 'Invalid Intensity (NaN)',
      'config': {'color': Colors.teal, 'width': 50.0, 'intensity': double.nan},
      'description': 'Testing with NaN intensity'
    },
    {
      'name': 'Invalid Color (transparent)',
      'config': {'color': Colors.transparent, 'width': 60.0, 'intensity': 0.7},
      'description': 'Testing with transparent color'
    },
    {
      'name': 'Pulsing with Invalid Duration',
      'config': {
        'color': Colors.pink,
        'width': 75.0,
        'intensity': 0.8,
        'pulseMode': HaloPulseMode.moderate,
        'pulseDuration': const Duration(milliseconds: 0)
      },
      'description': 'Testing pulse mode with invalid duration'
    },
    {
      'name': 'Very Large Width',
      'config': {'color': Colors.indigo, 'width': 500.0, 'intensity': 0.6},
      'description': 'Testing with extremely large width'
    },
    {
      'name': 'Alert Pulse Mode',
      'config': {
        'color': Colors.red,
        'width': 60.0,
        'intensity': 0.9,
        'pulseMode': HaloPulseMode.alert,
        'pulseDuration': const Duration(milliseconds: 1000)
      },
      'description': 'Testing with alert pulse mode'
    },
    {
      'name': 'Gentle Pulse Mode',
      'config': {
        'color': Colors.lightBlue,
        'width': 60.0,
        'intensity': 0.7,
        'pulseMode': HaloPulseMode.gentle,
        'pulseDuration': const Duration(milliseconds: 3000)
      },
      'description': 'Testing with gentle pulse mode'
    },
    {
      'name': 'Disable Effect',
      'config': {'enabled': false},
      'description': 'Testing disabling the effect'
    },
  ];

  @override
  void initState() {
    super.initState();

    // Set a delay before starting the tests
    Future.delayed(const Duration(seconds: 2), () {
      startTests();
    });
  }

  void startTests() {
    setState(() {
      testStatus = 'Starting tests...';
    });

    testTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      currentTestIndex++;

      if (currentTestIndex >= tests.length) {
        timer.cancel();
        setState(() {
          testStatus = 'All tests completed successfully';
          // Disable the halo effect at the end
          controller.disableHaloEffect();
        });
        return;
      }

      final test = tests[currentTestIndex];
      setState(() {
        testStatus =
            'Running test ${currentTestIndex + 1}/${tests.length}: ${test['name']}';
      });

      try {
        if (test['config']['enabled'] == false) {
          controller.disableHaloEffect();
        } else {
          controller.enableHaloEffect(
            color: test['config']['color'],
            width: test['config']['width'],
            intensity: test['config']['intensity'],
            pulseMode: test['config']['pulseMode'] ?? HaloPulseMode.none,
            pulseDuration: test['config']['pulseDuration'],
          );
        }
        print('✅ Test "${test['name']}" applied successfully');
      } catch (e) {
        print('❌ Error in test "${test['name']}": $e');
        // Continue with next test despite errors
      }
    });
  }

  @override
  void dispose() {
    testTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppHaloWrapper(
      controller: controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Halo Effect Robustness Test'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Testing Halo Effect Robustness',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                testStatus,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              if (currentTestIndex >= 0 && currentTestIndex < tests.length)
                _buildCurrentTestInfo(),
              const SizedBox(height: 20),
              Text(
                'Test ${currentTestIndex + 1} of ${tests.length}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTestInfo() {
    final test = tests[currentTestIndex];
    return Container(
      width: 600,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test: ${test['name']}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Description: ${test['description']}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            'Parameters:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTestParameters(test['config']),
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  String _formatTestParameters(Map<String, dynamic> config) {
    String result = '';
    config.forEach((key, value) {
      if (value is Color) {
        result +=
            '$key: Color(0x${value.value.toRadixString(16).padLeft(8, '0')})\n';
      } else {
        result += '$key: $value\n';
      }
    });
    return result;
  }
}
