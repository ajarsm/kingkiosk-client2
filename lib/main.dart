import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/foundation.dart';

import 'app/routes/app_pages.dart';
import 'app/core/bindings/initial_binding.dart';
import 'app/core/theme/app_theme.dart';

void main() {
  // Make zone errors fatal in debug mode to catch these issues early
  if (kDebugMode) {
    BindingBase.debugZoneErrorsAreFatal = true;
  }
  
  // Run everything in the same zone
  runZonedGuarded(() async {
    // Ensure Flutter is initialized (in the same zone as runApp)
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize MediaKit
    MediaKit.ensureInitialized();
    
    // Initialize GetStorage
    await GetStorage.init();
    
    // Initialize services
    InitialBinding().dependencies();
    
    runApp(
      GetMaterialApp(
        title: 'Flutter GetX Kiosk',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        debugShowCheckedModeBanner: false,
        // Ensure that directionality is properly set
        textDirection: TextDirection.ltr,
        defaultTransition: Transition.fade,
      ),
    );
  }, (error, stackTrace) {
    // Log error but don't use notifications during startup
    print('ERROR: $error');
    print('STACK TRACE: $stackTrace');
  });
}