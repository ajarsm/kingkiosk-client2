// Simple Dart script to check WeatherData properties
import 'dart:mirrors';
import 'package:open_weather_client/open_weather.dart';

void main() {
  // Get the type of WeatherData to inspect its properties
  ClassMirror classMirror = reflectClass(WeatherData);

  print('WeatherData properties:');
  classMirror.declarations.forEach((symbol, declaration) {
    if (declaration is VariableMirror && declaration.isGetter) {
      print(
          '- ${MirrorSystem.getName(symbol)}: ${declaration.type.simpleName}');
    }
  });

  print('\nWeatherData constructors:');
  classMirror.declarations.forEach((symbol, declaration) {
    if (declaration is MethodMirror && declaration.isConstructor) {
      print('- ${MirrorSystem.getName(symbol)}');
    }
  });
}
