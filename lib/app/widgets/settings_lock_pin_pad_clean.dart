import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:number_pad_keyboard/number_pad_keyboard.dart';
import 'shake_widget.dart';
import 'controllers/settings_lock_pin_pad_controller.dart';

export 'settings_lock_pin_pad.dart' show SettingsLockPinPad;

class SettingsLockPinPad extends GetView<SettingsLockPinPadController> {
  final void Function(String pin) onPinEntered;
  final int pinLength;
  final String? title;
  final String? errorMessage;

  const SettingsLockPinPad({
    Key? key,
    required this.onPinEntered,
    this.pinLength = 4,
    this.title,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller with parameters
    Get.put(SettingsLockPinPadController(
      pinLength: pinLength,
      onPinEntered: onPinEntered,
    ));

    return Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ShakeWidget(
              shake: controller.shake.value,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (i) {
                  final filled = i < controller.enteredPin.value.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Colors.blue : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ),
            if (controller.error.value.isNotEmpty || errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  controller.error.value.isNotEmpty
                      ? controller.error.value
                      : errorMessage ?? '',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: NumberPadKeyboard(
                addDigit: controller.onDigit,
                backspace: controller.onBackspace,
                onEnter: controller.onEnter,
                numberStyle: TextStyle(fontSize: 24, color: Colors.black),
                enterButtonColor: Colors.blue[100],
                enterButtonText: 'OK',
                deleteColor: Colors.black,
              ),
            ),
          ],
        ));
  }
}

// Extension to access controller methods from outside
extension SettingsLockPinPadExtension on SettingsLockPinPad {
  void showError(String error) {
    final controller = Get.find<SettingsLockPinPadController>();
    controller.showError(error);
  }
}
