#!/bin/bash

# Debug script for Halo Effect feature in KingKiosk
# This script helps verify that the Halo Effect is properly implemented

echo "🔍 Starting Halo Effect Debug..."

# Check if the necessary files exist
echo "Checking Halo Effect implementation files:"

# Check for HaloEffectOverlay widget
if [ -f "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/widgets/halo_effect/halo_effect_overlay.dart" ]; then
  echo "✅ HaloEffectOverlay widget exists"
else
  echo "❌ HaloEffectOverlay widget is missing"
fi

# Check for HaloEffectController
if [ -f "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/controllers/halo_effect_controller.dart" ]; then
  echo "✅ HaloEffectController exists"
else
  echo "❌ HaloEffectController is missing"
fi

# Check if HaloEffectController is registered in InitialBinding
if grep -q "HaloEffectControllerGetx" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/core/bindings/initial_binding.dart"; then
  echo "✅ HaloEffectControllerGetx is registered in InitialBinding"
else
  echo "❌ HaloEffectControllerGetx is not registered in InitialBinding"
fi

# Check if halo_effect command is implemented in MQTT service
if grep -q "_processHaloEffectCommand" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/mqtt_service_consolidated.dart"; then
  echo "✅ halo_effect command handler is implemented in MQTT service"
else
  echo "❌ halo_effect command handler is missing from MQTT service"
fi

# Check if AnimatedHaloEffect is used in main.dart
if grep -q "AnimatedHaloEffect" "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/main.dart"; then
  echo "✅ AnimatedHaloEffect is integrated into the main app"
else
  echo "❌ AnimatedHaloEffect is not integrated into the main app"
fi

# Check if documentation exists
if [ -f "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/docs/halo_effect_feature.md" ]; then
  echo "✅ Halo Effect documentation exists"
else
  echo "❌ Halo Effect documentation is missing"
fi

# Check if test script exists
if [ -f "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/test_halo_effect.sh" ]; then
  echo "✅ Halo Effect test script exists"
  if [ -x "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/test_halo_effect.sh" ]; then
    echo "✅ Halo Effect test script is executable"
  else
    echo "❌ Halo Effect test script is not executable"
  fi
else
  echo "❌ Halo Effect test script is missing"
fi

echo ""
echo "Verification complete! If all checks passed, the Halo Effect feature should be properly implemented."
echo "Run the app and test with the test_halo_effect.sh script to verify functionality."
