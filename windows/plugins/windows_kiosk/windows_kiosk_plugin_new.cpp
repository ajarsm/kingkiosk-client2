#include "windows_kiosk_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <sstream>
#include <windows.h>
#include <winuser.h>
#include <shellapi.h>
#include <shlobj.h>
#include <thread>
#include <chrono>

namespace windows_kiosk {

// Static variables for global state
static HWND g_taskbar_hwnd = nullptr;
static bool g_taskbar_hidden = false;
static bool g_kiosk_mode_active = false;
static HHOOK g_keyboard_hook = nullptr;
static std::thread g_monitor_thread;
static bool g_monitoring_active = false;

// Low-level keyboard hook procedure
LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0 && g_kiosk_mode_active) {
        KBDLLHOOKSTRUCT* kbStruct = (KBDLLHOOKSTRUCT*)lParam;
        
        // Block common escape keys
        if (kbStruct->vkCode == VK_LWIN || kbStruct->vkCode == VK_RWIN ||
            kbStruct->vkCode == VK_TAB || kbStruct->vkCode == VK_ESCAPE) {
            return 1; // Block the key
        }
        
        // Block Ctrl+Alt+Del combination
        if ((kbStruct->vkCode == VK_DELETE) && 
            (GetAsyncKeyState(VK_CONTROL) & 0x8000) && 
            (GetAsyncKeyState(VK_MENU) & 0x8000)) {
            return 1;
        }
    }
    
    return CallNextHookEx(g_keyboard_hook, nCode, wParam, lParam);
}

// Process monitoring thread
void ProcessMonitorThread() {
    while (g_monitoring_active) {
        // Simple process monitoring - could be expanded
        std::this_thread::sleep_for(std::chrono::seconds(1));
        
        // Find and kill Task Manager if it appears
        HWND hwndTaskMgr = FindWindow(L"TaskManagerWindow", nullptr);
        if (hwndTaskMgr) {
            PostMessage(hwndTaskMgr, WM_CLOSE, 0, 0);
        }
    }
}

// Registry helper functions
bool SetRegistryValue(HKEY hKey, const std::wstring& subKey, const std::wstring& valueName, DWORD value) {
    HKEY hSubKey;
    LONG result = RegCreateKeyEx(hKey, subKey.c_str(), 0, nullptr, REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &hSubKey, nullptr);
    if (result == ERROR_SUCCESS) {
        result = RegSetValueEx(hSubKey, valueName.c_str(), 0, REG_DWORD, (const BYTE*)&value, sizeof(value));
        RegCloseKey(hSubKey);
        return result == ERROR_SUCCESS;
    }
    return false;
}

bool DeleteRegistryValue(HKEY hKey, const std::wstring& subKey, const std::wstring& valueName) {
    HKEY hSubKey;
    LONG result = RegOpenKeyEx(hKey, subKey.c_str(), 0, KEY_SET_VALUE, &hSubKey);
    if (result == ERROR_SUCCESS) {
        result = RegDeleteValue(hSubKey, valueName.c_str());
        RegCloseKey(hSubKey);
        return result == ERROR_SUCCESS;
    }
    return false;
}

// WindowsKioskPlugin implementation
WindowsKioskPlugin::WindowsKioskPlugin() {
    // Initialize plugin
}

WindowsKioskPlugin::~WindowsKioskPlugin() {
    // Cleanup on destruction
    if (g_kiosk_mode_active) {
        // Emergency cleanup
        if (g_keyboard_hook) {
            UnhookWindowsHookEx(g_keyboard_hook);
            g_keyboard_hook = nullptr;
        }
        
        if (g_monitoring_active) {
            g_monitoring_active = false;
            if (g_monitor_thread.joinable()) {
                g_monitor_thread.join();
            }
        }
        
        // Show taskbar if hidden
        if (g_taskbar_hidden && g_taskbar_hwnd) {
            ShowWindow(g_taskbar_hwnd, SW_SHOW);
        }
    }
}

void WindowsKioskPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "windows_kiosk",
        &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<WindowsKioskPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
}

void WindowsKioskPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    const auto& method = method_call.method_name();
    
    if (method == "enableKioskMode") {
        bool success = EnableKioskMode();
        result->Success(flutter::EncodableValue(success));
    }
    else if (method == "disableKioskMode") {
        bool success = DisableKioskMode();
        result->Success(flutter::EncodableValue(success));
    }
    else if (method == "isKioskModeActive") {
        result->Success(flutter::EncodableValue(g_kiosk_mode_active));
    }
    else if (method == "hideTaskbar") {
        bool success = HideTaskbar();
        result->Success(flutter::EncodableValue(success));
    }
    else if (method == "showTaskbar") {
        bool success = ShowTaskbar();
        result->Success(flutter::EncodableValue(success));
    }
    else if (method == "blockKeyboardShortcuts") {
        bool success = BlockKeyboardShortcuts();
        result->Success(flutter::EncodableValue(success));
    }
    else if (method == "unblockKeyboardShortcuts") {
        bool success = UnblockKeyboardShortcuts();
        result->Success(flutter::EncodableValue(success));
    }
    else if (method == "disableTaskManager") {
        bool success = DisableTaskManager();
        result->Success(flutter::EncodableValue(success));
    }
    else if (method == "enableTaskManager") {
        bool success = EnableTaskManager();
        result->Success(flutter::EncodableValue(success));
    }
    else if (method == "hasAdminPrivileges") {
        bool hasAdmin = HasAdminPrivileges();
        result->Success(flutter::EncodableValue(hasAdmin));
    }
    else if (method == "forceDisableAllKioskFeatures") {
        bool success = ForceDisableAllKioskFeatures();
        result->Success(flutter::EncodableValue(success));
    }
    else {
        result->NotImplemented();
    }
}

