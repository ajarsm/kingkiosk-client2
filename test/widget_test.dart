// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_kiosk/app/modules/splash/views/splash_view.dart';

void main() {
  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      GetMaterialApp(
        home: Directionality( // Add Directionality to avoid test errors
          textDirection: TextDirection.ltr,
          child: SplashView(),
        ),
      ),
    );

    // Verify that the splash screen appears
    expect(find.byType(SplashView), findsOneWidget);
  });
}
