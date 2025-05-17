# King Kiosk Home Assistant Integration Demo

This folder contains Docker configurations to quickly set up a Home Assistant instance that can integrate with King Kiosk for MQTT features including the screenshot functionality.

## Setup Instructions

1. Install Docker and Docker Compose if not already installed
2. In this folder, run the following command to start both MQTT broker and Home Assistant:

```bash
docker-compose up -d
```

3. Access Home Assistant at http://localhost:8123 and complete the initial setup
4. Configure your King Kiosk app to use the MQTT broker at `localhost:1883`
5. Make sure to enable Home Assistant discovery in the King Kiosk app's MQTT settings

## Testing the Screenshot Feature

1. Use the test script in the parent directory:

```bash
../test_screenshot.sh
```

2. Check your Home Assistant instance - you should see a camera entity for the screenshot
3. You can integrate the screenshot into dashboards, automations, etc.

## Included Files

- `docker-compose.yml` - Defines the containers for MQTT broker and Home Assistant
- `configuration.yaml` - Sample Home Assistant configuration with MQTT camera setup
- `mosquitto/config/mosquitto.conf` - Configuration for the MQTT broker

## Notes

- This is a demonstration setup and not intended for production use
- For production use, configure proper authentication for the MQTT broker
- Make sure to adjust the device name in the configuration to match your kiosk's device name
