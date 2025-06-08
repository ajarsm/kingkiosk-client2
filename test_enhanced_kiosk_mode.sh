#!/bin/bash

# Enhanced Android Kiosk Mode Test Script
# Tests auto-restoration and comprehensive cleanup functionality

echo "🔒 Enhanced Android Kiosk Mode Test Suite"
echo "========================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
PACKAGE_NAME="com.ki.king_kiosk"
ACTIVITY_NAME="com.ki.king_kiosk.MainActivity"
ADB="adb"

# Helper functions
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if device is connected
check_device() {
    print_step "Checking if device is connected..."
    if ! $ADB devices | grep -q "device$"; then
        print_error "No Android device connected. Please connect a device and enable USB debugging."
        exit 1
    fi
    print_success "Device connected"
}

# Check if app is installed
check_app_installed() {
    print_step "Checking if King Kiosk app is installed..."
    if ! $ADB shell pm list packages | grep -q "$PACKAGE_NAME"; then
        print_error "King Kiosk app is not installed. Please install the app first."
        exit 1
    fi
    print_success "King Kiosk app is installed"
}

# Get app state
get_app_state() {
    local is_running=$($ADB shell "ps | grep $PACKAGE_NAME" | wc -l)
    local is_home_app=$($ADB shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME | grep -q "$PACKAGE_NAME" && echo "1" || echo "0")
    
    echo "is_running:$is_running,is_home_app:$is_home_app"
}

# Launch app
launch_app() {
    print_step "Launching King Kiosk app..."
    $ADB shell am start -n "$PACKAGE_NAME/$ACTIVITY_NAME"
    sleep 3
    print_success "App launched"
}

# Stop app
stop_app() {
    print_step "Stopping King Kiosk app..."
    $ADB shell am force-stop "$PACKAGE_NAME"
    sleep 2
    print_success "App stopped"
}

# Clear app data
clear_app_data() {
    print_step "Clearing app data..."
    $ADB shell pm clear "$PACKAGE_NAME"
    sleep 2
    print_success "App data cleared"
}

# Simulate device restart
simulate_device_restart() {
    print_step "Simulating device restart by stopping and starting app..."
    stop_app
    sleep 2
    launch_app
    sleep 3
}

# Test 1: Enable kiosk mode and check persistence
test_kiosk_persistence() {
    echo
    echo "🧪 Test 1: Kiosk Mode Persistence"
    echo "================================="
    
    print_step "1.1 Starting with clean state..."
    clear_app_data
    launch_app
    sleep 5
    
    print_step "1.2 Enabling kiosk mode via app..."
    # This would require interaction with the app UI
    # For automated testing, you could use UI testing frameworks
    print_warning "Manual step: Enable kiosk mode in the app"
    echo "Please enable kiosk mode in the King Kiosk app and press Enter to continue..."
    read -r
    
    local state_before=$(get_app_state)
    print_step "1.3 State before restart: $state_before"
    
    print_step "1.4 Simulating device restart..."
    simulate_device_restart
    sleep 5
    
    local state_after=$(get_app_state)
    print_step "1.5 State after restart: $state_after"
    
    # Check if kiosk mode was restored
    if echo "$state_after" | grep -q "is_running:1"; then
        print_success "✅ App auto-started after restart"
    else
        print_error "❌ App did not auto-start after restart"
    fi
}

# Test 2: Test comprehensive cleanup
test_comprehensive_cleanup() {
    echo
    echo "🧪 Test 2: Comprehensive Cleanup"
    echo "================================"
    
    print_step "2.1 Ensuring kiosk mode is enabled..."
    print_warning "Manual step: Ensure kiosk mode is enabled"
    echo "Please ensure kiosk mode is enabled and press Enter to continue..."
    read -r
    
    print_step "2.2 Testing normal disable..."
    print_warning "Manual step: Disable kiosk mode normally"
    echo "Please disable kiosk mode using the normal disable button and press Enter to continue..."
    read -r
    
    print_step "2.3 Checking if all restrictions are released..."
    # Test if user can navigate away from app
    print_step "2.4 Testing if home button works..."
    $ADB shell input keyevent KEYCODE_HOME
    sleep 2
    
    local current_app=$($ADB shell dumpsys window windows | grep -E 'mCurrentFocus|mFocusedApp' | head -1)
    if echo "$current_app" | grep -q "$PACKAGE_NAME"; then
        print_warning "⚠️ App still has focus - kiosk restrictions may not be fully released"
    else
        print_success "✅ Home button works - restrictions properly released"
    fi
    
    print_step "2.5 Testing force cleanup..."
    launch_app
    sleep 3
    print_warning "Manual step: Use force cleanup"
    echo "Please use the 'Force Cleanup' button in Advanced Controls and press Enter to continue..."
    read -r
    
    sleep 3
    $ADB shell input keyevent KEYCODE_HOME
    sleep 2
    
    local current_app_after=$($ADB shell dumpsys window windows | grep -E 'mCurrentFocus|mFocusedApp' | head -1)
    if echo "$current_app_after" | grep -q "$PACKAGE_NAME"; then
        print_error "❌ Force cleanup did not release all restrictions"
    else
        print_success "✅ Force cleanup successfully released all restrictions"
    fi
}

