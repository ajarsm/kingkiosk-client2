import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_weather_client/open_weather.dart';
import '../../../services/window_manager_service.dart';
import '../../../services/platform_sensor_service.dart';

/// Weather units enum
enum WeatherDisplayUnits {
  metric, // Celsius, m/s
  imperial, // Fahrenheit, mph
  standard, // Kelvin, m/s
}

/// Weather window controller for handling OpenWeatherMap widgets
class WeatherWindowController extends GetxController
    implements KioskWindowController {
  final String windowName;

  // Reactive properties
  final _isVisible = true.obs;
  final _isMinimized = false.obs;
  final _isLoading = false.obs;
  final _errorMessage = RxnString();
  final _weatherData = Rxn<WeatherData>();
  final _forecastData = Rxn<WeatherForecastData>();
  final _lastUpdated = Rxn<DateTime>();

  // Configuration
  final _apiKey = ''.obs;
  final _location = RxnString();
  final _latitude = RxnDouble();
  final _longitude = RxnDouble();
  final _units = WeatherDisplayUnits.metric.obs;
  final _language = 'en'.obs;
  final _showForecast = false.obs;
  final _autoRefresh = true.obs;
  final _refreshInterval = 300.obs; // 5 minutes default

  // Timer for auto refresh
  Timer? _refreshTimer;
  late OpenWeather _openWeather;

  // Getters
  bool get isVisible => _isVisible.value;
  bool get isMinimized => _isMinimized.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  WeatherData? get weatherData => _weatherData.value;
  WeatherForecastData? get forecastData => _forecastData.value;
  DateTime? get lastUpdated => _lastUpdated.value;
  String get apiKey => _apiKey.value;
  String? get location => _location.value;
  double? get latitude => _latitude.value;
  double? get longitude => _longitude.value;
  WeatherDisplayUnits get units => _units.value;
  String get language => _language.value;
  bool get showForecast => _showForecast.value;
  bool get autoRefresh => _autoRefresh.value;
  int get refreshInterval => _refreshInterval.value;

  WeatherWindowController({required this.windowName});

  @override
  KioskWindowType get windowType => KioskWindowType.custom;

  @override
  void onInit() {
    super.onInit();

    // Register this controller with the window manager
    Get.find<WindowManagerService>().registerWindow(this);

    print('Weather window controller initialized for: $windowName');
  }

  @override
  void onClose() {
    disposeWindow();
    super.onClose();
  }

  @override
  void handleCommand(String action, Map<String, dynamic>? payload) {
    print('Weather window received command: $action with payload: $payload');

    switch (action) {
      case 'minimize':
        minimize();
        break;
      case 'maximize':
      case 'restore':
        maximize();
        break;
      case 'close':
        close();
        break;
      case 'configure':
        configure(payload ?? {});
        break;
      case 'refresh':
        refresh();
        break;
      case 'toggle_forecast':
        toggleForecast();
        break;
      case 'set_location':
        final lat = payload?['latitude'] as double?;
        final lon = payload?['longitude'] as double?;
        final loc = payload?['location'] as String?;
        if (lat != null && lon != null) {
          setLocation(latitude: lat, longitude: lon);
        } else if (loc != null) {
          setLocation(location: loc);
        }
        break;
      default:
        print('Unknown command for Weather window: $action');
    }
  }

  @override
  void disposeWindow() {
    try {
      _refreshTimer?.cancel();
      Get.find<WindowManagerService>().unregisterWindow(windowName);
      print('Weather window disposed: $windowName');
    } catch (e) {
      print('Error disposing Weather window: $e');
    }
  }

  /// Configure the weather widget
  void configure(Map<String, dynamic> config) {
    print('Configuring weather widget: $config');

    // Set API key
    if (config['api_key'] != null) {
      _apiKey.value = config['api_key'].toString();
    }

    // Set location
    if (config['location'] != null) {
      _location.value = config['location'].toString();
    }

    // Set coordinates
    if (config['latitude'] != null) {
      _latitude.value = double.tryParse(config['latitude'].toString());
    }
    if (config['longitude'] != null) {
      _longitude.value = double.tryParse(config['longitude'].toString());
    }

    // Set units
    if (config['units'] != null) {
      final unitsStr = config['units'].toString().toLowerCase();
      switch (unitsStr) {
        case 'metric':
          _units.value = WeatherDisplayUnits.metric;
          break;
        case 'imperial':
          _units.value = WeatherDisplayUnits.imperial;
          break;
        case 'standard':
          _units.value = WeatherDisplayUnits.standard;
          break;
      }
    }

    // Set language
    if (config['language'] != null) {
      final langStr = config['language'].toString().toLowerCase();
      // Map common language codes to language strings
      switch (langStr) {
        case 'en':
        case 'english':
          _language.value = 'en';
          break;
        case 'de':
        case 'german':
          _language.value = 'de';
          break;
        case 'fr':
        case 'french':
          _language.value = 'fr';
          break;
        case 'es':
        case 'spanish':
          _language.value = 'es';
          break;
        case 'it':
        case 'italian':
          _language.value = 'it';
          break;
        default:
          _language.value = 'en';
      }
    }

    // Set other options
    if (config['show_forecast'] != null) {
      _showForecast.value = config['show_forecast'] == true;
    }

    if (config['auto_refresh'] != null) {
      _autoRefresh.value = config['auto_refresh'] == true;
    }

    if (config['refresh_interval'] != null) {
      _refreshInterval.value =
          int.tryParse(config['refresh_interval'].toString()) ?? 300;
    }

    // Initialize OpenWeather client and fetch data
    _initializeAndFetch();
  }

  /// Initialize OpenWeather client and fetch weather data
  void _initializeAndFetch() async {
    if (_apiKey.value.isEmpty) {
      _errorMessage.value = 'API key is required';
      return;
    }

    try {
      _openWeather = OpenWeather(apiKey: _apiKey.value);

      // If no location is set, try to get current location
      if (_location.value == null &&
          (_latitude.value == null || _longitude.value == null)) {
        await _getCurrentLocation();
      }

      // Fetch weather data
      await refresh();

      // Start auto refresh if enabled
      if (_autoRefresh.value) {
        _startAutoRefresh();
      }
    } catch (e) {
      _errorMessage.value = 'Failed to initialize weather: $e';
      print('Error initializing weather: $e');
    }
  }

  /// Get current location from device
  Future<void> _getCurrentLocation() async {
    try {
      // Try to get from platform sensor service first
      final sensorService = Get.find<PlatformSensorService>();
      if (sensorService.latitude.value != 0.0 &&
          sensorService.longitude.value != 0.0) {
        _latitude.value = sensorService.latitude.value;
        _longitude.value = sensorService.longitude.value;
        print(
            'Using location from sensor service: ${_latitude.value}, ${_longitude.value}');
        return;
      }

      // Fallback to direct geolocator
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _latitude.value = position.latitude;
      _longitude.value = position.longitude;
      print('Got current location: ${_latitude.value}, ${_longitude.value}');
    } catch (e) {
      print('Error getting current location: $e');
      // Use default location (London) as fallback
      _latitude.value = 51.5074;
      _longitude.value = -0.1278;
    }
  }

  /// Refresh weather data
  Future<void> refresh() async {
    if (_apiKey.value.isEmpty) {
      _errorMessage.value = 'API key is required';
      return;
    }

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      final weatherUnits = _getWeatherUnits();

      WeatherData? currentWeather;
      WeatherForecastData? forecast;

      // Fetch current weather
      if (_location.value != null && _location.value!.isNotEmpty) {
        // Fetch by city name
        currentWeather = await _openWeather.currentWeatherByCityName(
          cityName: _location.value!,
          weatherUnits: weatherUnits,
        );
      } else if (_latitude.value != null && _longitude.value != null) {
        // Fetch by coordinates
        currentWeather = await _openWeather.currentWeatherByLocation(
          latitude: _latitude.value!,
          longitude: _longitude.value!,
          weatherUnits: weatherUnits,
        );
      } else {
        throw Exception('No location specified');
      }

      _weatherData.value = currentWeather;

      // Fetch forecast if enabled
      if (_showForecast.value) {
        if (_location.value != null && _location.value!.isNotEmpty) {
          forecast = await _openWeather.fiveDaysWeatherForecastByCityName(
            cityName: _location.value!,
            weatherUnits: weatherUnits,
          );
        } else if (_latitude.value != null && _longitude.value != null) {
          forecast = await _openWeather.fiveDaysWeatherForecastByLocation(
            latitude: _latitude.value!,
            longitude: _longitude.value!,
            weatherUnits: weatherUnits,
          );
        }
        _forecastData.value = forecast;
      }

      _lastUpdated.value = DateTime.now();
      print('Weather data refreshed successfully');
    } catch (e) {
      _errorMessage.value = 'Failed to fetch weather: $e';
      print('Error fetching weather: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Convert display units to WeatherUnits
  WeatherUnits _getWeatherUnits() {
    switch (_units.value) {
      case WeatherDisplayUnits.metric:
        return WeatherUnits.METRIC;
      case WeatherDisplayUnits.imperial:
        return WeatherUnits.IMPERIAL;
      case WeatherDisplayUnits.standard:
        return WeatherUnits.STANDARD;
    }
  }

  /// Set location for weather data
  void setLocation({String? location, double? latitude, double? longitude}) {
    if (location != null) {
      _location.value = location;
      _latitude.value = null;
      _longitude.value = null;
    } else if (latitude != null && longitude != null) {
      _latitude.value = latitude;
      _longitude.value = longitude;
      _location.value = null;
    }

    if (_apiKey.value.isNotEmpty) {
      refresh();
    }
  }

  /// Toggle forecast display
  void toggleForecast() {
    _showForecast.value = !_showForecast.value;
    if (_showForecast.value && _forecastData.value == null) {
      refresh();
    }
  }

  /// Start auto refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    if (_autoRefresh.value && _refreshInterval.value > 0) {
      _refreshTimer = Timer.periodic(
        Duration(seconds: _refreshInterval.value),
        (_) => refresh(),
      );
    }
  }

  /// Stop auto refresh timer
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _autoRefresh.value = false;
  }

  /// Get temperature unit symbol
  String get temperatureUnit {
    switch (_units.value) {
      case WeatherDisplayUnits.metric:
        return '°C';
      case WeatherDisplayUnits.imperial:
        return '°F';
      case WeatherDisplayUnits.standard:
        return 'K';
    }
  }

  /// Get wind speed unit
  String get windSpeedUnit {
    switch (_units.value) {
      case WeatherDisplayUnits.metric:
        return 'm/s';
      case WeatherDisplayUnits.imperial:
        return 'mph';
      case WeatherDisplayUnits.standard:
        return 'm/s';
    }
  }

  /// Window management methods
  void minimize() {
    _isMinimized.value = true;
    print('Weather window minimized: $windowName');
  }

  void maximize() {
    _isMinimized.value = false;
    print('Weather window maximized: $windowName');
  }

  void close() {
    disposeWindow();
  }
}
