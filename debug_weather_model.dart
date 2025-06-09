import 'package:open_weather_client/open_weather.dart';

void main() {
  // This is just a debug file to understand the WeatherData structure
  // We'll examine the open_weather_client package documentation

  print('Checking WeatherData structure...');

  // Example structure based on open_weather_client package:
  // WeatherData has:
  // - name (city name)
  // - coord (coordinates)
  // - weather (list of Weather objects)
  // - main (Main object with temp, humidity, pressure)
  // - wind (Wind object)
  // - dt (timestamp)

  print('WeatherData properties:');
  print('- name: String (city name)');
  print('- coord: Coord (lat, lon)');
  print('- weather: List<Weather> (conditions)');
  print('- main: Main (temp, humidity, pressure, feels_like)');
  print('- wind: Wind (speed, deg)');
  print('- dt: int (timestamp)');
  print('- sys: Sys (country, sunrise, sunset)');
}
