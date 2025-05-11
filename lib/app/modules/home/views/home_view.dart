import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../widgets/kiosk_web_view.dart';
import 'tiling_window_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => controller.isMaximizedWebViewActive.value
        ? _buildKioskView()
        : _buildTilingView(),
      ),
    );
  }
  
  Widget _buildKioskView() {
    return KioskWebView(
      url: controller.currentWebViewUrl.value,
      isMaximized: true,
    );
  }
  
  Widget _buildTilingView() {
    return const TilingWindowView();
  }
}