import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_visualizer_tile_controller.dart';

class AudioVisualizerTile extends StatefulWidget {
  final String url;
  final String? title;

  const AudioVisualizerTile({
    Key? key,
    required this.url,
    this.title,
  }) : super(key: key);

  @override
  State<AudioVisualizerTile> createState() => _AudioVisualizerTileState();
}

class _AudioVisualizerTileState extends State<AudioVisualizerTile> {
  late AudioVisualizerTileController controller;
  late String tag;

  @override
  void initState() {
    super.initState();
    tag = widget.url; // Use URL as unique tag

    // Initialize controller with URL-specific tag
    if (!Get.isRegistered<AudioVisualizerTileController>(tag: tag)) {
      controller = AudioVisualizerTileController(
        url: widget.url,
        title: widget.title,
      );
      Get.put(controller, tag: tag, permanent: false);
    } else {
      controller = Get.find<AudioVisualizerTileController>(tag: tag);
    }
  }

  @override
  void dispose() {
    // Properly dispose the controller when widget is disposed
    try {
      if (Get.isRegistered<AudioVisualizerTileController>(tag: tag)) {
        // Stop and dispose the controller
        controller.stop();

        // Remove the controller from GetX
        Get.delete<AudioVisualizerTileController>(tag: tag, force: true);
        print(
            '🔊 [AudioVisualizerTile] Disposed controller for URL: ${widget.url}');
      }
    } catch (e) {
      print('⚠️ [AudioVisualizerTile] Error disposing controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Obx to make widget reactive to controller changes
    return Obx(() => _buildContent(controller));
  }

  Widget _buildContent(AudioVisualizerTileController controller) {
    if (controller.hasError.value) {
      return _buildErrorWidget(controller);
    }

    if (!controller.isInitialized.value) {
      return _buildLoadingWidget();
    }

    return _buildVisualizerWidget(controller);
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
            if (widget.title != null) ...[
              SizedBox(height: 8),
              Text(
                widget.title!,
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

  Widget _buildErrorWidget(AudioVisualizerTileController controller) {
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

  Widget _buildVisualizerWidget(AudioVisualizerTileController controller) {
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
            _buildFrequencyBars(controller),
            // Control overlay
            _buildControlOverlay(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyBars(AudioVisualizerTileController controller) {
    return Obx(() => CustomPaint(
          painter: FrequencyBarsPainter(
            frequencyData: List<double>.from(
                controller.frequencyData), // Convert RxList to List
            color: controller.getCurrentVisualizerColor(),
          ),
          size: Size.infinite,
        ));
  }

  Widget _buildControlOverlay(AudioVisualizerTileController controller) {
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
                  if (widget.title != null)
                    Text(
                      widget.title!,
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
                  icon: Obx(() => Icon(
                        controller.isPlaying.value
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      )),
                  onPressed: () {
                    if (controller.isPlaying.value) {
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
  final List<double> frequencyData;
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
