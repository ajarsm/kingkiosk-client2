import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/tiling_window_controller.dart';
import '../../../controllers/app_state_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register home controller - ensuring dependencies are already available
    // from the InitialBinding that runs first
    
    // Make sure AppStateController is available
    if (!Get.isRegistered<AppStateController>()) {
      print('Warning: AppStateController not registered - it should be registered in InitialBinding');
    }
    
    // Register home controller
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    
    // Register TilingWindowController for the tiling view
    Get.lazyPut<TilingWindowController>(() => TilingWindowController(), fenix: true);
  }
}
