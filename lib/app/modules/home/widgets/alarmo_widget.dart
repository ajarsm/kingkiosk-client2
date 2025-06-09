import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:number_pad_keyboard/number_pad_keyboard.dart';
import '../controllers/alarmo_window_controller.dart';

/// Alarmo dialpad widget that provides native alarm control interface
class AlarmoWidget extends StatelessWidget {
  final String windowId;
  final bool showControls;
  final VoidCallback? onClose;

  const AlarmoWidget({
    Key? key,
    required this.windowId,
    this.showControls = true,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to get existing controller first, create if not found
    AlarmoWindowController controller;
    try {
      controller = Get.find<AlarmoWindowController>(tag: windowId);
    } catch (e) {
      // Controller not found, create a new one
      controller = Get.put(
        AlarmoWindowController(windowName: windowId),
        tag: windowId,
      );
    }

    return Obx(() {
      if (!controller.isVisible) {
        return const SizedBox.shrink();
      }

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Window title bar with controls
            if (showControls) _buildTitleBar(context, controller),

            // Alarmo content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _buildAlarmoContent(context, controller),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTitleBar(
      BuildContext context, AlarmoWindowController controller) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // Window title
          Expanded(
            child: Text(
              'Alarmo - $windowId',
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Minimize button
          IconButton(
            onPressed: controller.minimize,
            icon: const Icon(Icons.minimize, size: 18),
            tooltip: 'Minimize',
          ),

          // Close button
          IconButton(
            onPressed: onClose ?? controller.close,
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmoContent(
      BuildContext context, AlarmoWindowController controller) {
    return Obx(() {
      if (controller.showModeSelection) {
        return _buildModeSelection(context, controller);
      } else {
        return _buildMainDialpad(context, controller);
      }
    });
  }

  Widget _buildMainDialpad(
      BuildContext context, AlarmoWindowController controller) {
    return Column(
      children: [
        // State display
        Expanded(
          flex: 2,
          child: _buildStateDisplay(context, controller),
        ),

        // Code input display
        if (controller.requireCode)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _buildCodeDisplay(context, controller),
          ),

        // Error message
        if (controller.errorMessage != null)
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              controller.errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Number pad keyboard
        Expanded(
          flex: 3,
          child: _buildNumberPad(context, controller),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.only(top: 16),
          child: _buildActionButtons(context, controller),
        ),
      ],
    );
  }

  Widget _buildStateDisplay(
      BuildContext context, AlarmoWindowController controller) {
    return Obx(() {
      final stateColor = controller.getStateColor();
      final stateText = controller.getStateDisplayText();

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: stateColor.withValues(alpha: 0.1),
          border: Border.all(color: stateColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStateIcon(controller.currentState),
              size: 48,
              color: stateColor,
            ),
            const SizedBox(height: 8),
            Text(
              stateText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: stateColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (controller.isLoading)
              Container(
                margin: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCodeDisplay(
      BuildContext context, AlarmoWindowController controller) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(controller.codeLength, (i) {
          final filled = i < controller.enteredCode.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildNumberPad(
      BuildContext context, AlarmoWindowController controller) {
    return NumberPadKeyboard(
      addDigit: controller.addDigit,
      backspace: controller.removeDigit,
      onEnter: controller.executeAction,
      numberStyle: TextStyle(
        fontSize: 24,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      enterButtonColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      enterButtonText: _getActionButtonText(controller),
      deleteColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildActionButtons(
      BuildContext context, AlarmoWindowController controller) {
    return Obx(() {
      return Row(
        children: [
          // Mode selection button (if multiple modes available)
          if (controller.availableModes.length > 1 &&
              controller.currentState == AlarmoState.disarmed)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.toggleModeSelection,
                icon:
                    Icon(controller.getArmModeIcon(controller.selectedArmMode)),
                label: Text(controller
                    .getArmModeDisplayText(controller.selectedArmMode)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),

          if (controller.availableModes.length > 1 &&
              controller.currentState == AlarmoState.disarmed)
            const SizedBox(width: 16),

          // Clear code button
          if (controller.requireCode && controller.enteredCode.isNotEmpty)
            ElevatedButton(
              onPressed: controller.clearCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              child: const Text('Clear'),
            ),

          if (controller.requireCode && controller.enteredCode.isNotEmpty)
            const SizedBox(width: 16),

          // Main action button
          Expanded(
            child: ElevatedButton(
              onPressed: controller.isLoading ? null : controller.executeAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getActionButtonColor(context, controller),
                foregroundColor: _getActionButtonTextColor(context, controller),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _getActionButtonText(controller),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildModeSelection(
      BuildContext context, AlarmoWindowController controller) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select Arm Mode',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        // Mode options
        Expanded(
          child: ListView.builder(
            itemCount: controller.availableModes.length,
            itemBuilder: (context, index) {
              final mode = controller.availableModes[index];
              final isSelected = mode == controller.selectedArmMode;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: isSelected ? 8 : 2,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surface,
                  child: ListTile(
                    leading: Icon(
                      controller.getArmModeIcon(mode),
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    title: Text(
                      controller.getArmModeDisplayText(mode),
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    onTap: () {
                      controller.setArmMode(mode);
                      controller.hideModeSelection();
                      // Immediately arm with selected mode if code is entered
                      if (!controller.requireCode ||
                          controller.enteredCode.length ==
                              controller.codeLength) {
                        controller.executeAction();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),

        // Back button
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.hideModeSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStateIcon(AlarmoState state) {
    switch (state) {
      case AlarmoState.disarmed:
        return Icons.shield_outlined;
      case AlarmoState.arming:
        return Icons.schedule;
      case AlarmoState.armed_away:
        return Icons.shield;
      case AlarmoState.armed_home:
        return Icons.home_outlined;
      case AlarmoState.armed_night:
        return Icons.bedtime;
      case AlarmoState.armed_vacation:
        return Icons.luggage;
      case AlarmoState.armed_custom_bypass:
        return Icons.tune;
      case AlarmoState.pending:
        return Icons.warning;
      case AlarmoState.triggered:
        return Icons.warning;
      case AlarmoState.unavailable:
        return Icons.help_outline;
    }
  }

  String _getActionButtonText(AlarmoWindowController controller) {
    if (controller.currentState == AlarmoState.disarmed) {
      return 'ARM';
    } else {
      return 'DISARM';
    }
  }

  Color _getActionButtonColor(
      BuildContext context, AlarmoWindowController controller) {
    if (controller.currentState == AlarmoState.disarmed) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

  Color _getActionButtonTextColor(
      BuildContext context, AlarmoWindowController controller) {
    if (controller.currentState == AlarmoState.disarmed) {
      return Theme.of(context).colorScheme.onPrimary;
    } else {
      return Theme.of(context).colorScheme.onError;
    }
  }
}
