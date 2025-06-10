import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import '../controllers/pdf_window_controller.dart';
import '../../../services/window_manager_service.dart';

/// Controller for PdfTile to replace StatefulWidget state management
class PdfTileController extends GetxController {
  final String url;
  final String windowId;
  final VoidCallback? onCloseCallback;

  // Reactive state variables
  final isLoading = true.obs;
  final errorMessage = RxnString(); // RxnString for nullable String
  final pdfReady = false.obs;

  // Non-reactive variables (no need to be reactive)
  late PdfWindowController windowController;
  final pdfController = PdfViewerController();

  PdfTileController({
    required this.url,
    required this.windowId,
    this.onCloseCallback,
  });

  @override
  void onInit() {
    super.onInit();
    _setupWindowController();
    // We'll set loading to false since the PdfViewer.uri handles loading internally
    isLoading.value = false;
  }

  @override
  void onClose() {
    // PdfViewerController doesn't have dispose method
    super.onClose();
  }

  void _setupWindowController() {
    try {
      final wm = Get.find<WindowManagerService>();
      final existingController = wm.getWindow(windowId);

      if (existingController != null &&
          existingController is PdfWindowController) {
        windowController = existingController;
      } else {
        windowController = PdfWindowController(
          windowName: windowId,
          pdfUrl: url,
          onCloseCallback: onCloseCallback,
        );
        wm.registerWindow(windowController);
      }
    } catch (e) {
      print('Error setting up window controller: $e');
      // Create a fallback controller if service isn't available
      windowController = PdfWindowController(
        windowName: windowId,
        pdfUrl: url,
        onCloseCallback: onCloseCallback,
      );
    }
  }

  // Methods for PDF navigation
  void goToFirstPage() {
    pdfController.goToPage(pageNumber: 1);
  }

  void goToLastPage() {
    if (pdfController.isReady) {
      final pageCount = pdfController.pageCount;
      if (pageCount > 0) {
        pdfController.goToPage(pageNumber: pageCount);
      }
    }
  }

  // Handle PDF loading states
  void onPdfReady() {
    pdfReady.value = true;
    isLoading.value = false;
    errorMessage.value = null;
  }

  void onPdfError(String error) {
    isLoading.value = false;
    errorMessage.value = error;
    pdfReady.value = false;
  }

  void reload() {
    isLoading.value = true;
    errorMessage.value = null;
    pdfReady.value = false;
    // The PdfViewer will handle the reload when the widget rebuilds
  }
}
