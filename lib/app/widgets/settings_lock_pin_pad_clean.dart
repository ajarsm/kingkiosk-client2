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

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 350, // Limit maximum width
          minWidth: 280, // Ensure minimum width for usability
        ),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Obx(() => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          title!,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
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
                              border: Border.all(
                                color: filled ? Colors.blue : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    if (controller.error.value.isNotEmpty ||
                        errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          controller.error.value.isNotEmpty
                              ? controller.error.value
                              : errorMessage ?? '',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 280, // Constrain the number pad width
                        ),
                        child: NumberPadKeyboard(
                          addDigit: controller.onDigit,
                          backspace: controller.onBackspace,
                          onEnter: controller.onEnter,
                          numberStyle: TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          enterButtonColor: Colors.blue[100],
                          enterButtonText: 'OK',
                          deleteColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}

// Extension to access controller methods from outside
extension SettingsLockPinPadExtension on SettingsLockPinPad {
  void showError(String error) {
    final controller = Get.find<SettingsLockPinPadController>();
    controller.showError(error);
  }
}
