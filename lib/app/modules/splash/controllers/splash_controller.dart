import 'dart:async';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    // Simulate initialization tasks (loading settings, checking login, etc.)
    await Future.delayed(const Duration(seconds: 2));
    
    isInitialized.value = true;
    
    // Navigate to home screen
    Get.offAllNamed(Routes.HOME);
  }
}