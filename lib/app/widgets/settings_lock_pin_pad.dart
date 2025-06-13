import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:number_pad_keyboard/number_pad_keyboard.dart';
im                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 260, // Further reduced number pad width
                      ),
                      child: NumberPadKeyboard(
                        addDigit: _controller.onDigit,
                        backspace: _controller.onBackspace,
                        onEnter: _controller.onEnter,
                        numberStyle: TextStyle(
                          fontSize: 20, // Reduced font size
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        enterButtonColor: Colors.blue[100],
                        enterButtonText: 'OK', // Changed from default "ENTER" to "OK"
                        deleteColor: Colors.black,
                      ),
                    ),.dart';
import 'controllers/settings_lock_pin_pad_controller.dart';

export 'settings_lock_pin_pad.dart'
    show SettingsLockPinPad, SettingsLockPinPadState;

class SettingsLockPinPad extends StatefulWidget {
  final Function(String pin) onPinEntered;
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
  State<SettingsLockPinPad> createState() => SettingsLockPinPadState();
}

class SettingsLockPinPadState extends State<SettingsLockPinPad> {
  late final SettingsLockPinPadController _controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    // Create a unique tag for this instance to avoid conflicts
    _controllerTag =
        'pin_pad_${DateTime.now().millisecondsSinceEpoch}_${hashCode}';

    // Create and register the controller with a unique tag
    _controller = SettingsLockPinPadController(
      pinLength: widget.pinLength,
      onPinEntered: widget.onPinEntered,
    );
    Get.put(_controller, tag: _controllerTag);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    try {
      if (Get.isRegistered<SettingsLockPinPadController>(tag: _controllerTag)) {
        Get.delete<SettingsLockPinPadController>(tag: _controllerTag);
      }
    } catch (e) {
      print('Error disposing PIN pad controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Check if controller is still registered and not closed
      if (!Get.isRegistered<SettingsLockPinPadController>(
              tag: _controllerTag) ||
          _controller.isClosed) {
        return Container(); // Return empty container if controller is disposed
      }

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        widget.title!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ShakeWidget(
                    shake: _controller.shake.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.pinLength, (i) {
                        final filled = i < _controller.enteredPin.value.length;
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
                  if (_controller.error.value.isNotEmpty ||
                      widget.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _controller.error.value.isNotEmpty
                            ? _controller.error.value
                            : widget.errorMessage ?? '',
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
                        addDigit: _controller.onDigit,
                        backspace: _controller.onBackspace,
                        onEnter: _controller.onEnter,
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
              ),
            ),
          ),
        ),
      );
    });
  }

  // Method to show error from outside the widget
  void showError(String error) {
    try {
      if (mounted && !_controller.isClosed) {
        _controller.showError(error);
      }
    } catch (e) {
      print('Error showing PIN error: $e');
    }
  }
}
