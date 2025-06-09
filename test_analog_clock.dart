import 'package:flutter/material.dart';
import 'package:animated_analog_clock/animated_analog_clock.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            width: 200,
            height: 200,
            child: AnimatedAnalogClock(
              dialType: DialType.numbers,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
