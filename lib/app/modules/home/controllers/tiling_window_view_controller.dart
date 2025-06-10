import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../services/ai_assistant_service.dart';

/// Controller for TilingWindowView to replace StatefulWidget state management
class TilingWindowViewController extends GetxController {
  // Reactive state that was previously managed with setState
  final isAiAssistantAvailable = false.obs;

  // Optional reference to AI assistant service
  AiAssistantService? aiAssistantService;

  @override
  void onInit() {
    super.onInit();
    _initializeAiAssistant();
  }

  /// Initialize AI Assistant service with reactive updates
  void _initializeAiAssistant() {
    try {
      aiAssistantService = Get.find<AiAssistantService>();
      isAiAssistantAvailable.value = true;
    } catch (e) {
      // AI Assistant service may not be ready yet
      debugPrint('AI Assistant service not available yet: $e');

      // Set up delayed retry with reactive update
      Future.delayed(Duration(seconds: 3), () {
        try {
          aiAssistantService = Get.find<AiAssistantService>();
          isAiAssistantAvailable.value =
              true; // This will automatically update UI
        } catch (e) {
          debugPrint('Still cannot find AI Assistant service: $e');
        }
      });
    }
  }

  /// Refresh AI Assistant availability
  void refreshAiAssistant() {
    _initializeAiAssistant();
  }
}
