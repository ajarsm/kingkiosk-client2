import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class ImageTile extends StatelessWidget {
  final String url; // Single URL for backward compatibility
  final List<String> imageUrls; // Multiple URLs for carousel
  final bool showControls;
  final VoidCallback? onClose;
  final Duration autoPlayInterval;

  const ImageTile({
    Key? key,
    required this.url,
    this.imageUrls = const [], // Default to empty list
    this.showControls = true,
    this.onClose,
    this.autoPlayInterval =
        const Duration(seconds: 5), // Default 5 second interval
  }) : super(key: key);

  // Helper method to build a single image display
  Widget _buildSingleImage(String imageUrl) {
    return Center(
      child: Image.network(
        imageUrl,
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
          return _buildErrorWidget(imageUrl);
        },
      ),
    );
  }

  Widget _buildErrorWidget(String imageUrl) {
    return Center(
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        color: Colors.red.shade50.withOpacity(0.95),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: [Colors.redAccent, Colors.orangeAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(rect),
                child: Icon(Icons.broken_image_rounded,
                    color: Colors.white, size: 64),
              ),
              SizedBox(height: 22),
              Text('Failed to load image',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.red.shade700)),
              SizedBox(height: 12),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 400),
                style: TextStyle(fontSize: 14, color: Colors.red.shade400),
                child: Text(
                  imageUrl,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 28),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                ),
                onPressed: () {
                  // Implement reload logic if needed
                },
                label: Text('Retry', style: TextStyle(fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the image carousel
  Widget _buildImageCarousel(List<String> urls) {
    return FlutterCarousel(
      items: urls.map((imageUrl) => _buildSingleImage(imageUrl)).toList(),
      options: FlutterCarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        showIndicator: true,
        slideIndicator: CircularSlideIndicator(
          slideIndicatorOptions: SlideIndicatorOptions(
            alignment: Alignment.bottomCenter,
            currentIndicatorColor: Colors.white,
            indicatorBackgroundColor: Colors.grey,
            indicatorRadius: 4,
            itemSpacing: 12,
            padding: const EdgeInsets.only(bottom: 16),
          ),
        ),
        autoPlay:
            urls.length > 1, // Only auto-play if there's more than one image
        autoPlayInterval: autoPlayInterval,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        enableInfiniteScroll: true,
      ),
    );
  }

  // Helper method for fullscreen view
  void _showFullscreenView(BuildContext context, List<String> urls) {
    final bool hasMultipleImages = urls.length > 1;

    Get.dialog(
      Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fullscreen image or carousel
            hasMultipleImages
                ? _buildImageCarousel(urls)
                : _buildSingleImage(urls.first),

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
  }

  @override
  Widget build(BuildContext context) {
    // If we have images in the imageUrls array, use those
    // Otherwise fall back to the single url property for backward compatibility
    final List<String> urls = imageUrls.isNotEmpty ? imageUrls : [url];
    final bool hasMultipleImages = urls.length > 1;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image carousel or single image based on number of URLs
          hasMultipleImages
              ? _buildImageCarousel(urls)
              : _buildSingleImage(urls.first),

          // Controls overlay (conditionally shown)
          if (showControls)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.fullscreen, color: Colors.white70),
                    onPressed: () => _showFullscreenView(context, urls),
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
