import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageTile extends StatelessWidget {
  final String url;
  final bool showControls;
  final VoidCallback? onClose;

  const ImageTile({
    Key? key,
    required this.url,
    this.showControls = true,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with loading indicator
          Center(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      url,
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Controls overlay (conditionally shown)
          if (showControls)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.fullscreen, color: Colors.white70),
                    onPressed: () {
                      // Open fullscreen view
                      Get.dialog(
                        Dialog.fullscreen(
                          backgroundColor: Colors.black,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Fullscreen image
                              Center(
                                child: Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              // Close button
                              Positioned(
                                top: 16,
                                right: 16,
                                child: IconButton(
                                  icon: Icon(Icons.close, color: Colors.white, size: 32),
                                  onPressed: () => Get.back(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white70),
                      onPressed: onClose,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
