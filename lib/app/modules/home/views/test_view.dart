import 'package:flutter/material.dart';

/// A dead simple test view with minimal dependencies
class TestView extends StatelessWidget {
  const TestView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Print debugging info to console
    print("TestView.build called, building basic scaffold");
    
    // Use the absolute simplest widget tree possible - DON'T nest MaterialApp inside GetMaterialApp
    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text('Emergency Test View'),
        backgroundColor: Colors.red,
      ),
      body: Container(
        color: Colors.amber,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'EMERGENCY TEST VIEW',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("Button pressed in test view");
                // No GetX dependency here to avoid any issues
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Button pressed')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Test Button'),
            ),
          ],
        ),
      ),
    );
  }
}