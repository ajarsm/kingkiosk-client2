import 'package:get/get.dart';
import '../../services/audio_service_concurrent.dart';

class SettingsLockPinPadController extends GetxController {
  final RxString enteredPin = ''.obs;
  final RxString error = ''.obs;
  final RxBool shake = false.obs;

  final int pinLength;
  final void Function(String pin) onPinEntered;

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
      onPinEntered(enteredPin.value);
      // Parent must call showError('Incorrect PIN') if PIN is wrong
    } else {
      await _triggerError('Enter $pinLength-digit PIN');
    }
  }

  Future<void> _triggerError(String errorMessage) async {
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
    shake.value = false;
  }

  void showError(String errorMessage) {
    _triggerError(errorMessage);
  }
}
