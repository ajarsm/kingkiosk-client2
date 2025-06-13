#!/usr/bin/env python3
"""
Test Object Detection MQTT Publishing
Quick test to verify that person and object detection is publishing to MQTT
"""
import json
import time
import paho.mqtt.client as mqtt
from datetime import datetime

# MQTT Configuration
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
DEVICE_NAME = "kingkiosk-device"  # Adjust this to match your device name

# Topics to monitor
OBJECT_DETECTION_TOPIC = f"kingkiosk/{DEVICE_NAME}/object_detection"
PERSON_PRESENCE_TOPIC = f"kingkiosk/{DEVICE_NAME}/person_presence"

def on_connect(client, userdata, flags, rc):
    """Callback for when MQTT client connects"""
    if rc == 0:
        print(f"✅ Connected to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
        client.subscribe(OBJECT_DETECTION_TOPIC)
        client.subscribe(PERSON_PRESENCE_TOPIC)
        print(f"📡 Subscribed to:")
        print(f"   - {OBJECT_DETECTION_TOPIC}")
        print(f"   - {PERSON_PRESENCE_TOPIC}")
    else:
        print(f"❌ Failed to connect to MQTT broker. Return code: {rc}")

def on_message(client, userdata, msg):
    """Callback for when a message is received"""
    topic = msg.topic
    try:
        payload = json.loads(msg.payload.decode())
        timestamp = datetime.now().strftime("%H:%M:%S")
        
        if topic == OBJECT_DETECTION_TOPIC:
            print(f"\n🔍 [{timestamp}] Object Detection Data:")
            print(f"   📊 Total objects: {payload.get('total_objects', 0)}")
            print(f"   🎯 Any object detected: {payload.get('any_object_detected', False)}")
            print(f"   👤 Person present: {payload.get('person_present', False)}")
            print(f"   📈 Person confidence: {payload.get('person_confidence', 0):.3f}")
            
            # Show object counts
            object_counts = payload.get('object_counts', {})
            if object_counts:
                print(f"   📋 Detected object types:")
                for obj_type, count in object_counts.items():
                    confidence = payload.get('object_confidences', {}).get(obj_type, 0)
                    print(f"      • {obj_type}: {count} (max confidence: {confidence:.3f})")
            
            # Show detailed objects (first 5)
            detected_objects = payload.get('detected_objects', [])
            if detected_objects:
                print(f"   🔎 Detailed detections ({len(detected_objects)}):")
                for obj in detected_objects[:5]:
                    print(f"      • {obj.get('class_name', 'unknown')}: {obj.get('confidence', 0):.3f}")
                if len(detected_objects) > 5:
                    print(f"      ... and {len(detected_objects) - 5} more")
                    
        elif topic == PERSON_PRESENCE_TOPIC:
            print(f"\n👤 [{timestamp}] Person Presence:")
            print(f"   Present: {payload.get('person_present', False)}")
            print(f"   Confidence: {payload.get('confidence', 0):.3f}")
            print(f"   Frames processed: {payload.get('frames_processed', 0)}")
            
    except Exception as e:
        print(f"❌ Error parsing message: {e}")
        print(f"   Raw payload: {msg.payload.decode()}")

def main():
    """Main test function"""
    print("🚀 Object Detection MQTT Test Starting...")
    print(f"📡 MQTT Broker: {MQTT_BROKER}:{MQTT_PORT}")
    print(f"🔧 Device: {DEVICE_NAME}")
    print("\nMake sure:")
    print("1. KingKiosk app is running")
    print("2. MQTT broker is running")
    print("3. Person detection is enabled")
    print("4. Device name matches in the app")
    
    # Create MQTT client
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    try:
        # Connect to MQTT broker
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        
        # Wait for messages
        print("\n⏳ Waiting for object detection messages...")
        print("   (Wave your hand or move objects in front of the camera)")
        
        # Run for 60 seconds
        time.sleep(60)
        
    except KeyboardInterrupt:
        print("\n⏹️ Test stopped by user")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        client.loop_stop()
        client.disconnect()
        print("👋 Disconnected from MQTT broker")

if __name__ == "__main__":
    main()
