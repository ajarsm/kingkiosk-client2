import 'package:get/get.dart';
import '../../services/audio_service_concurrent.dart';

class SettingsLockPinPadController extends GetxController {
  final RxString enteredPin = ''.obs;
  final RxString error = ''.obs;
  final RxBool shake = false.obs;

  final int pinLength;
  final Function(String pin) onPinEntered;

  SettingsLockPinPadController({
    required this.pinLength,
    required this.onPinEntered,
  });

  void onDigit(int digit) {
    if (enteredPin.value.length < pinLength) {
      enteredPin.value += digit.toString();
      error.value = '';
    }
  }

  void onBackspace() {
    if (enteredPin.value.isNotEmpty) {
      enteredPin.value =
          enteredPin.value.substring(0, enteredPin.value.length - 1);
      error.value = '';
    }
  }

  Future<void> onEnter() async {
    if (enteredPin.value.length == pinLength) {
      // Save current context and state before async operations
      final currentPin = enteredPin.value;

      try {
        // Check if controller is still active before executing callback
        if (!isClosed) {
          // Execute the callback directly but handle any errors
          await onPinEntered(currentPin);
        }
      } catch (e) {
        print('Error in PIN callback: $e');
        // If there's an error and controller is still active, treat it as wrong PIN
        if (!isClosed) {
          await _triggerError('Navigation error occurred');
        }
      }
      // Parent must call showError('Incorrect PIN') if PIN is wrong
    } else {
      await _triggerError('Enter $pinLength-digit PIN');
    }
  }

  Future<void> _triggerError(String errorMessage) async {
    // Check if controller is still active before modifying state
    if (isClosed) return;

    // Play error sound using AudioService concurrently with animation
    try {
      // Call error sound without awaiting to allow concurrent execution with animation
      AudioServiceConcurrent.playErrorConcurrent();
    } catch (_) {}

    error.value = errorMessage;
    enteredPin.value = '';
    shake.value = true;

    // Reset shake state after animation completes
    await Future.delayed(const Duration(milliseconds: 500));

    // Check again if controller is still active before updating shake state
    if (!isClosed) {
      shake.value = false;
    }
  }

  void showError(String errorMessage) {
    // Only trigger error if controller is still active
    if (!isClosed) {
      _triggerError(errorMessage);
    }
  }
}
