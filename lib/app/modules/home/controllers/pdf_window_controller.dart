import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/window_manager_service.dart';

/// Controller for PDF window tiles
class PdfWindowController extends GetxController
    implements KioskWindowController {
  @override
  final String windowName;
  final String pdfUrl;
  final VoidCallback? onCloseCallback;

  @override
  KioskWindowType get windowType => KioskWindowType.custom;

  // Observable for current page
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 0.obs;

  PdfWindowController({
    required this.windowName,
    required this.pdfUrl,
    this.onCloseCallback,
  });

  @override
  void handleCommand(String action, Map<String, dynamic>? payload) {
    // Handle PDF-specific commands here
    switch (action.toLowerCase()) {
      case 'next_page':
        nextPage();
        break;
      case 'previous_page':
        previousPage();
        break;
      case 'go_to_page':
        if (payload != null && payload['page'] != null) {
          final page = int.tryParse(payload['page'].toString());
          if (page != null) {
            goToPage(page);
          }
        }
        break;
      case 'close':
        // Handle window closure
        disposeWindow();
        break;
    }
  }

  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      print('📄 [PDF] Moving to next page: ${currentPage.value}');
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      print('📄 [PDF] Moving to previous page: ${currentPage.value}');
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      print('📄 [PDF] Going to page: $page');
    }
  }

  void setTotalPages(int pages) {
    totalPages.value = pages;
    print('📄 [PDF] Total pages set to: $pages');
  }

  @override
  void disposeWindow() {
    if (onCloseCallback != null) {
      onCloseCallback!();
    }
    // Additional cleanup if needed
  }
}
