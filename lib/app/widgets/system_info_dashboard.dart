import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/platform_sensor_service.dart';
import '../core/utils/platform_utils.dart';

class SystemInfoDashboard extends StatelessWidget {
  final bool compact;
  
  const SystemInfoDashboard({
    Key? key, 
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PlatformSensorService sensorService = Get.find<PlatformSensorService>();
    
    return Card(
      margin: EdgeInsets.all(compact ? 8.0 : 16.0),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Text(
                  'System Information',
                  style: TextStyle(
                    fontSize: compact ? 14 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(),
            _buildInfoRow('Platform', PlatformUtils.platformName),
            _buildSensorRow(
              'Battery', 
              sensorService.batteryLevel, 
              suffix: '%',
              icon: Icons.battery_full,
            ),
            _buildSensorRow(
              'Battery Status', 
              sensorService.batteryState,
              icon: Icons.battery_charging_full,
            ),
            _buildSensorRow<double>(
              'CPU Usage', 
              sensorService.cpuUsage,
              suffix: '%',
              valueMapper: (value) => (value * 100).toStringAsFixed(1),
              icon: Icons.memory,
            ),
            _buildSensorRow<double>(
              'Memory Usage', 
              sensorService.memoryUsage,
              suffix: '%',
              valueMapper: (value) => (value * 100).toStringAsFixed(1),
              icon: Icons.storage,
            ),
            if (!compact) ...[
              Divider(),
              Text(
                'Accelerometer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Obx(() => _buildAccelerometerValue('X', sensorService.accelerometerX.value)),
                  Obx(() => _buildAccelerometerValue('Y', sensorService.accelerometerY.value)),
                  Obx(() => _buildAccelerometerValue('Z', sensorService.accelerometerZ.value)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2.0 : 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSensorRow<T>(
    String label, 
    Rx<T> sensor, {
    String suffix = '',
    IconData? icon,
    String Function(T)? valueMapper,
  }) {
    return Obx(() {
      final value = sensor.value;
      final displayValue = valueMapper != null ? valueMapper(value) : value.toString();
      
      return Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 2.0 : 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: compact ? 14 : 16),
                  SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '$displayValue$suffix',
              style: TextStyle(
                fontSize: compact ? 12 : 14,
              ),
            ),
          ],
        ),
      );
    });
  }
  
  Widget _buildAccelerometerValue(String axis, double value) {
    return Column(
      children: [
        Text(
          axis,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(value.toStringAsFixed(2)),
      ],
    );
  }
}