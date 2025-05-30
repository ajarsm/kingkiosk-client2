# KingKiosk MQTT Examples

This directory contains example scripts and documentation for using MQTT commands with KingKiosk.

## Files

### `mqtt_provision_example.py`
A comprehensive Python script demonstrating how to use the `provision` command to remotely configure KingKiosk devices via MQTT.

**Features:**
- Shows how to connect to an MQTT broker
- Demonstrates various provision command formats
- Handles provision responses and error reporting
- Includes examples for all major setting categories
- Shows both camelCase and snake_case key formats

**Requirements:**
```bash
pip install paho-mqtt
```

**Usage:**
1. Update the MQTT broker configuration in the script
2. Set the correct device name for your KingKiosk device
3. Run the script:
   ```bash
   python mqtt_provision_example.py
   ```

**What it demonstrates:**
- Basic UI settings (theme, kiosk mode, system info)
- MQTT configuration (broker, credentials, device name)
- SIP settings (server, protocol)
- Mixed key formats (camelCase vs snake_case)
- Error handling for invalid settings
- Complete device provisioning workflow

## Getting Started

1. Ensure your KingKiosk device is connected to the same network as your MQTT broker
2. Configure MQTT settings in the KingKiosk app (or use the provision command itself!)
3. Install the required Python packages for the examples
4. Update the broker and device configuration in the example scripts
5. Run the examples to see the commands in action

## MQTT Reference

For complete documentation of all available MQTT commands, see the main `mqtt_reference.md` file in the project root.

## Security Note

The provision command can change sensitive settings including MQTT credentials and security PINs. Always use secure connections (TLS) when sending provision commands over untrusted networks.
