import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:number_pad_keyboard/number_pad_keyboard.dart';
import '../core/utils/audio_utils.dart';

/// A reusable PIN dialog for settings access
class SettingsPinDialog extends StatefulWidget {
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
  State<SettingsPinDialog> createState() => _SettingsPinDialogState();
}

class _SettingsPinDialogState extends State<SettingsPinDialog> {
  String enteredPin = '';
  bool isError = false;
  int attempts = 0;

  void _addDigit(int digit) {
    // Reset error state when user starts typing again
    if (isError) {
      setState(() {
        isError = false;
      });
    }

    // Maximum 4 digits
    if (enteredPin.length >= 4) return;

    // Add the digit
    setState(() {
      enteredPin += digit.toString();
    });

    // Check PIN when 4 digits are entered
    if (enteredPin.length == 4) {
      _checkPin();
    }
  }

  void _backspace() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      });
    }
  }

  void _checkPin() async {
    if (enteredPin == widget.correctPin) {
      // Play success sound
      await AudioPlayerCompat.playSuccessSound();

      // Close dialog and call success callback
      Get.back();
      widget.onSuccess();
    } else {
      // Play error sound
      await AudioPlayerCompat.playErrorSound();

      // Show error
      setState(() {
        isError = true;
        attempts++;
        enteredPin = '';
      });

      // After 3 failed attempts, close dialog
      if (attempts >= 3) {
        await Future.delayed(Duration(seconds: 1));
        if (mounted) {
          Get.back();
          if (widget.onCancel != null) {
            widget.onCancel!();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
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
                    color: index < enteredPin.length
                        ? isError
                            ? Colors.red
                            : Colors.blue
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            SizedBox(height: 16),
            if (isError)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Incorrect PIN. Try again (${3 - attempts} attempts left)',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            // Number pad
            NumberPadKeyboard(
              addDigit: _addDigit,
              backspace: _backspace,
              onEnter: _checkPin,
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Get.back();
                if (widget.onCancel != null) {
                  widget.onCancel!();
                }
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
