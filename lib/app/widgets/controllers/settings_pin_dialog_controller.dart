import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/audio_utils.dart';

class SettingsPinDialogController extends GetxController {
  final RxString enteredPin = ''.obs;
  final RxBool isError = false.obs;
  final RxInt attempts = 0.obs;

  final String correctPin;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  SettingsPinDialogController({
    required this.correctPin,
    required this.onSuccess,
    this.onCancel,
  });

  void addDigit(int digit) {
    // Reset error state when user starts typing again
    if (isError.value) {
      isError.value = false;
    }

    // Maximum 4 digits
    if (enteredPin.value.length >= 4) return;

    // Add the digit
    enteredPin.value += digit.toString();

    // Check PIN when 4 digits are entered
    if (enteredPin.value.length == 4) {
      checkPin();
    }
  }

  void backspace() {
    if (enteredPin.value.isNotEmpty) {
      enteredPin.value =
          enteredPin.value.substring(0, enteredPin.value.length - 1);
    }
  }

  void checkPin() async {
    if (enteredPin.value == correctPin) {
      // Play success sound
      await AudioPlayerCompat.playSuccessSound();

      // Close dialog and call success callback
      Get.back();
      onSuccess();
    } else {
      // Play error sound
      await AudioPlayerCompat.playErrorSound();

      // Show error
      isError.value = true;
      attempts.value++;
      enteredPin.value = '';

      // After 3 failed attempts, close dialog
      if (attempts.value >= 3) {
        await Future.delayed(Duration(seconds: 1));
        Get.back();
        if (onCancel != null) {
          onCancel!();
        }
      }
    }
  }

  void cancel() {
    Get.back();
    if (onCancel != null) {
      onCancel!();
    }
  }
}
