#!/bin/zsh

# Script to safely delete unused files in the Flutter GetX Kiosk project
# Created on: May 12, 2025

echo "Deleting unused files from Flutter GetX Kiosk project..."

# List of files to be deleted
declare -a FILES_TO_DELETE=(
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/mqtt_service_fixed.dart"
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/mqtt_service_checker.dart"
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/routes/app_pages.dart"
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/fixed_module.dart"
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/settings/controllers/settings_controller_fixed_2.dart"
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/settings/bindings/fixed_settings_binding.dart"
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/settings/views/mqtt_settings_view_fixed.dart"
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/settings/views/mqtt_settings_view_fixed_3.dart"
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/modules/home/bindings/home_binding.dart"
  "/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk/lib/app/services/service_bindings.dart"
)

# Delete each file if it exists
for file in "${FILES_TO_DELETE[@]}"; do
  if [ -f "$file" ]; then
    rm "$file"
    echo "✅ Deleted: $file"
  else
    echo "❌ Not found: $file"
  fi
done

echo ""
echo "Done! Removed unused files."
echo "Note: If you encounter any build errors, check for any remaining references to the deleted files."
