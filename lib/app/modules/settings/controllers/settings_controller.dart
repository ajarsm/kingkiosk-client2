import 'package:get/get.dart';
import '../../../services/storage_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/mqtt_service.dart';
import '../../../core/utils/app_constants.dart';

class SettingsController extends GetxController {
  // Use lazy put to avoid build-time initialization issues
  final StorageService _storageService = Get.find<StorageService>();
  
  // Services
  late final MqttService _mqttService;
  
  // Theme settings
  final RxBool isDarkMode = false.obs;
  
  // MQTT settings
  final RxBool mqttEnabled = false.obs;
  final RxString mqttBrokerUrl = AppConstants.defaultMqttBrokerUrl.obs;
  final RxInt mqttBrokerPort = AppConstants.defaultMqttBrokerPort.obs;
  final RxString mqttUsername = ''.obs;
  final RxString mqttPassword = ''.obs;
  final RxString deviceName = ''.obs;
  final RxBool mqttHaDiscovery = false.obs;
  final RxBool mqttConnected = false.obs;
  
  // WebSocket settings
  final RxString websocketUrl = AppConstants.defaultWebsocketUrl.obs;
  
  // WebRTC settings
  final RxString mediaServerUrl = AppConstants.defaultMediaServerUrl.obs;
  
  // App settings
  final RxBool kioskMode = true.obs;
  final RxBool showSystemInfo = true.obs;
  
