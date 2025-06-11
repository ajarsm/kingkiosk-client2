#!/usr/bin/env python3
"""
MQTT Wait Command Test Script
Tests the new wait command functionality in batch scripts
"""

import json
import time
import paho.mqtt.client as mqtt
from datetime import datetime

# MQTT Configuration
MQTT_BROKER = "192.168.0.199"
MQTT_PORT = 1883
MQTT_USERNAME = "alarmpanelgarage"  # Update with your credentials
MQTT_PASSWORD = "your_password"      # Update with your credentials
DEVICE_NAME = "rajofficemac"

# MQTT Topics
COMMAND_TOPIC = f"kingkiosk/{DEVICE_NAME}/command"
RESPONSE_TOPIC = f"kingkiosk/{DEVICE_NAME}/test/response"

def on_connect(client, userdata, flags, rc):
    print(f"Connected to MQTT broker with result code {rc}")
    # Subscribe to response topic
    client.subscribe(RESPONSE_TOPIC)
    print(f"Subscribed to response topic: {RESPONSE_TOPIC}")

def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        print(f"[{timestamp}] Response: {payload}")
    except Exception as e:
        print(f"Error parsing response: {e}")

def test_single_wait_command(client):
    """Test a single wait command"""
    print("\n🧪 Testing single wait command (3 seconds)...")
    
    command = {
        "command": "wait",
        "seconds": 3,
        "response_topic": RESPONSE_TOPIC
    }
    
    start_time = time.time()
    client.publish(COMMAND_TOPIC, json.dumps(command))
    print(f"⏱️  Sent wait command at {datetime.now().strftime('%H:%M:%S.%f')[:-3]}")
    
    # Wait a bit longer than the command to see the response
    time.sleep(4)
    end_time = time.time()
    print(f"✅ Test completed in {end_time - start_time:.2f} seconds")

def test_batch_wait_commands(client):
    """Test batch commands with multiple waits"""
    print("\n🧪 Testing batch commands with waits...")
    
    batch_command = {
        "command": "batch",
        "commands": [
            {
                "command": "tts",
                "text": "Starting batch test with waits",
                "response_topic": RESPONSE_TOPIC
            },
            {
                "command": "wait",
                "seconds": 2,
                "response_topic": RESPONSE_TOPIC
            },
            {
                "command": "tts", 
                "text": "First wait completed",
                "response_topic": RESPONSE_TOPIC
            },
            {
                "command": "wait",
                "seconds": 1.5,
                "response_topic": RESPONSE_TOPIC
            },
            {
                "command": "tts",
                "text": "Batch test completed",
                "response_topic": RESPONSE_TOPIC
            }
        ]
    }
    
    start_time = time.time()
    client.publish(COMMAND_TOPIC, json.dumps(batch_command))
    print(f"⏱️  Sent batch command at {datetime.now().strftime('%H:%M:%S.%f')[:-3]}")
    
    # Wait for batch to complete
    time.sleep(8)
    end_time = time.time()
    print(f"✅ Batch test completed in {end_time - start_time:.2f} seconds")

def test_invalid_wait_command(client):
    """Test wait command with invalid parameters"""
    print("\n🧪 Testing invalid wait command...")
    
    command = {
        "command": "wait",
        "seconds": 500,  # Exceeds 300 second limit
        "response_topic": RESPONSE_TOPIC
    }
    
    client.publish(COMMAND_TOPIC, json.dumps(command))
    print("⏱️  Sent invalid wait command (500 seconds - should fail)")
    
    time.sleep(2)

def test_fractional_wait(client):
    """Test fractional seconds wait"""
    print("\n🧪 Testing fractional seconds wait (2.5 seconds)...")
    
    command = {
        "command": "wait",
        "seconds": 2.5,
        "response_topic": RESPONSE_TOPIC
    }
    
    start_time = time.time()
    client.publish(COMMAND_TOPIC, json.dumps(command))
    print(f"⏱️  Sent fractional wait command at {datetime.now().strftime('%H:%M:%S.%f')[:-3]}")
    
    time.sleep(4)
    end_time = time.time()
    print(f"✅ Fractional test completed in {end_time - start_time:.2f} seconds")

def main():
    print("🚀 MQTT Wait Command Test Script")
    print("=" * 50)
    
    # Create MQTT client
    client = mqtt.Client()
    client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    client.on_connect = on_connect
    client.on_message = on_message
    
    try:
        # Connect to MQTT broker
        print(f"Connecting to MQTT broker: {MQTT_BROKER}:{MQTT_PORT}")
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        
        # Wait for connection
        time.sleep(2)
        
        # Run tests
        test_single_wait_command(client)
        test_fractional_wait(client)
        test_invalid_wait_command(client)
        test_batch_wait_commands(client)
        
        print("\n✅ All tests completed!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    
    finally:
        client.loop_stop()
        client.disconnect()
        print("🔌 Disconnected from MQTT broker")

if __name__ == "__main__":
    main()
