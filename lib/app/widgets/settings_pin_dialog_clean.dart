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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 320, // Reduced max width to prevent overflow
              maxHeight: MediaQuery.of(context).size.height * 0.8, // Max height
            ),
            child: IntrinsicWidth(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0), // Reduced padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18, // Reduced font size
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12), // Reduced spacing
                    Text(
                      'Enter PIN to continue',
                      style: TextStyle(
                        fontSize: 14, // Reduced font size
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20), // Reduced spacing
                    // PIN display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 8), // Reduced margin
                          width: 18, // Reduced size
                          height: 18, // Reduced size
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < controller.enteredPin.value.length
                                ? controller.isError.value
                                    ? Colors.red
                                    : Colors.blue
                                : Colors.grey.shade300,
                            border: Border.all(
                              color: index < controller.enteredPin.value.length
                                  ? controller.isError.value
                                      ? Colors.red
                                      : Colors.blue
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 16), // Reduced spacing
                    if (controller.isError.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16), // Reduced spacing
                        child: Text(
                          'Incorrect PIN. Try again (${3 - controller.attempts.value} attempts left)',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12, // Reduced font size
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Number pad with constraints
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: 260, // Further reduced number pad width
                      ),
                      child: NumberPadKeyboard(
                        addDigit: controller.addDigit,
                        backspace: controller.backspace,
                        onEnter: controller.checkPin,
                        numberStyle: TextStyle(
                          fontSize: 20, // Reduced font size
                          fontWeight: FontWeight.w600,
                        ),
                        enterButtonText: 'OK', // Changed from default "ENTER" to "OK"
                      ),
                    ),
                    SizedBox(height: 16), // Reduced spacing
                    TextButton(
                      onPressed: controller.cancel,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Reduced padding
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14), // Reduced font size
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
