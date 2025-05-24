import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const ErrorTypesApp());
}

class ErrorTypesApp extends StatelessWidget {
  const ErrorTypesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Print all available WebResourceErrorType values
    print('Available WebResourceErrorType values:');
    WebResourceErrorType.values.forEach((type) {
      print('- ${type.toString()}');
    });

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Error Types')),
        body: Center(
          child: Text('Check console output for error types'),
        ),
      ),
    );
  }
}
