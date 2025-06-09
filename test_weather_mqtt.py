#!/usr/bin/env python3

import paho.mqtt.client as mqtt
import json
import time

# MQTT Configuration
MQTT_BROKER = "192.168.0.199"
MQTT_PORT = 1883
MQTT_USERNAME = "alarmpanelgarage"
MQTT_PASSWORD = "alarmpanelgarage"
DEVICE_NAME = "rajofficemac"

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")

def on_publish(client, userdata, mid):
    print(f"Message published successfully (mid: {mid})")

def send_weather_command():
    client = mqtt.Client()
    client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    client.on_connect = on_connect
    client.on_publish = on_publish
    
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        
        # Wait for connection
        time.sleep(2)
        
        # Weather widget command with demo API key (will show error but should create tile)
        weather_command = {
            "command": "open_weather_client",
            "api_key": "demo_key_123",
            "location": "London"
        }
        
        topic = f"kingkiosk/{DEVICE_NAME}/command"
        message = json.dumps(weather_command)
        
        print(f"Sending weather command to topic: {topic}")
        print(f"Command: {message}")
        
        result = client.publish(topic, message)
        
        # Wait for publish to complete
        time.sleep(2)
        
        client.loop_stop()
        client.disconnect()
        
        print("Weather command sent successfully!")
        print("Check the Flutter app - a weather tile should appear")
        
    except Exception as e:
        print(f"Error sending command: {e}")

if __name__ == "__main__":
    send_weather_command()
