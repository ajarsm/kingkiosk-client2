#ifndef PLUGINS_WINDOWS_KIOSK_WINDOWS_KIOSK_PLUGIN_H_
#define PLUGINS_WINDOWS_KIOSK_WINDOWS_KIOSK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace windows_kiosk {

class WindowsKioskPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  WindowsKioskPlugin();

  virtual ~WindowsKioskPlugin();

  // Disallow copy and assign.
  WindowsKioskPlugin(const WindowsKioskPlugin&) = delete;
  WindowsKioskPlugin& operator=(const WindowsKioskPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Kiosk mode control methods
  bool EnableKioskMode();
  bool DisableKioskMode();
  bool HideTaskbar();
  bool ShowTaskbar();
  bool BlockKeyboardShortcuts();
  bool UnblockKeyboardShortcuts();
  bool DisableTaskManager();
  bool EnableTaskManager();
  bool EnableProcessMonitoring();
  bool DisableProcessMonitoring();
  bool HasAdminPrivileges();
  bool ForceDisableAllKioskFeatures();
};

}  // namespace windows_kiosk

#endif  // PLUGINS_WINDOWS_KIOSK_WINDOWS_KIOSK_PLUGIN_H_
