import 'package:get/get.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/bindings/settings_compat_binding.dart';
import '../modules/settings/views/settings_view_fixed.dart';
import '../modules/home/bindings/home_binding_fixed.dart';
import '../modules/home/views/tiling_window_view.dart';
import '../modules/device_test/views/device_test_view.dart';
import '../modules/device_test/bindings/device_test_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/splash/bindings/splash_binding.dart';

// Routes class to replace external part
class Routes {
  Routes._();

  static const SPLASH = '/splash';
  static const HOME = '/home';
  static const SETTINGS = '/settings';
  static const DEVICE_TEST = '/device_test';
}

class AppPagesFixed {
  AppPagesFixed._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const TilingWindowView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => const SettingsViewFixed(),
      binding: BindingsBuilder(() {
        SettingsBinding().dependencies();
        SettingsCompatBinding().dependencies();
      }),
    ),
    GetPage(
      name: Routes.DEVICE_TEST,
      page: () => const DeviceTestView(),
      binding: DeviceTestBinding(),
    ),
  ];
}
