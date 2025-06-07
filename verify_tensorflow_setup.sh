#!/bin/bash

# Verification script for TensorFlow Lite setup
echo "🔍 Verifying TensorFlow Lite setup..."

echo "=== Source Libraries in Project Root ==="
ls -la *.dylib *.dll 2>/dev/null || echo "❌ No libraries found in project root"

echo -e "\n=== Target Libraries in macOS Resources ==="
if [ -d "macos/Runner/Resources" ]; then
    ls -la macos/Runner/Resources/*.dylib 2>/dev/null || echo "❌ No libraries found in macOS Resources"
else
    echo "❌ macOS Resources directory not found"
fi

echo -e "\n=== TensorFlow Lite Models ==="
if [ -d "assets/models" ]; then
    ls -la assets/models/*.tflite 2>/dev/null || echo "❌ No .tflite models found"
else
    echo "❌ Models directory not found"
fi

echo -e "\n=== Build Scripts ==="
echo "restore_libraries.sh: $([ -x "restore_libraries.sh" ] && echo "✅ Executable" || echo "❌ Not executable")"
echo "flutter_clean_with_restore.sh: $([ -x "flutter_clean_with_restore.sh" ] && echo "✅ Executable" || echo "❌ Not executable")"
echo "macos/copy_tflite_libs.sh: $([ -x "macos/copy_tflite_libs.sh" ] && echo "✅ Executable" || echo "❌ Not executable")"

echo -e "\n=== pubspec.yaml Configuration ==="
if grep -q "tflite_flutter" pubspec.yaml; then
    echo "✅ tflite_flutter dependency found"
else
    echo "❌ tflite_flutter dependency missing"
fi

if grep -q "assets/models/" pubspec.yaml; then
    echo "✅ Models assets configured"
else
    echo "❌ Models assets not configured"
fi

echo -e "\n=== Summary ==="
echo "📱 TensorFlow Lite libraries are $([ -f "libtensorflowlite_c.dylib" ] && echo "✅ PRESENT" || echo "❌ MISSING")"
echo "🧠 ML models are $([ -f "assets/models/person_detect.tflite" ] && echo "✅ AVAILABLE" || echo "❌ MISSING")"
echo "🛠️ Build scripts are $([ -x "restore_libraries.sh" ] && echo "✅ READY" || echo "❌ NOT READY")"

echo -e "\n💡 To restore libraries after 'flutter clean', run:"
echo "   ./flutter_clean_with_restore.sh  (Enhanced clean with auto-restore)"
echo "   OR"
echo "   flutter clean && ./restore_libraries.sh && flutter pub get"
