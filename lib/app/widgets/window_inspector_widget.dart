import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/window_manager_service.dart';
import '../modules/home/controllers/tiling_window_controller.dart';

/// Window Inspector Widget - Shows all open windows with management options
class WindowInspectorWidget extends StatelessWidget {
  const WindowInspectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final windowManager = Get.find<WindowManagerService>();
    final tilingController = Get.find<TilingWindowController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.view_list,
                    color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Window Inspector',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Window list
            Expanded(
              child: Obx(() {
                final openWindows = windowManager.openWindowNames;
                final tiles = tilingController.tiles;

                if (openWindows.isEmpty && tiles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.desktop_windows,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No open windows',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tiles.length,
                  itemBuilder: (context, index) {
                    final tile = tiles[index];
                    final windowController = windowManager.getWindow(tile.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Window type icon
                                Icon(
                                  _getWindowTypeIcon(tile.type),
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 12),

                                // Window info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tile.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${tile.id}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      if (tile.url.isNotEmpty)
                                        Text(
                                          'URL: ${tile.url}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),

                                // Action buttons
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Copy window ID
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 18),
                                      tooltip: 'Copy Window ID',
                                      onPressed: () => _copyWindowId(tile.id),
                                    ),

                                    // Close window
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 18, color: Colors.red),
                                      tooltip: 'Close Window',
                                      onPressed: () => _closeWindow(tile),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Window status
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatusChip(
                                  'Type: ${tile.type.toString().split('.').last}',
                                  Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                _buildStatusChip(
                                  'Registered: ${windowController != null ? 'Yes' : 'No'}',
                                  windowController != null
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                if (tile.isMaximized) ...[
                                  const SizedBox(width: 8),
                                  _buildStatusChip('Maximized', Colors.purple),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Window Inspector shows all open windows. Click X to close a window or copy icon to copy its ID.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getWindowTypeIcon(dynamic windowType) {
    final typeString = windowType.toString().split('.').last;
    switch (typeString) {
      case 'webView':
        return Icons.web;
      case 'media':
        return Icons.play_circle;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'clock':
        return Icons.access_time;
      case 'weather':
        return Icons.wb_cloudy;
      case 'calendar':
        return Icons.calendar_today;
      case 'alarmo':
        return Icons.security;
      case 'audioVisualizer':
        return Icons.graphic_eq;
      default:
        return Icons.window;
    }
  }

  void _copyWindowId(String windowId) {
    Clipboard.setData(ClipboardData(text: windowId));
    Get.snackbar(
      'Copied',
      'Window ID copied to clipboard: $windowId',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _closeWindow(dynamic tile) {
    final tilingController = Get.find<TilingWindowController>();
    final windowManager = Get.find<WindowManagerService>();

    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Close Window'),
        content: Text('Are you sure you want to close "${tile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close confirmation dialog

              // Close the window
              tilingController.closeTile(tile);

              // Unregister from window manager
              windowManager.unregisterWindow(tile.id);

              Get.snackbar(
                'Window Closed',
                'Closed window: ${tile.name}',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Close Window'),
          ),
        ],
      ),
    );
  }
}
