import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sip_ua/sip_ua.dart';
import '../services/storage_service.dart';
import '../core/utils/app_constants.dart';
import '../services/sip_service.dart';

/// Service for handling AI assistant calls
class AiAssistantService extends GetxService {
  // Dependencies
  final SipService _sipService;
  final StorageService _storageService;

  // Reactive state
  final isAiEnabled = false.obs;
  final aiProviderHost = ''.obs;
  final isAiCallActive = false.obs;
  final aiCallState = ''.obs;

  // Constructor
  AiAssistantService(this._sipService, this._storageService) {
    // Load settings
    _loadSettings();

    // Listen for call state changes
    ever(_sipService.callState, _onCallStateChanged);
    ever(_sipService.currentCall, _onCurrentCallChanged);
  }

  /// Initialize the service
  Future<AiAssistantService> init() async {
    try {
      debugPrint('Initializing AI Assistant Service');

      // Verify SIP service is correctly initialized
      if (_sipService.isRegistered.value) {
        debugPrint('SIP service is registered and ready for AI assistant');
      } else {
        debugPrint(
            'SIP service not registered yet, AI calls may not work until SIP registers');

        // Set up a one-time listener to detect when SIP registers
        ever(_sipService.isRegistered, (bool registered) {
          if (registered) {
            debugPrint('SIP service now registered, AI assistant ready');
            // Notify user if AI is enabled
            if (isAiEnabled.value) {
              Get.snackbar(
                'AI Assistant',
                'AI assistant is now ready',
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 2),
              );
            }
          }
        }, condition: (registered) => registered == true);
      }

      debugPrint('AI Assistant Service initialized successfully');
      return this;
    } catch (e) {
      debugPrint('Error during AI Assistant Service initialization: $e');
      return this;
    }
  }

  /// Load AI settings from storage
  void _loadSettings() {
    isAiEnabled.value =
        _storageService.read<bool>(AppConstants.keyAiEnabled) ?? false;
    aiProviderHost.value =
        _storageService.read<String>(AppConstants.keyAiProviderHost) ?? '';
  }

  /// Public method to reload AI settings from storage
  void reloadSettings() {
    _loadSettings();
  }

  /// Handle call state changes
  void _onCallStateChanged(String state) {
    if (isAiCallActive.value) {
      aiCallState.value = state;
      debugPrint('AI call state changed to: $state');

      // Update state based on SIP call state
      switch (state) {
        case 'connecting':
        case 'progress':
          Get.snackbar(
            'AI Assistant',
            'Connecting to AI assistant...',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 2),
          );
          break;
        case 'connected':
        case 'confirmed':
          Get.snackbar(
            'AI Assistant',
            'Connected to AI assistant',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.7),
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
          break;
        case 'failed':
          Get.snackbar(
            'AI Assistant',
            'Call failed to connect',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.7),
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
          isAiCallActive.value = false;
          break;
        case 'ended':
          Get.snackbar(
            'AI Assistant',
            'Call ended',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 2),
          );
          isAiCallActive.value = false;
          break;
      }
    }
  }

  /// Handle current call changes
  void _onCurrentCallChanged(Call? call) {
    if (call == null) {
      isAiCallActive.value = false;
      aiCallState.value = '';
    }
  }

  /// Dial the AI assistant
  Future<bool> callAiAssistant() async {
    try {
      // Check if AI is enabled and configured
      if (!isAiEnabled.value) {
        debugPrint('AI assistant not enabled');
        Get.snackbar(
          'Cannot Call AI',
          'AI assistant is not enabled. Please enable it in settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }

      if (aiProviderHost.value.isEmpty) {
        debugPrint('AI assistant not configured with a host');
        Get.snackbar(
          'Cannot Call AI',
          'AI assistant is not configured. Please add an AI provider in settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }

      // Check if SIP is registered
      if (!_sipService.isRegistered.value) {
        debugPrint('Cannot call AI: SIP not registered');
        Get.snackbar(
          'Cannot Call AI',
          'SIP service is not registered. Please check your SIP settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }

      // Check if there's already an ongoing call
      if (_sipService.currentCall.value != null) {
        debugPrint('Cannot call AI: Already in a call');
        Get.snackbar(
          'Cannot Call AI',
          'Already in a call. End the current call first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }

      // Make the call to AI provider
      debugPrint('Calling AI assistant at ${aiProviderHost.value}');

      // Show connecting message before attempting call
      Get.snackbar(
        'AI Assistant',
        'Connecting to AI assistant...',
        snackPosition: SnackPosition.BOTTOM,
      );

      final success =
          await _sipService.makeCall(aiProviderHost.value, video: false);

      if (success) {
        isAiCallActive.value = true;
        aiCallState.value = 'connecting';
        return true;
      } else {
        // This means the makeCall method failed
        isAiCallActive.value = false;
        aiCallState.value = 'failed';
        debugPrint('Failed to initiate call to AI assistant');

        Get.snackbar(
          'Call Failed',
          'Could not connect to AI assistant',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );

        return false;
      }
    } catch (e) {
      debugPrint('Error calling AI assistant: $e');

      // Reset state in case of error
      isAiCallActive.value = false;
      aiCallState.value = 'failed';

      Get.snackbar(
        'Error',
        'Failed to call AI assistant: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// End the current AI call
  Future<bool> endAiCall() async {
    try {
      if (!isAiCallActive.value || _sipService.currentCall.value == null) {
        debugPrint('No active AI call to end');
        return false;
      }

      _sipService.currentCall.value!.hangup();
      isAiCallActive.value = false;
      aiCallState.value = 'ended';
      return true;
    } catch (e) {
      debugPrint('Error ending AI call: $e');
      return false;
    }
  }

  /// Toggle mute state of the current AI call
  Future<bool> toggleMuteAiCall() async {
    try {
      if (!isAiCallActive.value || _sipService.currentCall.value == null) {
        debugPrint('No active AI call to mute/unmute');
        return false;
      }

      // Toggle mute state using SIP service
      _sipService.toggleMute();

      return true;
    } catch (e) {
      debugPrint('Error toggling mute state: $e');
      return false;
    }
  }
}
