import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_weather_client/open_weather.dart';
import '../controllers/weather_window_controller.dart';

/// Simple weather data model for UI display
class WeatherDisplayData {
  final String? location;
  final double? temperature;
  final String? condition;
  final double? humidity;
  final double? windSpeed;
  final double? pressure;
  final DateTime? time;

  WeatherDisplayData({
    this.location,
    this.temperature,
    this.condition,
    this.humidity,
    this.windSpeed,
    this.pressure,
    this.time,
  });

  factory WeatherDisplayData.fromWeatherData(WeatherData data) {
    return WeatherDisplayData(
      location: data.name,
      temperature: data.temperature.currentTemperature,
      condition: data.weather?.first.description,
      humidity: data.details?.humidity,
      windSpeed: data.wind.speed,
      pressure: data.details?.pressure,
      time: DateTime.now(),
    );
  }
}

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
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

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
                const Text(
                  'Weather Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    controller.errorMessage!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final weatherData = controller.weatherData;
        if (weatherData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Weather Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Load Weather'),
                ),
              ],
            ),
          );
        }

        // Convert WeatherData to our display model
        final weather = WeatherDisplayData.fromWeatherData(weatherData);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with location and refresh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.location ?? 'Weather',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatLastUpdated(controller.lastUpdated),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.refresh(),
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                    tooltip: 'Refresh Weather',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current weather display
              Expanded(
                child: Row(
                  children: [
                    // Weather icon and temperature
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Weather icon (placeholder for now)
                          Icon(
                            _getWeatherIcon(weather.condition),
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${weather.temperature?.toStringAsFixed(0) ?? '--'}${controller.temperatureUnit}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            weather.condition?.capitalize ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Weather details
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (weather.humidity != null)
                            _buildWeatherDetail(
                              Icons.water_drop,
                              '${weather.humidity!.toStringAsFixed(0)}%',
                              'Humidity',
                            ),
                          if (weather.windSpeed != null)
                            _buildWeatherDetail(
                              Icons.air,
                              '${weather.windSpeed!.toStringAsFixed(1)} ${controller.windSpeedUnit}',
                              'Wind',
                            ),
                          if (weather.pressure != null)
                            _buildWeatherDetail(
                              Icons.compress,
                              '${weather.pressure!.toStringAsFixed(0)} hPa',
                              'Pressure',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Forecast section (if enabled)
              if (controller.showForecast && controller.forecastData != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Colors.white30),
                    const SizedBox(height: 8),
                    const Text(
                      'Forecast',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: math.min(
                            controller.forecastData?.forecastData?.length ?? 0,
                            5),
                        itemBuilder: (context, index) {
                          final forecast =
                              controller.forecastData!.forecastData![index];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            child: Column(
                              children: [
                                Text(
                                  _formatForecastTime(forecast.date),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  _getWeatherIcon(
                                      forecast.weather?.first.description),
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${forecast.temperature.currentTemperature?.toStringAsFixed(0) ?? '--'}°',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white70,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.help_outline;

    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('clear')) {
      return Icons.wb_sunny;
    } else if (lowerCondition.contains('cloud')) {
      return Icons.cloud;
    } else if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle')) {
      return Icons.grain;
    } else if (lowerCondition.contains('snow')) {
      return Icons.ac_unit;
    } else if (lowerCondition.contains('thunder') ||
        lowerCondition.contains('storm')) {
      return Icons.flash_on;
    } else if (lowerCondition.contains('mist') ||
        lowerCondition.contains('fog')) {
      return Icons.visibility_off;
    } else {
      return Icons.wb_cloudy;
    }
  }

  String _formatLastUpdated(DateTime? time) {
    if (time == null) return 'Never';

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

  String _formatForecastTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = time.difference(now).inHours;

    if (difference < 24) {
      return '${time.hour}:00';
    } else {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    }
  }
}
