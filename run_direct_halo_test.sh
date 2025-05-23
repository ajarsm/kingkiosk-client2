#!/bin/bash

# Direct test for halo effect without using MQTT
# This test directly exercises the HaloEffectControllerGetx

echo "🧪 Running direct test of Halo Effect (bypassing MQTT)"
echo "This will test the controller's ability to handle both Color and MaterialColor"

cd "$(dirname "$0")"
flutter run -d macos test_direct_halo_effect.dart

echo -e "\n✅ Test completed"