bool WindowsKioskPlugin::EnableKioskMode() {
    g_kiosk_mode_active = true;
    
    bool success = true;
    success &= HideTaskbar();
    success &= BlockKeyboardShortcuts();
    success &= DisableTaskManager();
    success &= EnableProcessMonitoring();
    
    return success;
}

bool WindowsKioskPlugin::DisableKioskMode() {
    g_kiosk_mode_active = false;
    
    bool success = true;
    success &= ShowTaskbar();
    success &= UnblockKeyboardShortcuts();
    success &= EnableTaskManager();
    success &= DisableProcessMonitoring();
    
    return success;
}

bool WindowsKioskPlugin::HideTaskbar() {
    g_taskbar_hwnd = FindWindow(L"Shell_TrayWnd", nullptr);
    if (g_taskbar_hwnd) {
        ShowWindow(g_taskbar_hwnd, SW_HIDE);
        g_taskbar_hidden = true;
        return true;
    }
    return false;
}

bool WindowsKioskPlugin::ShowTaskbar() {
    if (g_taskbar_hwnd) {
        ShowWindow(g_taskbar_hwnd, SW_SHOW);
        g_taskbar_hidden = false;
        return true;
    }
    return false;
}

bool WindowsKioskPlugin::BlockKeyboardShortcuts() {
    if (!g_keyboard_hook) {
        g_keyboard_hook = SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, GetModuleHandle(nullptr), 0);
        return g_keyboard_hook != nullptr;
    }
    return true;
}

bool WindowsKioskPlugin::UnblockKeyboardShortcuts() {
    if (g_keyboard_hook) {
        bool success = UnhookWindowsHookEx(g_keyboard_hook);
        g_keyboard_hook = nullptr;
        return success;
    }
    return true;
}

bool WindowsKioskPlugin::DisableTaskManager() {
    return SetRegistryValue(HKEY_CURRENT_USER, 
        L"Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System", 
        L"DisableTaskMgr", 1);
}

bool WindowsKioskPlugin::EnableTaskManager() {
    return DeleteRegistryValue(HKEY_CURRENT_USER, 
        L"Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System", 
        L"DisableTaskMgr");
}

bool WindowsKioskPlugin::EnableProcessMonitoring() {
    if (!g_monitoring_active) {
        g_monitoring_active = true;
        g_monitor_thread = std::thread(ProcessMonitorThread);
        return true;
    }
    return true;
}

bool WindowsKioskPlugin::DisableProcessMonitoring() {
    if (g_monitoring_active) {
        g_monitoring_active = false;
        if (g_monitor_thread.joinable()) {
            g_monitor_thread.join();
        }
        return true;
    }
    return true;
}

bool WindowsKioskPlugin::HasAdminPrivileges() {
    BOOL isAdmin = FALSE;
    PSID adminGroup = nullptr;
    
    SID_IDENTIFIER_AUTHORITY ntAuthority = SECURITY_NT_AUTHORITY;
    if (AllocateAndInitializeSid(&ntAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID,
                                DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, &adminGroup)) {
        CheckTokenMembership(nullptr, adminGroup, &isAdmin);
        FreeSid(adminGroup);
    }
    
    return isAdmin == TRUE;
}

bool WindowsKioskPlugin::ForceDisableAllKioskFeatures() {
    // Emergency method to disable all kiosk features
    g_kiosk_mode_active = false;
    
    bool success = true;
    
    // Unhook keyboard
    if (g_keyboard_hook) {
        UnhookWindowsHookEx(g_keyboard_hook);
        g_keyboard_hook = nullptr;
    }
    
    // Stop monitoring
    if (g_monitoring_active) {
        g_monitoring_active = false;
        if (g_monitor_thread.joinable()) {
            g_monitor_thread.join();
        }
    }
    
    // Show taskbar
    if (g_taskbar_hwnd) {
        ShowWindow(g_taskbar_hwnd, SW_SHOW);
        g_taskbar_hidden = false;
    }
    
    // Enable Task Manager
    DeleteRegistryValue(HKEY_CURRENT_USER, 
        L"Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System", 
        L"DisableTaskMgr");
    
    return success;
}

}  // namespace windows_kiosk
