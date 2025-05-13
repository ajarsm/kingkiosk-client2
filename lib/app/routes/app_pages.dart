import 'package:get/get.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view_fixed.dart';
import '../modules/device_test/views/device_test_view.dart';
import '../modules/device_test/bindings/device_test_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => const SettingsViewFixed(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: Routes.DEVICE_TEST,
      page: () => const DeviceTestView(),
      binding: DeviceTestBinding(),
    ),
  ];
}