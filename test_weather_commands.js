// Test script for weather widget MQTT commands
// This can be used to test the weather widget once the app is running

// Basic weather widget command
const basicWeatherCommand = {
  "command": "open_weather_client",
  "api_key": "your_api_key_here",
  "location": "London"
};

// Weather widget with coordinates
const coordinateWeatherCommand = {
  "command": "open_weather_client", 
  "api_key": "your_api_key_here",
  "latitude": 40.7128,
  "longitude": -74.0060
};

// Weather widget with full configuration
const fullWeatherCommand = {
  "command": "open_weather_client",
  "api_key": "your_api_key_here",
  "location": "New York",
  "units": "metric",
  "show_forecast": true,
  "auto_refresh": true,
  "refresh_interval": 300
};

console.log("Weather Widget Test Commands:");
console.log("1. Basic Weather Command:", JSON.stringify(basicWeatherCommand, null, 2));
console.log("2. Coordinate Weather Command:", JSON.stringify(coordinateWeatherCommand, null, 2));
console.log("3. Full Weather Command:", JSON.stringify(fullWeatherCommand, null, 2));

console.log("\nTo test:");
console.log("1. Start the Flutter app");
console.log("2. Send one of these MQTT commands to test the weather widget");
console.log("3. The widget should appear as a tile in the tiling window system");
