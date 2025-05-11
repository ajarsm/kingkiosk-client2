import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_state_controller.dart';

/// A global loading overlay that can be shown/hidden from anywhere in the app
class LoadingOverlay extends StatelessWidget {
  final Widget child;

  const LoadingOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppStateController appStateController = Get.find<AppStateController>();

    return Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          // Fix directionality issue by using standard Alignment
          alignment: Alignment.center,
          children: [
            // Main content
            child,
            
            // Loading overlay
            Obx(() {
              final isLoading = appStateController.isLoading.value;
              final message = appStateController.loadingMessage.value;
              
              return Visibility(
                visible: isLoading,
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            if (message.isNotEmpty) ...[
                              SizedBox(height: 16),
                              Text(
                                message,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}