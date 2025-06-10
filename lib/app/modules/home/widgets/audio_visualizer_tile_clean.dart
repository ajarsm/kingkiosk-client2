import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_visualizer_tile_controller.dart';

class AudioVisualizerTile extends GetView<AudioVisualizerTileController> {
  final String url;
  final String? title;

  const AudioVisualizerTile({
    Key? key,
    required this.url,
    this.title,
  }) : super(key: key);

  @override
  String get tag => url; // Use URL as unique tag

  @override
  Widget build(BuildContext context) {
    // Initialize controller with URL-specific tag
    Get.put(
        AudioVisualizerTileController(
          url: url,
          title: title,
        ),
        tag: tag);

    return Obx(() => _buildContent());
  }

  Widget _buildContent() {
    if (controller.hasError.value) {
      return _buildErrorWidget();
    }

    if (!controller.isInitialized.value) {
      return _buildLoadingWidget();
    }

    return _buildVisualizerWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            Colors.grey.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Loading Audio...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (title != null) ...[
              SizedBox(height: 8),
              Text(
                title!,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade900,
            Colors.red.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Audio Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              onPressed: () {
                controller.hasError.value = false;
                controller.errorMessage.value = '';
                controller.initializePlayer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizerWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            Colors.grey.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background gradient animation
            AnimatedBuilder(
              animation: controller.colorController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        controller.getCurrentVisualizerColor().withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Frequency bars
            Obx(() => _buildFrequencyBars()),
            // Control overlay
            _buildControlOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyBars() {
    return CustomPaint(
      painter: FrequencyBarsPainter(
        frequencyData: controller.frequencyData,
        color: controller.getCurrentVisualizerColor(),
      ),
      size: Size.infinite,
    );
  }

  Widget _buildControlOverlay() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 4),
                  Obx(() => Text(
                        _formatDuration(controller.position.value),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      )),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    controller.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (controller.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.stop,
                    color: Colors.white,
                  ),
                  onPressed: () => controller.stop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}

/// Custom painter for frequency visualization bars
class FrequencyBarsPainter extends CustomPainter {
  final RxList<double> frequencyData;
  final Color color;

  FrequencyBarsPainter({
    required this.frequencyData,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (frequencyData.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    final barWidth = size.width / frequencyData.length;
    final centerY = size.height / 2;

    for (int i = 0; i < frequencyData.length; i++) {
      final barHeight = frequencyData[i] * (size.height * 0.4);
      final x = i * barWidth;

      // Create gradient for each bar
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color,
          color.withOpacity(0.3),
        ],
      );

      paint.shader = gradient.createShader(
        Rect.fromLTWH(x, centerY - barHeight, barWidth - 2, barHeight * 2),
      );

      // Draw the bar (mirrored top and bottom)
      canvas.drawRect(
        Rect.fromLTWH(x, centerY - barHeight, barWidth - 2, barHeight * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FrequencyBarsPainter oldDelegate) {
    return frequencyData != oldDelegate.frequencyData ||
        color != oldDelegate.color;
  }
}
