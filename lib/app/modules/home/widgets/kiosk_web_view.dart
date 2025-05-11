import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class KioskWebView extends StatefulWidget {
  final String url;
  final bool isMaximized;
  
  const KioskWebView({
    Key? key,
    required this.url,
    this.isMaximized = true,
  }) : super(key: key);

  @override
  State<KioskWebView> createState() => _KioskWebViewState();
}

class _KioskWebViewState extends State<KioskWebView> {
  final isLoading = true.obs;
  final HomeController homeController = Get.find<HomeController>();
  
  @override
  void initState() {
    super.initState();
    // Simulate loading delay
    Future.delayed(Duration(milliseconds: 1000), () {
      isLoading.value = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        Center(
          child: Obx(() => isLoading.value
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.web, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('Kiosk Mode Active', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 8),
                  Text('Configured URL: ${widget.url}', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 24),
                  Text('In a real WebView, this would load the URL'),
                ],
              )
          ),
        ),
        
        // Exit kiosk mode button
        Positioned(
          top: 10,
          right: 10,
          child: Opacity(
            opacity: 0.7,
            child: FloatingActionButton.small(
              backgroundColor: Colors.red,
              child: const Icon(Icons.close),
              onPressed: () {
                homeController.closeMaximizedWebView();
              },
            ),
          ),
        ),
      ],
    );
  }
}