#!/bin/zsh
# Troubleshoot plugin issues for Android builds

# Check if project path is provided, otherwise use default
PROJECT_PATH=${1:-"/Users/raj/dev/kingkiosk-client2/flutter_getx_kiosk"}
cd "$PROJECT_PATH" || { echo "Cannot access project directory"; exit 1; }

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}Plugin Troubleshooting Script${NC}"
echo -e "${BLUE}====================================${NC}"

# Function to check plugin health
check_plugin() {
  local plugin_name=$1
  local plugin_path=$2
  
  echo -e "\n${YELLOW}Checking $plugin_name...${NC}"
  
  if [ -d "$plugin_path" ]; then
    echo -e "${GREEN}✓ Plugin found at $plugin_path${NC}"
    
    # Check build.gradle
    if [ -f "$plugin_path/android/build.gradle" ]; then
      echo -e "${GREEN}✓ build.gradle file exists${NC}"
      
      # Check for namespace
      if grep -q "namespace" "$plugin_path/android/build.gradle"; then
        echo -e "${GREEN}✓ Namespace is defined in build.gradle${NC}"
      else
        echo -e "${RED}✗ Namespace is NOT defined in build.gradle${NC}"
        echo -e "${YELLOW}This could cause build issues. Consider patching this plugin.${NC}"
      fi
      
      # Check Kotlin version
      if grep -q "kotlin_version" "$plugin_path/android/build.gradle"; then
        local kotlin_version=$(grep "kotlin_version" "$plugin_path/android/build.gradle" | head -1)
        echo -e "${GREEN}✓ Kotlin version: $kotlin_version${NC}"
      fi
      
    else
      echo -e "${RED}✗ build.gradle file not found${NC}"
    fi
  else
    echo -e "${RED}✗ Plugin not found at $plugin_path${NC}"
  fi
}

# Function to fix all common plugin issues
fix_all_plugins() {
  echo -e "\n${BLUE}Applying fixes to all problematic plugins...${NC}"
  
  # Run the patch script
  if [ -f "./apply_plugin_patches.sh" ]; then
    echo -e "${YELLOW}Running apply_plugin_patches.sh...${NC}"
    ./apply_plugin_patches.sh
  else
    echo -e "${RED}✗ apply_plugin_patches.sh not found${NC}"
  fi
}

# Check problematic plugins
PLUGIN_BASE_PATH="/Users/raj/.pub-cache/hosted/pub.dev"
check_plugin "image_gallery_saver" "$PLUGIN_BASE_PATH/image_gallery_saver-2.0.3"

# Ask if user wants to fix all plugins
echo -e "\n${YELLOW}Do you want to apply fixes to all problematic plugins? (y/n)${NC}"
read -r apply_fix

if [[ $apply_fix =~ ^[Yy]$ ]]; then
  fix_all_plugins
  
  # Ask if user wants to run the app after fixing
  echo -e "\n${YELLOW}Do you want to run the app now? (y/n)${NC}"
  read -r run_app
  
  if [[ $run_app =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Running app...${NC}"
    ./run_android.sh
  fi
else
  echo -e "${BLUE}No fixes applied. You can apply them later using ./apply_plugin_patches.sh${NC}"
fi

echo -e "\n${BLUE}Troubleshooting completed.${NC}"
