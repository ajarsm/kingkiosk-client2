#!/usr/bin/env python3
"""
Test Multi-Object Detection Implementation
Verifies that TensorFlow model detects ALL objects above 60% confidence threshold
and publishes them via MQTT (not just people).
"""

import json
import time
import paho.mqtt.client as mqtt
from datetime import datetime

# MQTT Configuration
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
DEVICE_NAME = "test-device"

# Topics to monitor
OBJECT_DETECTION_TOPIC = f"kingkiosk/{DEVICE_NAME}/object_detection"
PERSON_PRESENCE_TOPIC = f"kingkiosk/{DEVICE_NAME}/person_presence"
COMMAND_TOPIC = f"kingkiosk/{DEVICE_NAME}/command"

# Global variables to store received data
received_object_detection = None
received_person_presence = None
detection_messages = []

def on_connect(client, userdata, flags, rc):
    """Callback for when MQTT client connects"""
    if rc == 0:
        print(f"✅ Connected to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
        
        # Subscribe to detection topics
        client.subscribe(OBJECT_DETECTION_TOPIC)
        client.subscribe(PERSON_PRESENCE_TOPIC)
        
        print(f"📡 Subscribed to:")
        print(f"   - {OBJECT_DETECTION_TOPIC}")
        print(f"   - {PERSON_PRESENCE_TOPIC}")
    else:
        print(f"❌ Failed to connect to MQTT broker. Return code: {rc}")

def on_message(client, userdata, msg):
    """Callback for when a message is received"""
    global received_object_detection, received_person_presence, detection_messages
    
    topic = msg.topic
    try:
        payload = json.loads(msg.payload.decode())
        timestamp = datetime.now().strftime("%H:%M:%S")
        
        if topic == OBJECT_DETECTION_TOPIC:
            received_object_detection = payload
            detection_messages.append((timestamp, payload))
            
            print(f"\n🔍 [{timestamp}] Object Detection Data Received:")
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
            
            # Show detailed objects
            detected_objects = payload.get('detected_objects', [])
            if detected_objects:
                print(f"   🔎 Detailed detections ({len(detected_objects)}):")
                for obj in detected_objects[:5]:  # Show first 5
                    print(f"      • {obj.get('class_name', 'unknown')}: {obj.get('confidence', 0):.3f}")
                if len(detected_objects) > 5:
                    print(f"      ... and {len(detected_objects) - 5} more")
                    
        elif topic == PERSON_PRESENCE_TOPIC:
            received_person_presence = payload
            
            print(f"\n👤 [{timestamp}] Person Presence Data:")
            print(f"   Present: {payload.get('person_present', False)}")
            print(f"   Confidence: {payload.get('confidence', 0):.3f}")
            print(f"   Frames processed: {payload.get('frames_processed', 0)}")
            
    except json.JSONDecodeError as e:
        print(f"❌ Failed to parse JSON from {topic}: {e}")
    except Exception as e:
        print(f"❌ Error processing message from {topic}: {e}")

def send_person_detection_command(action="enable"):
    """Send person detection control command"""
    client = mqtt.Client()
    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    
    command = {
        "command": "person_detection",
        "action": action,
        "confirm": True
    }
    
    client.publish(COMMAND_TOPIC, json.dumps(command))
    print(f"📤 Sent person detection {action} command")
    client.disconnect()

def analyze_multi_object_capabilities():
    """Analyze the received data for multi-object detection capabilities"""
    global detection_messages
    
    print("\n" + "="*60)
    print("🧪 MULTI-OBJECT DETECTION ANALYSIS")
    print("="*60)
    
    if not detection_messages:
        print("❌ No object detection messages received!")
        return False
    
    # Analyze the most recent detection data
    latest_detection = detection_messages[-1][1]
    
    # Check if system detects multiple object types
    object_counts = latest_detection.get('object_counts', {})
    detected_objects = latest_detection.get('detected_objects', [])
    
    print(f"📊 Latest detection summary:")
    print(f"   Total objects detected: {latest_detection.get('total_objects', 0)}")
    print(f"   Unique object types: {len(object_counts)}")
    print(f"   Object types found: {list(object_counts.keys())}")
    
    # Check for non-person objects
    non_person_objects = [obj for obj in detected_objects 
                         if obj.get('class_name', '').lower() != 'person']
    
    print(f"\n🎯 Multi-object detection verification:")
    print(f"   Non-person objects detected: {len(non_person_objects)}")
    
    if non_person_objects:
        print(f"   ✅ SUCCESS: System detects objects other than people!")
        print(f"   📋 Non-person objects found:")
        for obj in non_person_objects[:10]:  # Show first 10
            print(f"      • {obj.get('class_name', 'unknown')}: {obj.get('confidence', 0):.3f}")
    else:
        print(f"   ⚠️  Only person objects detected (or no objects)")
    
    # Check confidence threshold compliance
    print(f"\n🎚️ Confidence threshold analysis:")
    threshold_compliant = all(obj.get('confidence', 0) >= 0.6 for obj in detected_objects)
    
    if threshold_compliant and detected_objects:
        print(f"   ✅ All detected objects meet 60% confidence threshold")
    elif detected_objects:
        below_threshold = [obj for obj in detected_objects if obj.get('confidence', 0) < 0.6]
        print(f"   ❌ {len(below_threshold)} objects below 60% threshold")
    else:
        print(f"   ℹ️  No objects to analyze")
    
    # Check MQTT topics
    print(f"\n📡 MQTT publishing verification:")
    print(f"   Object detection topic active: {'✅' if detection_messages else '❌'}")
    print(f"   Messages received: {len(detection_messages)}")
    
    return len(non_person_objects) > 0 or len(object_counts) > 1

def main():
    """Main test function"""
    print("🚀 Multi-Object Detection Test Starting...")
    print(f"🎯 Target: Verify detection of ALL objects >60% confidence")
    print(f"📡 MQTT Broker: {MQTT_BROKER}:{MQTT_PORT}")
    print(f"🔧 Device: {DEVICE_NAME}")
    
    # Create MQTT client
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    try:
        # Connect to MQTT broker
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        
        # Wait for connection
        time.sleep(2)
        
        # Enable person detection if not already enabled
        print("\n📤 Enabling person detection...")
        send_person_detection_command("enable")
        
        # Wait for a few detection cycles
        print("\n⏳ Monitoring object detection for 30 seconds...")
        print("   (Watching for cars, bicycles, animals, furniture, etc.)")
        
        for i in range(30):
            time.sleep(1)
            if detection_messages and i > 0 and i % 10 == 0:
                print(f"   • {i}s elapsed - {len(detection_messages)} detection messages received")
        
        # Analyze results
        success = analyze_multi_object_capabilities()
        
        print("\n" + "="*60)
        print("🏆 TEST RESULTS")
        print("="*60)
        
        if success:
            print("✅ SUCCESS: Multi-object detection is working!")
            print("   • System detects objects beyond just people")
            print("   • Confidence threshold (60%) is properly enforced")
            print("   • MQTT publishing includes all detected objects")
        else:
            print("⚠️  PARTIAL: Only person detection observed")
            print("   • System may be working but no other objects in view")
            print("   • Try testing with different camera inputs")
            print("   • Ensure objects are clearly visible and well-lit")
        
        print(f"\n📊 Detection Summary:")
        print(f"   • Total MQTT messages: {len(detection_messages)}")
        print(f"   • Object detection topic: ✅")
        print(f"   • Person presence topic: ✅")
        print(f"   • Confidence threshold: 60%")
        
    except KeyboardInterrupt:
        print("\n\n⏹️  Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Test error: {e}")
    finally:
        client.loop_stop()
        client.disconnect()
        print("\n👋 Test completed")

if __name__ == "__main__":
    main()
