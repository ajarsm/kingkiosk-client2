#!/usr/bin/env python3
"""
Test script for the MQTT alert auto-dismiss functionality.
This script sends various alert commands with auto-dismiss timers to test the new feature.
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

def send_alert(client, title, message, position="center", alert_type="info", auto_dismiss_seconds=None, **kwargs):
    """Send an alert command with auto-dismiss functionality"""
    payload = {
        "command": "alert",
        "title": title,
        "message": message,
        "type": alert_type,
        "position": position,
        "sound": True,
        "is_html": False
    }
    
    if auto_dismiss_seconds is not None:
        payload["auto_dismiss_seconds"] = auto_dismiss_seconds
    
    # Add any additional parameters
    payload.update(kwargs)
    
    client.publish(TOPIC, json.dumps(payload))
    auto_text = f" (auto-dismiss: {auto_dismiss_seconds}s)" if auto_dismiss_seconds else " (manual dismiss)"
    print(f"📨 Sent {alert_type} alert to {position}{auto_text}: '{title}'")

def test_auto_dismiss_functionality():
    """Test auto-dismiss alerts with different timers and positions"""
    client = mqtt.Client()
    client.on_connect = on_connect
    
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        
        # Wait for connection
        time.sleep(2)
        
        print("\n🔔 Testing Auto-Dismiss Alert Functionality")
        print("=" * 55)
        
        # Test 1: Quick 3-second auto-dismiss
        print("\n📱 Test 1: Quick 3-second auto-dismiss")
        send_alert(client, 
                  "Quick Alert", 
                  "This alert will disappear in 3 seconds with a visual countdown", 
                  position="top-right", 
                  alert_type="info",
                  auto_dismiss_seconds=3)
        time.sleep(4)
        
        # Test 2: Standard 5-second auto-dismiss with custom border
        print("\n📱 Test 2: 5-second auto-dismiss with custom border")
        send_alert(client, 
                  "Auto-Dismiss Alert", 
                  "Watch the circular progress indicator count down from 5 seconds", 
                  position="center", 
                  alert_type="warning",
                  auto_dismiss_seconds=5,
                  border_color="#ff6b35")
        time.sleep(6)
        
        # Test 3: Longer 10-second auto-dismiss
        print("\n📱 Test 3: Extended 10-second auto-dismiss")
        send_alert(client, 
                  "Extended Timer", 
                  "This alert has a longer 10-second countdown timer for important messages", 
                  position="bottom-left", 
                  alert_type="error",
                  auto_dismiss_seconds=10)
        time.sleep(11)
        
        # Test 4: Manual dismiss (no auto-dismiss)
        print("\n📱 Test 4: Manual dismiss only (no timer)")
        send_alert(client, 
                  "Manual Dismiss", 
                  "This alert has no auto-dismiss timer and must be closed manually", 
                  position="center-right", 
                  alert_type="success")
        time.sleep(3)
        
        # Test 5: Very short 1-second auto-dismiss
        print("\n📱 Test 5: Minimal 1-second auto-dismiss")
        send_alert(client, 
                  "Flash Alert", 
                  "Quick flash notification", 
                  position="top-center", 
                  alert_type="info",
                  auto_dismiss_seconds=1,
                  show_border=False)
        time.sleep(2)
        
        # Test 6: HTML content with auto-dismiss
        print("\n📱 Test 6: HTML content with auto-dismiss")
        send_alert(client, 
                  "Rich Content Alert", 
                  "<h3>Auto-Dismiss HTML Alert</h3><p>This alert contains <strong>formatted HTML content</strong> and will auto-dismiss in <em>7 seconds</em>.</p><ul><li>Visual countdown indicator</li><li>Rich text formatting</li><li>Automatic dismissal</li></ul>", 
                  position="center", 
                  alert_type="info",
                  auto_dismiss_seconds=7,
                  is_html=True,
                  border_color="#3498db")
        time.sleep(8)
        
        print("\n✅ All auto-dismiss tests completed!")
        print("\nFeatures tested:")
        print("  ✓ 3, 5, 7, and 10-second auto-dismiss timers")
        print("  ✓ Visual countdown progress indicator")
        print("  ✓ Different positions with auto-dismiss")
        print("  ✓ Manual dismiss vs auto-dismiss comparison")
        print("  ✓ HTML content with auto-dismiss")
        print("  ✓ Custom border colors with timers")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    print("MQTT Auto-Dismiss Alert Test")
    print("This script tests the new auto-dismiss functionality with visual countdown indicators.")
    print(f"Target device: {DEVICE_NAME}")
    print(f"MQTT Broker: {MQTT_BROKER}:{MQTT_PORT}")
    print("\nMake sure your KingKiosk device is running and connected to MQTT.")
    
    response = input("\nPress Enter to start the auto-dismiss test, or 'q' to quit: ")
    if response.lower() != 'q':
        test_auto_dismiss_functionality()
    else:
        print("Test cancelled.")
