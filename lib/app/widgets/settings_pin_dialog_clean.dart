import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:number_pad_keyboard/number_pad_keyboard.dart';
import 'controllers/settings_pin_dialog_controller.dart';

/// A reusable PIN dialog for settings access
class SettingsPinDialog extends GetView<SettingsPinDialogController> {
  final String correctPin;
  final String title;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const SettingsPinDialog({
    Key? key,
    required this.correctPin,
    required this.title,
    required this.onSuccess,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller with parameters
    Get.put(SettingsPinDialogController(
      correctPin: correctPin,
      onSuccess: onSuccess,
      onCancel: onCancel,
    ));

    return Obx(() => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Enter PIN to continue',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                // PIN display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < controller.enteredPin.value.length
                            ? controller.isError.value
                                ? Colors.red
                                : Colors.blue
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
                SizedBox(height: 16),
                if (controller.isError.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Incorrect PIN. Try again (${3 - controller.attempts.value} attempts left)',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                // Number pad
                NumberPadKeyboard(
                  addDigit: controller.addDigit,
                  backspace: controller.backspace,
                  onEnter: controller.checkPin,
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: controller.cancel,
                  child: Text('Cancel'),
                ),
              ],
            ),
          ),
        ));
  }
}
