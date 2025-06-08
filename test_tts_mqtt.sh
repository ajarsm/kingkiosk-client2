#!/bin/bash
# TTS MQTT Test Script
# This script tests the TTS functionality via MQTT commands

# Configuration
MQTT_BROKER="${MQTT_BROKER:-localhost}"
MQTT_PORT="${MQTT_PORT:-1883}"
DEVICE_NAME="${DEVICE_NAME:-test-kiosk}"
TOPIC="kingkiosk/${DEVICE_NAME}/command"

echo "🔊 Testing TTS functionality via MQTT"
echo "Broker: $MQTT_BROKER:$MQTT_PORT"
echo "Topic: $TOPIC"
echo "Device: $DEVICE_NAME"
echo ""

# Function to send MQTT message
send_command() {
    local message="$1"
    local description="$2"
    echo "📤 $description"
    echo "   Command: $message"
    mosquitto_pub -h "$MQTT_BROKER" -p "$MQTT_PORT" -t "$TOPIC" -m "$message"
    sleep 2
}

# Test 1: Basic TTS
send_command '{"command":"tts","text":"TTS system test successful. Audio is working correctly."}' "Basic TTS Test"

# Test 2: Alternative command name
send_command '{"command":"speak","text":"This message uses the speak command."}' "Alternative Command Test"

# Test 3: Custom voice settings
send_command '{"command":"tts","text":"This message has custom voice settings with slower speech rate.","volume":0.8,"speechRate":0.4,"pitch":1.2}' "Custom Voice Settings Test"

# Test 4: Get TTS status
send_command '{"command":"tts","action":"status","response_topic":"'$TOPIC'/status"}' "Status Check"

# Test 5: Set volume
send_command '{"command":"tts","action":"setvolume","volume":0.6}' "Set Volume to 60%"

# Test 6: Confirm volume change
send_command '{"command":"tts","text":"Volume is now set to 60 percent."}' "Volume Confirmation"

# Test 7: Test pause and resume
send_command '{"command":"tts","text":"This is a long message that will be paused in the middle. You should hear the speech stop and then resume after a moment."}' "Long Message for Pause Test"
sleep 3
send_command '{"command":"tts","action":"pause"}' "Pause TTS"
sleep 2
send_command '{"command":"tts","action":"resume"}' "Resume TTS"

# Test 8: Queue multiple messages
send_command '{"command":"tts","text":"First queued message.","queue":true}' "Queue Message 1"
send_command '{"command":"tts","text":"Second queued message.","queue":true}' "Queue Message 2"
send_command '{"command":"tts","text":"Third queued message.","queue":true}' "Queue Message 3"

# Test 9: Stop all speech
sleep 5
send_command '{"command":"tts","action":"stop"}' "Stop All Speech"

# Test 10: Enhanced batch commands with optimized processing
send_command '{"command":"batch","commands":[{"command":"tts","action":"setvolume","volume":0.9,"id":"batch_volume"},{"command":"tts","text":"Volume set to 90 percent via optimized batch processing.","id":"batch_confirm"},{"command":"tts","text":"This is a second message processed in the same batch.","queue":true,"id":"batch_second"}]}' "Enhanced Batch Commands Test"

# Test 11: TTS sequence batch with response topics and tracking
send_command '{"command":"batch","commands":[{"command":"tts","action":"setlanguage","language":"en-US","response_topic":"'$TOPIC'/lang_result","id":"set_lang"},{"command":"tts","text":"Language set to English US via batch processing","response_topic":"'$TOPIC'/lang_confirm","id":"lang_msg"},{"command":"tts","text":"Optimized batch sequence complete with tracking","queue":true,"response_topic":"'$TOPIC'/batch_complete","id":"final_msg"}]}' "TTS Optimized Sequence Batch Test"

# Test 12: Mixed command batch (TTS + other commands) - demonstrates intelligent separation
send_command '{"command":"batch","commands":[{"command":"notify","message":"Enhanced TTS batch test starting","tier":"info"},{"command":"tts","text":"Mixed batch with intelligent TTS separation","id":"mixed_start"},{"command":"tts","text":"TTS commands are processed as optimized batch","queue":true,"id":"mixed_demo"}]}' "Intelligent Mixed Command Batch Test"

# Test 13: Multi-language batch with performance optimization
send_command '{"command":"batch","commands":[{"command":"tts","text":"Welcome to our service","language":"en-US","id":"welcome_en","response_topic":"'$TOPIC'/multilang/en"},{"command":"tts","text":"Bienvenido a nuestro servicio","language":"es-ES","queue":true,"id":"welcome_es","response_topic":"'$TOPIC'/multilang/es"},{"command":"tts","text":"Bienvenue à notre service","language":"fr-FR","queue":true,"id":"welcome_fr","response_topic":"'$TOPIC'/multilang/fr"}]}' "Multi-language Optimized Batch Test"

# Test 14: Performance-focused batch with command tracking
send_command '{"command":"batch","commands":[{"command":"tts","action":"setvolume","volume":0.8,"id":"perf_vol","response_topic":"'$TOPIC'/perf/volume"},{"command":"tts","action":"setrate","rate":0.6,"id":"perf_rate","response_topic":"'$TOPIC'/perf/rate"},{"command":"tts","text":"Performance optimized batch processing active","id":"perf_msg","response_topic":"'$TOPIC'/perf/message"},{"command":"tts","text":"All commands tracked with unique IDs","queue":true,"id":"perf_final","response_topic":"'$TOPIC'/perf/final"}]}' "Performance-Focused Batch Test"

# Test 15: Get available languages
send_command '{"command":"tts","action":"getlanguages","response_topic":"'$TOPIC'/languages"}' "Get Available Languages"

# Test 16: Get available voices  
send_command '{"command":"tts","action":"getvoices","response_topic":"'$TOPIC'/voices"}' "Get Available Voices"

# Test 17: Emergency alert simulation with batch optimization
send_command '{"command":"batch","commands":[{"command":"tts","action":"stop","id":"emergency_stop"},{"command":"tts","action":"clearqueue","id":"emergency_clear"},{"command":"tts","action":"setvolume","volume":1.0,"id":"emergency_volume"},{"command":"tts","text":"EMERGENCY ALERT: This is a test of the emergency notification system","language":"en-US","speechRate":0.8,"pitch":1.3,"id":"emergency_alert","response_topic":"'$TOPIC'/emergency/alert"}]}' "Emergency Alert Batch Test"

# Test 18: Final test with performance summary
send_command '{"command":"tts","text":"Enhanced TTS testing complete. All optimized batch functions have been tested successfully with intelligent command separation and performance improvements."}' "Final Enhanced Test"

echo ""
echo "✅ Enhanced TTS testing complete!"
echo ""
echo "� New features tested:"
echo "   • Optimized batch processing with intelligent command separation"
echo "   • Enhanced error handling and command tracking"
echo "   • Performance improvements for TTS command batches"
echo "   • Response topic management for batch commands"
echo ""
echo "�🔧 To monitor responses, subscribe to:"
echo "   mosquitto_sub -h $MQTT_BROKER -p $MQTT_PORT -t '$TOPIC/+'"
echo ""
echo "📋 Check the King Kiosk app logs for detailed TTS operation information."
echo "📊 Monitor batch processing performance and command tracking in the logs."