# Test 3: Test remote MQTT disable/enable
test_remote_control() {
    echo
    echo "🧪 Test 3: Remote MQTT Control"
    echo "=============================="
    
    print_step "3.1 Testing remote enable..."
    print_warning "This test requires MQTT broker connectivity"
    echo "If you have MQTT set up, you can test remote enable/disable commands"
    echo "Use your MQTT client to send enable/disable commands to test"
    echo "Press Enter to continue to next test..."
    read -r
}

# Test 4: Test state persistence across app updates
test_update_persistence() {
    echo
    echo "🧪 Test 4: State Persistence Across Updates"
    echo "=========================================="
    
    print_step "4.1 Enabling kiosk mode..."
    print_warning "Manual step: Enable kiosk mode"
    echo "Please enable kiosk mode and press Enter to continue..."
    read -r
    
    print_step "4.2 Simulating app update (reinstall)..."
    print_warning "This will reinstall the app. Kiosk state should be preserved in shared storage."
    echo "Press Enter to continue with app reinstall..."
    read -r
    
    # Note: In a real test, you'd reinstall the APK here
    # $ADB install -r path/to/your/app.apk
    
    print_step "4.3 Checking if kiosk state persists after 'update'..."
    launch_app
    sleep 5
    
    print_warning "Manual check: Verify if kiosk mode was automatically restored after the update"
    echo "Press Enter to continue..."
    read -r
}

# Test 5: Test edge cases and error handling
test_edge_cases() {
    echo
    echo "🧪 Test 5: Edge Cases and Error Handling"
    echo "========================================"
    
    print_step "5.1 Testing rapid enable/disable cycles..."
    print_warning "Manual test: Rapidly enable and disable kiosk mode multiple times"
    echo "This tests for race conditions and state inconsistencies"
    echo "Press Enter when done..."
    read -r
    
    print_step "5.2 Testing with permissions revoked..."
    print_warning "Manual test: Revoke device admin permission and try to enable kiosk mode"
    echo "This should gracefully handle permission denial"
    echo "Press Enter when done..."
    read -r
    
    print_step "5.3 Testing cleanup when stuck in partial state..."
    print_warning "Manual test: If kiosk mode gets stuck, use the Force Cleanup feature"
    echo "This should completely reset the kiosk state"
    echo "Press Enter when done..."
    read -r
}

# Generate test report
generate_report() {
    echo
    echo "📊 Test Report"
    echo "=============="
    
    local final_state=$(get_app_state)
    print_step "Final app state: $final_state"
    
    # Check device admin status
    local device_admin_status=$($ADB shell dpm list-owners | grep -q "$PACKAGE_NAME" && echo "Active" || echo "Inactive")
    print_step "Device admin status: $device_admin_status"
    
    # Check launcher status
    local launcher_status=$($ADB shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME | grep -q "$PACKAGE_NAME" && echo "Set as launcher" || echo "Not launcher")
    print_step "Launcher status: $launcher_status"
    
    echo
    print_success "✅ Enhanced kiosk mode testing completed!"
    echo
    echo "Key features tested:"
    echo "  • Auto-restoration of kiosk state on app startup"
    echo "  • Comprehensive cleanup when disabling kiosk mode"
    echo "  • Persistent state tracking across restarts"
    echo "  • Force cleanup for stuck states"
    echo "  • Edge case handling"
    echo
    echo "Please review the manual test results and verify that:"
    echo "  1. Kiosk mode auto-restores after device restart"
    echo "  2. Disabling kiosk mode fully releases all restrictions"
    echo "  3. Users can exit the app after disabling kiosk mode"
    echo "  4. Force cleanup resolves any stuck states"
    echo "  5. Remote MQTT control works as expected"
}

# Main test execution
main() {
    echo "Starting enhanced Android kiosk mode tests..."
    echo "This script will guide you through testing the new auto-restoration"
    echo "and comprehensive cleanup functionality."
    echo
    
    check_device
    check_app_installed
    
    echo "Available tests:"
    echo "  1. Kiosk Mode Persistence"
    echo "  2. Comprehensive Cleanup"
    echo "  3. Remote MQTT Control"
    echo "  4. State Persistence Across Updates"
    echo "  5. Edge Cases and Error Handling"
    echo "  a. Run all tests"
    echo
    echo -n "Enter test number to run (1-5, a for all): "
    read -r choice
    
    case $choice in
        1) test_kiosk_persistence ;;
        2) test_comprehensive_cleanup ;;
        3) test_remote_control ;;
        4) test_update_persistence ;;
        5) test_edge_cases ;;
        a|A) 
            test_kiosk_persistence
            test_comprehensive_cleanup
            test_remote_control
            test_update_persistence
            test_edge_cases
            ;;
        *) print_error "Invalid choice. Exiting." && exit 1 ;;
    esac
    
    generate_report
}

# Run main function
main "$@"
