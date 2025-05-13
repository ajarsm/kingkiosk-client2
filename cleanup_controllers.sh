#!/bin/bash

# Remove duplicate controller files
echo "Deleting redundant controller files..."

# Safety check for required files before deletion
if [ -f "./lib/app/modules/settings/controllers/settings_controller.dart" ] && [ -f "./lib/app/modules/settings/controllers/settings_controller_compat.dart" ]; then
    # Delete redundant files
    rm -f "./lib/app/modules/settings/controllers/settings_controller_fixed.dart"
    rm -f "./lib/app/modules/settings/controllers/settings_controller_fixed_2.dart"
    echo "Redundant controller files deleted successfully."
else
    echo "ERROR: Required files not found. Aborting delete operation."
    echo "Ensure these files exist before running this script:"
    echo "- lib/app/modules/settings/controllers/settings_controller.dart"
    echo "- lib/app/modules/settings/controllers/settings_controller_compat.dart"
    exit 1
fi

echo "Controller cleanup completed."
