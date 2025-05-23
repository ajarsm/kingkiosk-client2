// This is a test file to verify the halo effect functionality after fixing the directionality issue

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/controllers/halo_effect_controller.dart';
import 'app/widgets/halo_effect/halo_effect_overlay.dart';

void main() {
  // Ensure foundational services are registered
  runApp(const TestHaloEffectApp());
}

class TestHaloEffectApp extends StatelessWidget {
  const TestHaloEffectApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Register the HaloEffectController
    final haloController = HaloEffectControllerGetx();
    Get.put(haloController, permanent: true);
    
    // Enable the effect with default parameters
    haloController.enableHaloEffect(color: Colors.red);

    return MaterialApp(
      title: 'Halo Effect Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TestHaloEffectScreen(),
    );
  }
}

class TestHaloEffectScreen extends StatefulWidget {
  const TestHaloEffectScreen({super.key});

  @override
  State<TestHaloEffectScreen> createState() => _TestHaloEffectScreenState();
}

class _TestHaloEffectScreenState extends State<TestHaloEffectScreen> {
  final HaloEffectControllerGetx haloController = Get.find();
  int _currentTest = 0;
  final List<_HaloTest> _tests = [
    _HaloTest(
      name: "Red Border",
      color: Colors.red,
      pulseMode: HaloPulseMode.none,
    ),
    _HaloTest(
      name: "Green Gentle Pulse", 
      color: Colors.green,
      pulseMode: HaloPulseMode.gentle,
      pulseDuration: const Duration(milliseconds: 3000),
    ),
    _HaloTest(
      name: "Blue Moderate Pulse",
      color: Colors.blue,
      pulseMode: HaloPulseMode.moderate,
      pulseDuration: const Duration(milliseconds: 2000),
    ),
    _HaloTest(
      name: "Red Alert",
      color: Colors.red,
      pulseMode: HaloPulseMode.alert,
      pulseDuration: const Duration(milliseconds: 1000),
      intensity: 0.9,
    ),
    _HaloTest(
      name: "Purple Night Mode",
      color: const Color(0xFF9900FF),
      intensity: 0.5,
    ),
    _HaloTest(
      name: "Disabled",
      enabled: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Schedule the auto test
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runCurrentTest();
    });
  }

  void _runCurrentTest() {
    if (_currentTest < _tests.length) {
      final test = _tests[_currentTest];
      print("🧪 Running test: ${test.name}");
      
      if (!test.enabled) {
        haloController.disableHaloEffect();
      } else {
        haloController.enableHaloEffect(
          color: test.color,
          intensity: test.intensity,
          width: test.width,
          pulseMode: test.pulseMode,
          pulseDuration: test.pulseDuration,
        );
      }
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _currentTest++;
            _runCurrentTest();
          });
        }
      });
    }
  }

  void _nextTest() {
    if (_currentTest < _tests.length - 1) {
      setState(() {
        _currentTest++;
        _runCurrentTest();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTestName = _currentTest < _tests.length ? _tests[_currentTest].name : "Tests Complete";
    
    // We use a plain Scaffold wrapped with the AnimatedHaloEffect to avoid duplicate MaterialApp/ScaffoldMessenger issues
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halo Effect Test'),
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Testing Halo Effect Directionality Fix', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 40),
              Text('Current Test: $currentTestName', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Text('Test ${_currentTest + 1} of ${_tests.length}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _nextTest,
                child: const Text('Next Test'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class _HaloTest {
  final String name;
  final Color color;
  final double width;
  final double intensity;
  final bool enabled;
  final HaloPulseMode pulseMode;
  final Duration pulseDuration;

  _HaloTest({
    required this.name,
    this.color = Colors.red,
    this.width = 60.0,
    this.intensity = 0.7,
    this.enabled = true,
    this.pulseMode = HaloPulseMode.none,
    this.pulseDuration = const Duration(milliseconds: 2000),
  });
}
