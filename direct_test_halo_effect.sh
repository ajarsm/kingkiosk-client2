#!/bin/bash

# Direct test script for Halo Effect feature in KingKiosk - works without MQTT
# This script directly calls the API to test halo effect

echo "🧪 Starting Direct Halo Effect Test (No MQTT)..."

# Create a log file
LOG_FILE="direct_halo_effect_test.log"
echo "📝 Log file: $LOG_FILE"
> $LOG_FILE

# Function to directly launch flutter with a specific command
run_test() {
  NAME=$1
  CMD=$2
  echo "🧪 Test: $NAME" | tee -a $LOG_FILE
  echo "Running: $CMD" | tee -a $LOG_FILE
  echo "$CMD" > .temp_halo_cmd.dart
  echo "⏱️ Waiting to observe effect..." | tee -a $LOG_FILE
  sleep 3
}

# Prepare the app directory
cd /Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk

# Test Case 1: Red Halo Effect (Alarm Armed)
run_test "Red Halo Effect (Alarm Armed)" "import 'package:flutter/material.dart'; enableHaloEffect(color: Colors.red);"

# Test Case 2: Green Gentle Pulse Effect (Alarm Disarmed)
run_test "Green Gentle Pulse (Alarm Disarmed)" "import 'package:flutter/material.dart'; enableHaloEffect(color: Colors.green, pulseMode: HaloPulseMode.gentle, pulseDuration: Duration(milliseconds: 4000));"

# Test Case 3: Blue Away Mode
run_test "Blue Away Mode" "import 'package:flutter/material.dart'; enableHaloEffect(color: Colors.blue, intensity: 0.6);"

# Test Case 4: Red Alert Flash (Alarm Triggered)
run_test "Red Alert Flash (Alarm Triggered)" "import 'package:flutter/material.dart'; enableHaloEffect(color: Colors.red, pulseMode: HaloPulseMode.alert, pulseDuration: Duration(milliseconds: 1000), intensity: 0.9);"

# Test Case 5: Yellow Warning (Low Battery)
run_test "Yellow Warning (Low Battery)" "import 'package:flutter/material.dart'; enableHaloEffect(color: Color(0xFFFFCC00), pulseMode: HaloPulseMode.moderate, pulseDuration: Duration(milliseconds: 2000));"

# Test Case 6: Purple Night Mode
run_test "Purple Night Mode" "import 'package:flutter/material.dart'; enableHaloEffect(color: Color(0xFF9900FF), intensity: 0.5);"

# Test Case 7: Disable Halo Effect
run_test "Disable Halo Effect" "disableHaloEffect();"

echo "🧹 Test complete"
echo "Use this script to directly test the halo effect functionality"
echo "Check the log file for details: $LOG_FILE"

# Clean up
rm -f .temp_halo_cmd.dart

echo "💡 To manually test in Dart code:"
echo '1. Get the controller: final haloController = Get.find<HaloEffectControllerGetx>();'
echo '2. Enable: haloController.enableHaloEffect(color: Colors.red, pulseMode: HaloPulseMode.alert);'
echo '3. Disable: haloController.disableHaloEffect();'
