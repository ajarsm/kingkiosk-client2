import 'dart:async';
import 'package:flutter/material.dart';

/// A window container that auto-hides its title bar after a period of inactivity
/// and shows it again on hover or touch near the top of the window.
class AutoHideWindow extends StatefulWidget {
  /// The content of the window
  final Widget child;

  /// The title of the window
  final String title;

  /// The icon to display in the title bar
  final IconData? icon;

  /// Callback when the close button is pressed
  final VoidCallback? onClose;

  /// Whether the window is resizable
  final bool isResizable;

  /// Whether the window is initially maximized
  final bool initiallyMaximized;

  /// Duration after which the title bar should auto-hide
  final Duration hideDelay;

  /// Height of the hover detection area at the top of the window
  final double hoverAreaHeight;

  /// Height of the title bar
  final double titleBarHeight;

  const AutoHideWindow({
    Key? key,
    required this.child,
    required this.title,
    this.icon,
    this.onClose,
    this.isResizable = true,
    this.initiallyMaximized = false,
    this.hideDelay = const Duration(seconds: 3),
    this.hoverAreaHeight = 20.0,
    this.titleBarHeight = 40.0,
  }) : super(key: key);

  @override
  State<AutoHideWindow> createState() => _AutoHideWindowState();
}

class _AutoHideWindowState extends State<AutoHideWindow> {
  bool _isHovering = false;
  bool _isTitleBarVisible = true;
  Timer? _hideTimer;
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _isMaximized = widget.initiallyMaximized;
    // Start the auto-hide timer
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.hideDelay, () {
      if (mounted && !_isHovering) {
        setState(() {
          _isTitleBarVisible = false;
        });
      }
    });
  }

  void _showTitleBar() {
    setState(() {
      _isTitleBarVisible = true;
    });
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
        _startHideTimer();
      },
      child: GestureDetector(
        onTap: () {
          // If tapped near the top of the window, show the title bar
          // This is simplified - you might want to check the actual tap position
          _showTitleBar();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10.0,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Hover detection area
              MouseRegion(
                onEnter: (_) {
                  _showTitleBar();
                },
                onHover: (_) {
                  _showTitleBar();
                },
                child: Container(
                  height: widget.hoverAreaHeight,
                  color: Colors.transparent,
                ),
              ),

              // Title bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isTitleBarVisible ? widget.titleBarHeight : 0,
                color: Theme.of(context).primaryColor,
                child: _isTitleBarVisible
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (widget.isResizable)
                              IconButton(
                                icon: Icon(
                                  _isMaximized
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isMaximized = !_isMaximized;
                                  });
                                  // Here you would handle the actual resizing
                                },
                                tooltip: _isMaximized ? 'Restore' : 'Maximize',
                              ),
                            if (widget.onClose != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: widget.onClose,
                                tooltip: 'Close',
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Window content
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}
