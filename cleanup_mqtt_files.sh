#!/bin/zsh

# Cleanup script for MQTT implementation
# This script removes unnecessary MQTT-related files that were consolidated

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "${BLUE}=======================================${NC}"
echo "${BLUE}  Flutter GetX Kiosk - MQTT Cleanup   ${NC}"
echo "${BLUE}=======================================${NC}"
echo ""

# List of files to delete (after consolidation)
FILES_TO_DELETE=(
  "lib/app/services/mqtt_service_checker.dart"
  "lib/app/modules/settings/views/mqtt_settings_view_fixed_3.dart"
)

# Check if files exist and delete them
for file in "${FILES_TO_DELETE[@]}"; do
  if [[ -f "$file" ]]; then
    echo "${YELLOW}Removing${NC} $file"
    rm "$file"
    if [[ $? -eq 0 ]]; then
      echo "${GREEN}✓ Successfully removed${NC}"
    else
      echo "${RED}✗ Failed to remove${NC}"
    fi
  else
    echo "${BLUE}File not found:${NC} $file"
  fi
done

echo ""
echo "${GREEN}Cleanup complete!${NC}"
echo "${YELLOW}Note:${NC} mqtt_service_fixed.dart is still present for backward compatibility"
echo "      but should be removed in future updates after all references are updated."
echo ""
