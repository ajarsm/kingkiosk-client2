import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

// This file is for testing flutter_html API
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Html(
            data: "<p>Test HTML</p>",
            style: {
              "p": Style(
                  // Check what types are expected here
                  )
            },
          ),
        ),
      ),
    );
  }
}
