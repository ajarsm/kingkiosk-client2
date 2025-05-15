import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../services/wyoming_service.dart';
import '../../../services/mqtt_service_consolidated.dart';
import '../../../services/storage_service.dart';
import '../../../core/utils/app_constants.dart';

class WyomingSettingsController extends GetxController {
  final WyomingService wyomingService = Get.find();
  late final StorageService _storageService = Get.find<StorageService>();

  RxString host = ''.obs;
  RxInt port = 10300.obs;
  RxBool enabled = false.obs;

  // Discovery status
  final RxString discoveryStatus = ''.obs;
  final Rx<DateTime?> lastDiscoveryTime = Rx<DateTime?>(null);

  // Persistent controllers for host and port
  final TextEditingController hostController = TextEditingController();
  final TextEditingController portController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Load from storage if available, else from WyomingService
    host.value = _storageService.read<String>(AppConstants.keyWyomingHost) ?? wyomingService.host.value;
    port.value = _storageService.read<int>(AppConstants.keyWyomingPort) ?? wyomingService.port.value;
    enabled.value = _storageService.read<bool>(AppConstants.keyWyomingEnabled) ?? wyomingService.enabled.value;

    hostController.text = host.value;
    portController.text = port.value.toString();

    hostController.addListener(() {
      if (host.value != hostController.text) {
        host.value = hostController.text;
      }
    });
    portController.addListener(() {
      final parsed = int.tryParse(portController.text);
      if (parsed != null && port.value != parsed) {
        port.value = parsed;
      }
    });

    ever(host, (String val) {
      if (hostController.text != val) {
        hostController.text = val;
      }
    });
    ever(port, (int val) {
      final valStr = val.toString();
      if (portController.text != valStr) {
        portController.text = valStr;
      }
    });
  }

  void saveSettings() {
    wyomingService.host.value = host.value;
    wyomingService.port.value = port.value;
    wyomingService.enabled.value = enabled.value;
    // Persist to storage
    _storageService.write(AppConstants.keyWyomingHost, host.value);
    _storageService.write(AppConstants.keyWyomingPort, port.value);
    _storageService.write(AppConstants.keyWyomingEnabled, enabled.value);
  }

  void announceDiscovery() {
    final mqtt = Get.isRegistered<MqttService>() ? Get.find<MqttService>() : null;
    if (mqtt == null || !mqtt.isConnected.value) {
      discoveryStatus.value = 'MQTT not connected';
      Get.snackbar('Discovery Error', 'MQTT is not connected', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
      return;
    }
    wyomingService.announceDiscovery(friendlyName: 'Wyoming Satellite (${host.value})');
    lastDiscoveryTime.value = DateTime.now();
    discoveryStatus.value = 'Discovery announced successfully';
    Get.snackbar('Discovery', 'Wyoming discovery announced', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.withOpacity(0.8), colorText: Colors.white);
  }

  void removeDiscovery() {
    wyomingService.removeDiscovery();
  }

  void setAdvancedConfig(String host, int port, bool enabled) {
    wyomingService.setConfig(host: host, port: port, enabled: enabled);
    this.host.value = host;
    this.port.value = port;
    this.enabled.value = enabled;
  }
}
