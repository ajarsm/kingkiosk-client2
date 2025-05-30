#!/usr/bin/env python3
"""
KingKiosk MQTT Provision Command Example

This script demonstrates how to use the provision command to remotely configure
a KingKiosk device via MQTT. It shows examples of setting various types of
settings and handling responses.

Requirements:
    pip install paho-mqtt

Usage:
    python mqtt_provision_example.py
"""

import json
import time
import paho.mqtt.client as mqtt

# MQTT Configuration
MQTT_BROKER = "localhost"  # Change to your MQTT broker
MQTT_PORT = 1883
MQTT_USERNAME = None  # Set if your broker requires authentication
MQTT_PASSWORD = None

# Device Configuration
DEVICE_NAME = "test-kiosk"  # Change to your device name
COMMAND_TOPIC = f"kingkiosk/{DEVICE_NAME}/command"
RESPONSE_TOPIC = f"kingkiosk/{DEVICE_NAME}/provision_response"

def on_connect(client, userdata, flags, rc):
    """Callback for when the client connects to the MQTT broker."""
    if rc == 0:
        print("Connected to MQTT broker successfully")
        # Subscribe to the response topic to see provision results
        client.subscribe(RESPONSE_TOPIC)
        print(f"Subscribed to response topic: {RESPONSE_TOPIC}")
    else:
        print(f"Failed to connect to MQTT broker, return code {rc}")

def on_message(client, userdata, msg):
    """Callback for when a message is received."""
    try:
        topic = msg.topic
        payload = json.loads(msg.payload.decode())
        print(f"\n--- Response received on {topic} ---")
        print(json.dumps(payload, indent=2))
        
        # Check if it's a provision response
        if topic == RESPONSE_TOPIC:
            status = payload.get('status', 'unknown')
            applied = payload.get('total_applied', 0)
            failed = payload.get('total_failed', 0)
            
            print(f"Provision Status: {status}")
            print(f"Settings Applied: {applied}")
            print(f"Settings Failed: {failed}")
            
            if payload.get('failed_settings'):
                print("Failed Settings:")
                for failed in payload['failed_settings']:
                    print(f"  - {failed['key']}: {failed['error']}")
                    
    except json.JSONDecodeError:
        print(f"Received non-JSON message on {msg.topic}: {msg.payload.decode()}")

def send_provision_command(client, settings, description=""):
    """Send a provision command with the specified settings."""
    command = {
        "command": "provision",
        "settings": settings,
        "response_topic": RESPONSE_TOPIC
    }
    
    print(f"\n=== Sending Provision Command: {description} ===")
    print("Command payload:")
    print(json.dumps(command, indent=2))
    
    result = client.publish(COMMAND_TOPIC, json.dumps(command))
    if result.rc == mqtt.MQTT_ERR_SUCCESS:
        print("✓ Command sent successfully")
    else:
        print("✗ Failed to send command")
    
    # Wait a bit for the response
    time.sleep(2)

def main():
    """Main function to demonstrate provision commands."""
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    if MQTT_USERNAME and MQTT_PASSWORD:
        client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    
    try:
        print(f"Connecting to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        
        # Wait for connection
        time.sleep(2)
        
        # Example 1: Basic theme and display settings
        basic_settings = {
            "isDarkMode": True,
            "showSystemInfo": False,
            "kioskMode": False
        }
        send_provision_command(client, basic_settings, "Basic UI Settings")
        
        # Example 2: MQTT configuration
        mqtt_settings = {
            "mqttEnabled": True,
            "mqttBrokerUrl": "mqtt.example.com",
            "mqttBrokerPort": 1883,
            "mqttUsername": "kiosk_device",
            "mqttPassword": "secure_password_here",
            "deviceName": "lobby-display-01",
            "mqttHaDiscovery": True
        }
        send_provision_command(client, mqtt_settings, "MQTT Configuration")
        
        # Example 3: SIP settings
        sip_settings = {
            "sipEnabled": True,
            "sipServerHost": "sip.example.com",
            "sipProtocol": "UDP"
        }
        send_provision_command(client, sip_settings, "SIP Configuration")
        
        # Example 4: Mixed settings with snake_case keys
        mixed_settings = {
            "is_dark_mode": False,  # snake_case format
            "kiosk_mode": True,     # snake_case format
            "mqtt_broker_url": "new-mqtt.example.com",  # snake_case format
            "settingsPin": "9876",  # camelCase format
            "aiEnabled": True       # camelCase format
        }
        send_provision_command(client, mixed_settings, "Mixed Key Formats")
        
        # Example 5: Invalid settings (to demonstrate error handling)
        invalid_settings = {
            "validSetting": True,
            "invalidSetting1": "some_value",
            "anotherInvalidSetting": 42,
            "isDarkMode": "true"  # String that should be converted to boolean
        }
        send_provision_command(client, invalid_settings, "Mixed Valid/Invalid Settings")
        
        # Example 6: Complete device provisioning
        complete_settings = {
            # Theme
            "isDarkMode": False,
            
            # App behavior
            "kioskMode": True,
            "showSystemInfo": True,
            "kioskStartUrl": "https://dashboard.example.com",
            
            # MQTT
            "mqttEnabled": True,
            "mqttBrokerUrl": "mqtt.company.com",
            "mqttBrokerPort": 8883,
            "mqttUsername": "device_001",
            "mqttPassword": "device_secure_pass",
            "deviceName": "reception-kiosk",
            "mqttHaDiscovery": False,
            
            # SIP
            "sipEnabled": False,
            
            # AI
            "aiEnabled": True,
            "aiProviderHost": "ai.company.com",
            
            # Security
            "settingsPin": "1234"
        }
        send_provision_command(client, complete_settings, "Complete Device Setup")
        
        # Keep the client running to receive responses
        print("\nWaiting for responses... (Press Ctrl+C to exit)")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nShutting down...")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    main()
