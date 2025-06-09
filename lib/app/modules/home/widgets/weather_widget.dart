import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/weather_window_controller.dart';

class WeatherWidget extends StatelessWidget {
  final String windowId;
  final String windowName;
  final double? width;
  final double? height;

  const WeatherWidget({
    Key? key,
    required this.windowId,
    required this.windowName,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the weather controller for this window
    final controller = Get.find<WeatherWindowController>(tag: windowId);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        // Show loading state
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        // Show error state
        if (controller.errorMessage != null &&
            controller.errorMessage!.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Weather Error',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    controller.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show weather data
        final weatherData = controller.weatherData;
        if (weatherData == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'No weather data available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        // Display weather information
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with location name
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weatherData.name ?? 'Unknown Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.refresh(),
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main weather display - simplified for now
              Center(
                child: Column(
                  children: [
                    // Weather icon - use a generic sun icon for now
                    const Icon(
                      Icons.wb_sunny,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),

                    // Basic weather info
                    Text(
                      'Weather Data Available',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),

                    // Show data object toString for debugging
                    Text(
                      'Location: ${weatherData.name ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Last updated
              if (controller.lastUpdated != null)
                Center(
                  child: Text(
                    'Last updated: ${_formatTime(controller.lastUpdated!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
