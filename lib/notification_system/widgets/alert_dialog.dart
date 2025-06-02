// lib/notification_system/widgets/alert_dialog.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/notification_models.dart';

/// Center-screen alert dialog that reuses the notification system design
class AlertDialogWidget extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;
  final bool showBorder;
  final Color? borderColor;
  final int? autoDismissSeconds;

  const AlertDialogWidget({
    Key? key,
    required this.notification,
    required this.onDismiss,
    this.showBorder = true,
    this.borderColor,
    this.autoDismissSeconds,
  }) : super(key: key);

  @override
  State<AlertDialogWidget> createState() => _AlertDialogWidgetState();
}

class _AlertDialogWidgetState extends State<AlertDialogWidget>
    with TickerProviderStateMixin {
  late AnimationController? _countdownController;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize auto-dismiss functionality if specified
    if (widget.autoDismissSeconds != null && widget.autoDismissSeconds! > 0) {
      _countdownController = AnimationController(
        duration: Duration(seconds: widget.autoDismissSeconds!),
        vsync: this,
      );
      
      // Start the visual countdown
      _countdownController!.forward();
      
      // Set up auto-dismiss timer
      _autoDismissTimer = Timer(
        Duration(seconds: widget.autoDismissSeconds!),
        widget.onDismiss,
      );
    } else {
      _countdownController = null;
    }
  }

  @override
  void dispose() {
    _countdownController?.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 500,
        minWidth: 300,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),        border: widget.showBorder ? Border.all(
          color: widget.borderColor ?? _getPriorityColor(widget.notification.priority),
          width: 3,
        ) : null,
        boxShadow: [
          if (widget.showBorder) BoxShadow(
            color: (widget.borderColor ?? _getPriorityColor(widget.notification.priority)).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [          // Header with priority indicator and close button
          Container(
            decoration: BoxDecoration(
              color: widget.showBorder ? (widget.borderColor ?? _getPriorityColor(widget.notification.priority)).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                // Priority icon
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    _getPriorityIcon(widget.notification.priority),
                    color: _getPriorityColor(widget.notification.priority),
                    size: 28,
                  ),
                ),
                // Title
                Expanded(
                  child: Text(
                    widget.notification.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(widget.notification.priority),
                    ),
                  ),
                ),
                // Auto-dismiss countdown indicator
                if (_countdownController != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: AnimatedBuilder(
                        animation: _countdownController!,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: 1.0 - _countdownController!.value,
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getPriorityColor(widget.notification.priority),
                            ),
                            backgroundColor: Colors.grey[300],
                          );
                        },
                      ),
                    ),
                  ),
                ],
                // Close button
                IconButton(
                  onPressed: widget.onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Content area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,              children: [
                // Thumbnail if present
                if (widget.notification.thumbnail != null) ...[
                  _buildThumbnail(),
                  const SizedBox(width: 16),
                ],
                
                // Message content
                Expanded(
                  child: _buildContent(context),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,              children: [
                TextButton(
                  onPressed: widget.onDismiss,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildThumbnail() {
    if (widget.notification.thumbnail == null) return const SizedBox.shrink();

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: _buildThumbnailImage(),
      ),
    );
  }

  Widget _buildThumbnailImage() {
    if (widget.notification.thumbnail == null) return const SizedBox.shrink();
    
    final thumbnail = widget.notification.thumbnail!;
    switch (thumbnail.type) {
      case NotificationThumbnailType.network:
        return Image.network(
          thumbnail.source,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      case NotificationThumbnailType.asset:
        return Image.asset(
          thumbnail.source,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      case NotificationThumbnailType.file:
        return Image.file(
          File(thumbnail.source),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
    }
  }

  Widget _buildContent(BuildContext context) {
    if (widget.notification.isHtml) {
      return Html(
        data: widget.notification.message,
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(16),
          ),
        },
        onLinkTap: (url, attributes, element) {
          if (url != null) {
            launchUrlString(url);
          }
        },
      );
    } else {
      return Text(
        widget.notification.message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 16,
        ),
      );
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.blue.shade600; // Info/Success - Blue
      case NotificationPriority.normal:
        return Colors.orange.shade600; // Warning - Orange
      case NotificationPriority.high:
        return Colors.red.shade600; // Error - Red
    }
  }

  IconData _getPriorityIcon(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Icons.info;
      case NotificationPriority.normal:
        return Icons.warning;
      case NotificationPriority.high:
        return Icons.error;
    }
  }
}
