#!/usr/bin/env python3
"""
Script to enable Home Assistant discovery on your KingKiosk device
This uses the new provision command to remotely enable HA discovery
"""

import paho.mqtt.client as mqtt
import json
import time

# MQTT Configuration - Update these to match your setup
MQTT_BROKER = "192.168.0.199"  # Your MQTT broker IP from the logs
MQTT_PORT = 1883
MQTT_USERNAME = None  # Set if your broker requires auth
MQTT_PASSWORD = None  # Set if your broker requires auth

# Device configuration - Update this to match your device name
DEVICE_NAME = "your-device-name"  # Replace with your actual device name

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"✅ Connected to MQTT broker {MQTT_BROKER}:{MQTT_PORT}")
        
        # Subscribe to the response topic to see the result
        response_topic = f"kingkiosk/{DEVICE_NAME}/provision_response"
        client.subscribe(response_topic)
        print(f"🔔 Subscribed to response topic: {response_topic}")
        
        # Send the provision command to enable Home Assistant discovery
        provision_command = {
            "command": "provision",
            "settings": {
                "mqttHaDiscovery": True
            },
            "response_topic": response_topic
        }
        
        command_topic = f"kingkiosk/{DEVICE_NAME}/command"
        payload = json.dumps(provision_command, indent=2)
        
        print(f"📤 Sending provision command to: {command_topic}")
        print(f"📋 Payload: {payload}")
        
        client.publish(command_topic, payload)
        print("✅ Provision command sent!")
        
    else:
        print(f"❌ Failed to connect to MQTT broker. Return code: {rc}")

def on_message(client, userdata, msg):
    try:
        topic = msg.topic
        payload = msg.payload.decode('utf-8')
        
        print(f"📥 Received message on {topic}:")
        
        # Try to parse as JSON for pretty printing
        try:
            data = json.loads(payload)
            print(json.dumps(data, indent=2))
            
            # Check if this is a provision response
            if 'status' in data:
                if data['status'] == 'success':
                    print("🎉 SUCCESS! Home Assistant discovery has been enabled!")
                    print("👀 Check your Home Assistant for new device entities.")
                elif data['status'] == 'partial':
                    print("⚠️ PARTIAL SUCCESS: Some settings were applied")
                    print(f"Applied: {data.get('applied_settings', [])}")
                    print(f"Failed: {data.get('failed_settings', {})}")
                else:
                    print(f"❌ FAILED: {data.get('message', 'Unknown error')}")
                    
        except json.JSONDecodeError:
            print(payload)
            
    except Exception as e:
        print(f"❌ Error processing message: {e}")

def main():
    print("🚀 KingKiosk Home Assistant Discovery Enabler")
    print("=" * 50)
    
    # Validate device name
    if DEVICE_NAME == "your-device-name":
        print("❌ ERROR: Please update DEVICE_NAME in this script!")
        print("   Check your KingKiosk app logs or settings to find your device name.")
        print("   Look for lines like: 'Device name: xyz' or 'MQTT Connected' messages.")
        return
    
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
        
        print("⏱️ Waiting for response... (press Ctrl+C to exit)")
        time.sleep(10)  # Wait 10 seconds for response
        
        client.loop_stop()
        client.disconnect()
        print("👋 Disconnected from MQTT broker")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
