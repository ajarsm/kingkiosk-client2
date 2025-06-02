#!/usr/bin/env python3
"""
Quick test script to debug the top-right positioning and border issues.
"""

import paho.mqtt.client as mqtt
import json
import time

# MQTT Configuration
MQTT_BROKER = "localhost"  # Change to your MQTT broker
MQTT_PORT = 1883
DEVICE_NAME = "test_device"  # Change to your device name
TOPIC = f"kingkiosk/{DEVICE_NAME}/command"

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"✅ Connected to MQTT broker")
    else:
        print(f"❌ Failed to connect. Return code: {rc}")

def send_test_alerts():
    client = mqtt.Client()
    client.on_connect = on_connect
    
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        time.sleep(2)
        
        print("🧪 Testing specific issues...")
        
        # Test 1: top-right positioning with info type (should be blue)
        test1 = {
            "command": "alert",
            "title": "Top-Right Test",
            "message": "This should appear in top-right corner with blue border",
            "type": "info",
            "position": "top-right",
            "duration": 5000
        }
        client.publish(TOPIC, json.dumps(test1))
        print("📨 Test 1: top-right with info type (blue border)")
        time.sleep(6)
        
        # Test 2: top-right with no border
        test2 = {
            "command": "alert", 
            "title": "No Border Test",
            "message": "This should appear in top-right with NO border",
            "position": "top-right",
            "show_border": False,
            "duration": 5000
        }
        client.publish(TOPIC, json.dumps(test2))
        print("📨 Test 2: top-right with no border")
        time.sleep(6)
        
        # Test 3: top-right with custom green border
        test3 = {
            "command": "alert",
            "title": "Custom Border Test", 
            "message": "This should have a green border in top-right",
            "position": "top-right",
            "border_color": "#00ff00",
            "duration": 5000
        }
        client.publish(TOPIC, json.dumps(test3))
        print("📨 Test 3: top-right with green border")
        time.sleep(6)
        
        # Test 4: center position for comparison
        test4 = {
            "command": "alert",
            "title": "Center Test",
            "message": "This should appear in center (default)",
            "type": "info",
            "duration": 5000
        }
        client.publish(TOPIC, json.dumps(test4))
        print("📨 Test 4: center position (default)")
        
        print("\n✅ All tests sent! Check your KingKiosk device.")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    print("🚨 Alert Debug Test")
    print("Testing top-right positioning and border control")
    print(f"Target: {DEVICE_NAME} on {MQTT_BROKER}:{MQTT_PORT}")
    send_test_alerts()
