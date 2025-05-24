import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// A small app to print out all the available WebResourceErrorType values
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('WebResourceErrorType Checker')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: Text('Print WebResourceErrorType values'),
                onPressed: () {
                  printWebResourceErrorTypes();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void printWebResourceErrorTypes() {
    // Get all values of WebResourceErrorType
    print('Available WebResourceErrorType values:');
    for (var type in WebResourceErrorType.values) {
      print('- $type');
    }
  }
}
