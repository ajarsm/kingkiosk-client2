#!/usr/bin/env python3
"""
Test script for the enhanced MQTT alert positioning functionality.
This script sends various alert commands with different positions to test the new feature.
"""

import paho.mqtt.client as mqtt
import json
import time
import sys

# MQTT Configuration
MQTT_BROKER = "localhost"  # Change to your MQTT broker
MQTT_PORT = 1883
DEVICE_NAME = "test_device"  # Change to your device name
TOPIC = f"kingkiosk/{DEVICE_NAME}/command"

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"✅ Connected to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
    else:
        print(f"❌ Failed to connect to MQTT broker. Return code: {rc}")

def send_alert(client, title, message, position="center", alert_type="info", duration=0):
    """Send an alert command with the specified position"""
    payload = {
        "command": "alert",
        "title": title,
        "message": message,
        "type": alert_type,
        "position": position,
        "duration": duration,
        "sound": True,
        "is_html": False
    }
    
    client.publish(TOPIC, json.dumps(payload))
    print(f"📨 Sent {alert_type} alert to {position}: '{title}'")

def test_all_positions():
    """Test alerts in all supported positions"""
    client = mqtt.Client()
    client.on_connect = on_connect
    
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        
        # Wait for connection
        time.sleep(2)
        
        print("\n🚨 Testing Alert Positioning Functionality")
        print("=" * 50)
        
        # Test different positions with different alert types
        positions_and_types = [
            ("center", "info", "Default Center Alert", "This alert appears in the center (default behavior)"),
            ("top-left", "warning", "Top-Left Alert", "This alert appears in the top-left corner"),
            ("top-center", "info", "Top-Center Alert", "This alert appears at the top-center"),
            ("top-right", "success", "Top-Right Alert", "This alert appears in the top-right corner"),
            ("center-left", "error", "Center-Left Alert", "This alert appears on the center-left"),
            ("center-right", "warning", "Center-Right Alert", "This alert appears on the center-right"),
            ("bottom-left", "info", "Bottom-Left Alert", "This alert appears in the bottom-left corner"),
            ("bottom-center", "success", "Bottom-Center Alert", "This alert appears at the bottom-center"),
            ("bottom-right", "error", "Bottom-Right Alert", "This alert appears in the bottom-right corner"),
        ]
        
        for position, alert_type, title, message in positions_and_types:
            send_alert(client, title, message, position, alert_type, duration=3000)
            time.sleep(4)  # Wait 4 seconds between alerts
        
        print("\n✅ Alert positioning test completed!")
        print("\nAdditional test examples:")
        print("- HTML alert with positioning")
        print("- Alert with thumbnail and positioning")
        
        # Test HTML alert
        html_payload = {
            "command": "alert",
            "title": "HTML Alert Test",
            "message": "<b>Bold text</b> and <span style='color:red'>red text</span>",
            "type": "info",
            "position": "top-right",
            "duration": 5000,
            "is_html": True
        }
        client.publish(TOPIC, json.dumps(html_payload))
        print("📨 Sent HTML alert to top-right")
        
        time.sleep(6)
        
        # Test alert with thumbnail
        thumbnail_payload = {
            "command": "alert",
            "title": "Alert with Thumbnail",
            "message": "This alert includes a thumbnail image",
            "type": "success",
            "position": "bottom-left",
            "duration": 5000,
            "thumbnail": "https://via.placeholder.com/64x64/00ff00/ffffff?text=OK"
        }
        client.publish(TOPIC, json.dumps(thumbnail_payload))
        print("📨 Sent thumbnail alert to bottom-left")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    print("MQTT Alert Positioning Test")
    print("This script tests the enhanced alert functionality with different screen positions.")
    print(f"Target device: {DEVICE_NAME}")
    print(f"MQTT Broker: {MQTT_BROKER}:{MQTT_PORT}")
    print("\nMake sure your KingKiosk device is running and connected to MQTT.")
    
    response = input("\nPress Enter to start the test, or 'q' to quit: ")
    if response.lower() != 'q':
        test_all_positions()
    else:
        print("Test cancelled.")
