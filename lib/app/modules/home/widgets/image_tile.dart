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
    this.autoPlayInterval = const Duration(seconds: 5), // Default 5 second interval
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
                imageUrl,
                style: TextStyle(color: Colors.white60, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
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
        autoPlay: urls.length > 1, // Only auto-play if there's more than one image
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
