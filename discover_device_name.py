#!/usr/bin/env python3
"""
Script to discover your KingKiosk device name by listening to MQTT status messages
This will help you find your device name for enabling Home Assistant discovery
"""

import paho.mqtt.client as mqtt
import json
import time
import re

# MQTT Configuration - Update these to match your setup
MQTT_BROKER = "192.168.0.199"  # Your MQTT broker IP from the logs
MQTT_PORT = 1883
MQTT_USERNAME = None  # Set if your broker requires auth
MQTT_PASSWORD = None  # Set if your broker requires auth

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"✅ Connected to MQTT broker {MQTT_BROKER}:{MQTT_PORT}")
        
        # Subscribe to all kingkiosk topics to discover device names
        topics = [
            "kingkiosk/+/status",          # Device status messages
            "kingkiosk/+/battery",         # Battery sensor
            "kingkiosk/+/cpu_usage",       # CPU sensor
            "kingkiosk/+/command",         # Command topics (for testing)
            "kiosk/+/diagnostics/+",       # Diagnostics
        ]
        
        for topic in topics:
            client.subscribe(topic)
            print(f"🔔 Subscribed to: {topic}")
        
        print("\n🔍 Listening for KingKiosk device messages...")
        print("📱 Make sure your KingKiosk app is running and connected to MQTT!")
        print("⏰ Will listen for 30 seconds...\n")
        
    else:
        print(f"❌ Failed to connect to MQTT broker. Return code: {rc}")

def on_message(client, userdata, msg):
    try:
        topic = msg.topic
        payload = msg.payload.decode('utf-8')
        
        # Extract device name from topic
        device_name = None
        
        # Check for kingkiosk topics
        if topic.startswith("kingkiosk/"):
            parts = topic.split("/")
            if len(parts) >= 2:
                device_name = parts[1]
        
        # Check for kiosk topics
        elif topic.startswith("kiosk/"):
            parts = topic.split("/")
            if len(parts) >= 2:
                device_name = parts[1]
        
        if device_name:
            print(f"🎯 FOUND DEVICE: '{device_name}'")
            print(f"   📋 Topic: {topic}")
            print(f"   📦 Payload: {payload}")
            print(f"   ⚡ Use this device name in the enabler script!")
            print("-" * 60)
            
            # Try to parse as JSON for better display
            try:
                data = json.loads(payload)
                print(f"   📊 JSON Data: {json.dumps(data, indent=4)}")
            except json.JSONDecodeError:
                pass
                
            print()
            
    except Exception as e:
        print(f"❌ Error processing message: {e}")

def main():
    print("🔍 KingKiosk Device Name Discovery Tool")
    print("=" * 50)
    
    # Create MQTT client
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    # Set authentication if provided
    if MQTT_USERNAME and MQTT_PASSWORD:
        client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
        print(f"🔐 Using authentication for user: {MQTT_USERNAME}")
    
    try:
        print(f"🔌 Connecting to MQTT broker {MQTT_BROKER}:{MQTT_PORT}...")
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        
        # Start the loop and wait for messages
        client.loop_start()
        
        # Wait for 30 seconds
        time.sleep(30)
        
        client.loop_stop()
        client.disconnect()
        
        print("\n🏁 Discovery complete!")
        print("📝 If you found your device name above, update the enable_ha_discovery.py script")
        print("   and set DEVICE_NAME to the discovered name.")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
