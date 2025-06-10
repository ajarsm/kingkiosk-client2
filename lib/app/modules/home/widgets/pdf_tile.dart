import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import '../controllers/pdf_tile_controller.dart';

/// A widget that displays a PDF document
class PdfTile extends GetView<PdfTileController> {
  final String url;
  final String windowId;
  final VoidCallback? onClose;

  const PdfTile({
    Key? key,
    required this.url,
    required this.windowId,
    this.onClose,
  }) : super(key: key);

  @override
  String get tag => windowId; // Use windowId as unique tag

  @override
  Widget build(BuildContext context) {
    // Initialize controller with window-specific tag
    Get.put(
        PdfTileController(
          url: url,
          windowId: windowId,
          onCloseCallback: onClose,
        ),
        tag: tag);

    return Obx(() => _buildContent());
  }

  Widget _buildContent() {
    if (controller.isLoading.value) {
      return _buildLoadingWidget();
    }

    if (controller.errorMessage.value != null) {
      return _buildErrorWidget();
    }

    return _buildPdfViewer();
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.red.shade50,
      child: Center(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Failed to load PDF',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  controller.errorMessage.value ?? 'Unknown error',
                  style: TextStyle(color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  onPressed: () => controller.reload(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PdfViewer.uri(
          Uri.parse(url),
          controller: controller.pdfController,
          params: PdfViewerParams(
            backgroundColor: Colors.grey.shade100,
            onDocumentChanged: (document) {
              if (document != null) {
                controller.onPdfReady();
              }
            },
            onViewerReady: (document, controller) {
              // PDF is ready to be viewed
              this.controller.onPdfReady();
            },
          ),
        ),
      ),
    );
  }
}
