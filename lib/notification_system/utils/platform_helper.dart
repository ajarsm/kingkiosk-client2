// lib/notification_system/utils/platform_helper.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlatformHelper {
  static bool get isDesktopOS {
    if (kIsWeb) {
      return false;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  static bool isDesktopScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }
  
  static bool get isDesktop {
    if (kIsWeb) {
      return Get.width > 600;
    }
    return isDesktopOS;
  }
}