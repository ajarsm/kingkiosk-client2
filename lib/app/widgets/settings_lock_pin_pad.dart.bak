import 'package:flutter/material.dart';
import 'package:number_pad_keyboard/number_pad_keyboard.dart';
import '../services/audio_service_concurrent.dart';
import 'shake_widget.dart';

export 'settings_lock_pin_pad.dart'
    show SettingsLockPinPad, SettingsLockPinPadState;

class SettingsLockPinPad extends StatefulWidget {
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
  SettingsLockPinPadState createState() => SettingsLockPinPadState();
}

class SettingsLockPinPadState extends State<SettingsLockPinPad> {
  String _enteredPin = '';
  String? _error;
  bool _shake = false;

  void _onDigit(int digit) {
    if (_enteredPin.length < widget.pinLength) {
      setState(() {
        _enteredPin += digit.toString();
        _error = null;
      });
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _error = null;
      });
    }
  }

  void _onEnter() async {
    if (_enteredPin.length == widget.pinLength) {
      widget.onPinEntered(_enteredPin);
      // Parent must call showError('Incorrect PIN') if PIN is wrong
    } else {
      await _triggerError('Enter ${widget.pinLength}-digit PIN');
    }
  }

  Future<void> _triggerError(String error) async {
    // Play error sound using AudioService concurrently with animation
    try {
      // Call error sound without awaiting to allow concurrent execution with animation
      AudioServiceConcurrent.playErrorConcurrent();
    } catch (_) {}

    setState(() {
      _error = error;
      _enteredPin = '';
      _shake = true;
    });

    // Reset shake state after animation completes
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _shake = false;
    });
  }

  void showError(String error) {
    _triggerError(error);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ShakeWidget(
          shake: _shake,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pinLength, (i) {
              final filled = i < _enteredPin.length;
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
        if (_error != null || widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              _error ?? widget.errorMessage ?? '',
              style: TextStyle(color: Colors.red),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: NumberPadKeyboard(
            addDigit: _onDigit,
            backspace: _onBackspace,
            onEnter: _onEnter,
            numberStyle: TextStyle(fontSize: 24, color: Colors.black),
            enterButtonColor: Colors.blue[100],
            enterButtonText: 'OK',
            deleteColor: Colors.black,
          ),
        ),
      ],
    );
  }
}
