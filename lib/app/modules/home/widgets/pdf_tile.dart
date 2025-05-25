import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import '../controllers/pdf_window_controller.dart';
import '../../../services/window_manager_service.dart';

/// A widget that displays a PDF document
class PdfTile extends StatefulWidget {
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
  _PdfTileState createState() => _PdfTileState();
}

class _PdfTileState extends State<PdfTile> {
  late PdfWindowController windowController;
  bool isLoading = true;
  String? errorMessage;
  final pdfController = PdfViewerController();
  bool pdfReady = false;

  @override
  void initState() {
    super.initState();
    // Setup window controller
    _setupWindowController();

    // We'll set loading to false since the PdfViewer.uri handles loading internally
    setState(() {
      isLoading = false;
    });
  }

  void _setupWindowController() {
    try {
      final wm = Get.find<WindowManagerService>();
      final existingController = wm.getWindow(widget.windowId);

      if (existingController != null &&
          existingController is PdfWindowController) {
        windowController = existingController;
      } else {
        // Create a new controller and register it with the window manager
        windowController = PdfWindowController(
          windowName: widget.windowId,
          pdfUrl: widget.url,
          onCloseCallback: widget.onClose,
        );
        wm.registerWindow(windowController);
      }

      // Listen for changes from the window controller
      windowController.currentPage.listen((page) {
        if (pdfReady &&
            page > 0 &&
            pdfController.pageCount > 0 &&
            page <= pdfController.pageCount) {
          // Only go to the page if not already there
          if (pdfController.pageNumber != page - 1) {
            pdfController.goToPage(pageNumber: page - 1);
            print('📄 Controller requested page change to: $page');
          }
        }
      });
    } catch (e) {
      print('❌ Error setting up PDF window controller: $e');
      windowController = PdfWindowController(
        windowName: widget.windowId,
        pdfUrl: widget.url,
        onCloseCallback: widget.onClose,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                PdfViewer.uri(
                  Uri.parse(widget.url),
                  controller: pdfController,
                  params: PdfViewerParams(
                    onDocumentChanged: (document) {
                      if (document != null) {
                        setState(() {
                          errorMessage = null;
                        });
                        final pageCount = document.pages.length;
                        windowController.totalPages.value = pageCount;
                        // Always reset to page 1 on load
                        windowController.currentPage.value = 1;
                        print(
                            '📄 PDF loaded: ${widget.url}, pages: $pageCount');
                      } else {
                        setState(() {
                          errorMessage = 'Failed to load PDF document';
                        });
                        print('❌ Error: PDF document is null');
                      }
                    },
                    onViewerReady: (document, controller) {
                      pdfReady = true;
                      setState(() {});
                      print(
                          '📄 PDF viewer ready with document: ${document.pages.length} pages');
                    },
                    onPageChanged: (page) {
                      if (page != null) {
                        final newPage = page + 1;
                        // Only update if different and within bounds
                        if (windowController.currentPage.value != newPage &&
                            newPage <= windowController.totalPages.value) {
                          windowController.currentPage.value = newPage;
                          print('📄 Page changed to: $newPage');
                        }
                      }
                    },
                    loadingBannerBuilder:
                        (context, bytesDownloaded, totalBytes) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBannerBuilder:
                        (context, error, stackTrace, documentRef) {
                      print('❌ Error in PDF viewer: $error');
                      // Set error message to be displayed in the UI
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          errorMessage = 'Failed to load PDF: $error';
                        });
                      });
                      return Container(); // Error will be handled by our custom error overlay
                    },
                  ),
                ),

              // Show error overlay if there's an error
              if (errorMessage != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black54,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // PDF controls toolbar
        Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.navigate_before),
                tooltip: 'Previous Page',
                onPressed: () {
                  windowController.previousPage();
                },
              ),
              Obx(() => Text(
                    '${windowController.currentPage.value} / ${windowController.totalPages.value}',
                    style: const TextStyle(color: Colors.white),
                  )),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                tooltip: 'Next Page',
                onPressed: () {
                  windowController.nextPage();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