  // Web URL settings
  final RxString kioskStartUrl = AppConstants.defaultKioskStartUrl.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Use Future.microtask to ensure settings are loaded after the build is complete
    Future.microtask(() => _loadSettings());
  }

  void _loadSettings() {
    // Load theme settings
    isDarkMode.value = _storageService.read<bool>(AppConstants.keyIsDarkMode) ?? false;
    
    // Load WebSocket settings
    websocketUrl.value = _storageService.read<String>(AppConstants.keyWebsocketUrl) ?? websocketUrl.value;
    
    // Load WebRTC settings
    mediaServerUrl.value = _storageService.read<String>(AppConstants.keyMediaServerUrl) ?? mediaServerUrl.value;
    
    // Load app settings
    kioskMode.value = _storageService.read<bool>(AppConstants.keyKioskMode) ?? true;
    showSystemInfo.value = _storageService.read<bool>(AppConstants.keyShowSystemInfo) ?? true;
    
    // Load web URL settings
    kioskStartUrl.value = _storageService.read<String>(AppConstants.keyKioskStartUrl) ?? AppConstants.defaultKioskStartUrl;
    
    // Load MQTT settings
    mqttEnabled.value = _storageService.read<bool>(AppConstants.keyMqttEnabled) ?? false;
    mqttBrokerUrl.value = _storageService.read<String>(AppConstants.keyMqttBrokerUrl) ?? AppConstants.defaultMqttBrokerUrl;
    mqttBrokerPort.value = _storageService.read<int>(AppConstants.keyMqttBrokerPort) ?? AppConstants.defaultMqttBrokerPort;
    mqttUsername.value = _storageService.read<String>(AppConstants.keyMqttUsername) ?? '';
    mqttPassword.value = _storageService.read<String>(AppConstants.keyMqttPassword) ?? '';
    deviceName.value = _storageService.read<String>(AppConstants.keyDeviceName) ?? '';
    mqttHaDiscovery.value = _storageService.read<bool>(AppConstants.keyMqttHaDiscovery) ?? false;
    
    // Apply theme
    _applyTheme();
    
    // Initialize MQTT connection status
    _initMqttStatus();
  }
  
  void _initMqttStatus() {
    try {
      _mqttService = Get.find<MqttService>();
      mqttConnected.value = _mqttService.isConnected.value;
      
      // Listen for connection status changes
      ever(_mqttService.isConnected, (bool? connected) {
        mqttConnected.value = connected ?? false;
      });
      
      // Update device name if available from MqttService
      if (_mqttService.deviceName.value.isNotEmpty && deviceName.value.isEmpty) {
        deviceName.value = _mqttService.deviceName.value;
      }
    } catch (e) {
      print('MqttService not available: $e');
    }
  }

  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    _storageService.write(AppConstants.keyIsDarkMode, isDarkMode.value);
    
    _applyTheme();
  }

  void _applyTheme() {
    // Update the global ThemeService
    final ThemeService themeService = Get.find<ThemeService>();
    themeService.setDarkMode(isDarkMode.value);
  }

  void saveWebsocketUrl(String url) {
    websocketUrl.value = url;
    _storageService.write(AppConstants.keyWebsocketUrl, url);
  }

  void saveMediaServerUrl(String url) {
    mediaServerUrl.value = url;
    _storageService.write(AppConstants.keyMediaServerUrl, url);
  }

  void toggleKioskMode() {
    kioskMode.value = !kioskMode.value;
    _storageService.write(AppConstants.keyKioskMode, kioskMode.value);
  }

  void toggleShowSystemInfo() {
    showSystemInfo.value = !showSystemInfo.value;
    _storageService.write(AppConstants.keyShowSystemInfo, showSystemInfo.value);
  }

  void resetAllSettings() {
    // Reset theme settings
    isDarkMode.value = false;
    
    // Reset connection settings
    websocketUrl.value = AppConstants.defaultWebsocketUrl;
    mediaServerUrl.value = AppConstants.defaultMediaServerUrl;
    
    // Reset app settings
    kioskMode.value = true;
    showSystemInfo.value = true;
    
    // Reset web URL settings
    kioskStartUrl.value = AppConstants.defaultKioskStartUrl;
    
    // Reset MQTT settings
    mqttEnabled.value = false;
    mqttBrokerUrl.value = AppConstants.defaultMqttBrokerUrl;
    mqttBrokerPort.value = AppConstants.defaultMqttBrokerPort;
    mqttUsername.value = '';
    mqttPassword.value = '';
    mqttHaDiscovery.value = false;
    
    // If MQTT is connected, disconnect before resetting
    if (mqttConnected.value) {
      disconnectMqtt();
    }
    
    // Save theme settings
    _storageService.write(AppConstants.keyIsDarkMode, isDarkMode.value);
    
    // Save connection settings
    _storageService.write(AppConstants.keyWebsocketUrl, websocketUrl.value);
    _storageService.write(AppConstants.keyMediaServerUrl, mediaServerUrl.value);
    
    // Save app settings
    _storageService.write(AppConstants.keyKioskMode, kioskMode.value);
    _storageService.write(AppConstants.keyShowSystemInfo, showSystemInfo.value);
    
    // Save web URL settings
    _storageService.write(AppConstants.keyKioskStartUrl, kioskStartUrl.value);
    
    // Save MQTT settings
    _storageService.write(AppConstants.keyMqttEnabled, mqttEnabled.value);
    _storageService.write(AppConstants.keyMqttBrokerUrl, mqttBrokerUrl.value);
    _storageService.write(AppConstants.keyMqttBrokerPort, mqttBrokerPort.value);
    _storageService.write(AppConstants.keyMqttUsername, mqttUsername.value);
    _storageService.write(AppConstants.keyMqttPassword, mqttPassword.value);
    _storageService.write(AppConstants.keyMqttHaDiscovery, mqttHaDiscovery.value);
    
    // Note: We don't reset device name as that's device-specific
    
    _applyTheme();
  }

  // MQTT methods
  void toggleMqttEnabled(bool value) {
    mqttEnabled.value = value;
    _storageService.write(AppConstants.keyMqttEnabled, value);
    
    // If disabling, disconnect from MQTT
    if (!value && mqttConnected.value) {
      disconnectMqtt();
    }
  }
  
  void saveMqttBrokerUrl(String url) {
    mqttBrokerUrl.value = url;
    _storageService.write(AppConstants.keyMqttBrokerUrl, url);
  }
  
  void saveMqttBrokerPort(int port) {
    mqttBrokerPort.value = port;
    _storageService.write(AppConstants.keyMqttBrokerPort, port);
  }
  
  void saveMqttUsername(String username) {
    mqttUsername.value = username;
    _storageService.write(AppConstants.keyMqttUsername, username);
  }
  
  void saveMqttPassword(String password) {
    mqttPassword.value = password;
    _storageService.write(AppConstants.keyMqttPassword, password);
  }
  
  void saveDeviceName(String name) {
    deviceName.value = name;
    _storageService.write(AppConstants.keyDeviceName, name);
    
    // Update device name in MQTT service if connected
    try {
      _mqttService = Get.find<MqttService>();
      _mqttService.updateDeviceName(name);
    } catch (e) {
      print('MqttService not available to update device name: $e');
    }
  }
  
  void toggleMqttHaDiscovery(bool value) {
    mqttHaDiscovery.value = value;
    _storageService.write(AppConstants.keyMqttHaDiscovery, value);
    
    // If connected and enabling HA discovery, reconnect to register sensors
    if (value && mqttConnected.value) {
      disconnectMqtt();
      connectMqtt();
    }
  }
  
  void connectMqtt() {
    try {
      _mqttService = Get.find<MqttService>();
      _mqttService.connect(mqttBrokerUrl.value, mqttBrokerPort.value);
    } catch (e) {
      print('Error connecting to MQTT: $e');
      Get.snackbar(
        'MQTT Connection Failed',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void disconnectMqtt() {
    try {
      _mqttService = Get.find<MqttService>();
      _mqttService.disconnect();
    } catch (e) {
      print('Error disconnecting from MQTT: $e');
    }
  }

  // Web URL settings methods
  void saveKioskStartUrl(String url) {
    kioskStartUrl.value = url;
    _storageService.write(AppConstants.keyKioskStartUrl, url);
  }
}