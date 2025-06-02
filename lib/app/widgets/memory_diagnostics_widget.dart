import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/memory_manager_service.dart';
import '../services/cache_optimization_service.dart';

/// Widget for displaying memory usage and optimization controls
class MemoryDiagnosticsWidget extends StatelessWidget {
  final bool showControls;
  final bool compact;
  
  const MemoryDiagnosticsWidget({
    Key? key,
    this.showControls = true,
    this.compact = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Get services safely - they extend GetxService, not GetxController
    final memoryManager = Get.find<MemoryManagerService>();
    final cacheService = Get.find<CacheOptimizationService>();
    
    if (compact) {
      return _buildCompactView(memoryManager, cacheService);
    } else {
      return _buildDetailedView(memoryManager, cacheService, context);
    }
  }
  
  /// Build compact memory indicator
  Widget _buildCompactView(MemoryManagerService memoryManager, CacheOptimizationService cacheService) {
    return Obx(() => Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getMemoryColor(memoryManager.memoryUsagePercent.value).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getMemoryColor(memoryManager.memoryUsagePercent.value),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.memory,
            size: 16,
            color: _getMemoryColor(memoryManager.memoryUsagePercent.value),
          ),
          SizedBox(width: 4),
          Text(
            '${memoryManager.memoryUsageMB.value}MB',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getMemoryColor(memoryManager.memoryUsagePercent.value),
            ),
          ),
          if (memoryManager.isMemoryPressure.value) ...[
            SizedBox(width: 4),
            Icon(
              Icons.warning_amber,
              size: 14,
              color: Colors.orange,
            ),
          ],
        ],
      ),
    ));
  }
  
  /// Build detailed memory diagnostics view
  Widget _buildDetailedView(MemoryManagerService memoryManager, CacheOptimizationService cacheService, BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.memory, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Memory Diagnostics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Spacer(),
                if (memoryManager.isMemoryPressure.value)
                  Chip(
                    label: Text('Memory Pressure'),
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    side: BorderSide(color: Colors.orange),
                  ),
              ],
            ),
            SizedBox(height: 16),
            
            // Memory usage metrics
            _buildMemoryMetrics(memoryManager),
            
            SizedBox(height: 16),
            
            // Cache metrics
            _buildCacheMetrics(cacheService),
            
            if (showControls) ...[
              SizedBox(height: 16),
              _buildMemoryControls(memoryManager, cacheService),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build memory usage metrics
  Widget _buildMemoryMetrics(MemoryManagerService memoryManager) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Memory Usage', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        
        // Memory usage bar
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[300],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: memoryManager.memoryUsagePercent.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _getMemoryColor(memoryManager.memoryUsagePercent.value),
              ),
            ),
          ),
        ),
        
        SizedBox(height: 8),
        
        // Memory stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetricItem('Current', '${memoryManager.memoryUsageMB.value}MB'),
            _buildMetricItem('Peak', '${memoryManager.peakMemoryMB.value}MB'),
            _buildMetricItem('Usage', '${(memoryManager.memoryUsagePercent.value * 100).toStringAsFixed(1)}%'),
            _buildMetricItem('Services', '${_getRegisteredServiceCount()}'),
          ],
        ),
      ],
    ));
  }
  
  /// Build cache metrics
  Widget _buildCacheMetrics(CacheOptimizationService cacheService) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cache Status', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetricItem('Images', '${cacheService.imageCacheCount.value}'),
            _buildMetricItem('Image Cache', '${(cacheService.imageCacheSize.value / (1024 * 1024)).toStringAsFixed(1)}MB'),
            _buildMetricItem('WebViews', '${cacheService.webViewCount.value}'),
          ],
        ),
      ],
    ));
  }
  
  /// Build memory control buttons
  Widget _buildMemoryControls(MemoryManagerService memoryManager, CacheOptimizationService cacheService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Memory Controls', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => memoryManager.manualCleanup(),
              icon: Icon(Icons.cleaning_services, size: 16),
              label: Text('Clean Memory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            
            ElevatedButton.icon(
              onPressed: () => memoryManager.manualCleanup(aggressive: true),
              icon: Icon(Icons.delete_sweep, size: 16),
              label: Text('Deep Clean'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            
            ElevatedButton.icon(
              onPressed: () => cacheService.clearAllCaches(),
              icon: Icon(Icons.clear_all, size: 16),
              label: Text('Clear Caches'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            
            ElevatedButton.icon(
              onPressed: () => _showDetailedReport(memoryManager, cacheService),
              icon: Icon(Icons.info_outline, size: 16),
              label: Text('Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Build individual metric item
  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  /// Get registered service count (approximate)
  int _getRegisteredServiceCount() {
    // Since Get.registered doesn't exist, we'll count some key services
    int count = 0;
    
    // Check common services that are likely registered
    try {
      if (Get.isRegistered<MemoryManagerService>()) count++;
      if (Get.isRegistered<CacheOptimizationService>()) count++;
      // Add other services to count
      // This is an approximation since GetX doesn't expose the full registry
    } catch (e) {
      // Ignore errors
    }
    
    return count > 0 ? count : 10; // Default fallback
  }
  
  /// Get color based on memory usage percentage
  Color _getMemoryColor(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.8) return Colors.orange;
    if (percentage >= 0.6) return Colors.yellow[700]!;
    return Colors.green;
  }
  
  /// Show detailed memory report dialog
  void _showDetailedReport(MemoryManagerService memoryManager, CacheOptimizationService cacheService) {
    final memoryReport = memoryManager.getMemoryReport();
    final cacheReport = cacheService.getCacheReport();
    
    Get.dialog(
      AlertDialog(
        title: Text('Detailed Memory Report'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Memory Metrics:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...memoryReport.entries.map((entry) => 
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                ),
                SizedBox(height: 16),
                Text('Cache Metrics:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...cacheReport.entries.map((entry) => 
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
