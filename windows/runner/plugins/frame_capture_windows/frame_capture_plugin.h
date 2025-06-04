#ifndef FLUTTER_PLUGIN_FRAME_CAPTURE_PLUGIN_H_
#define FLUTTER_PLUGIN_FRAME_CAPTURE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <memory>

namespace frame_capture_windows {

class FrameCapturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  FrameCapturePlugin();

  virtual ~FrameCapturePlugin();

  // Disallow copy and assign.
  FrameCapturePlugin(const FrameCapturePlugin&) = delete;
  FrameCapturePlugin& operator=(const FrameCapturePlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
      
  // Helper methods for frame capture
  std::vector<uint8_t> CaptureFrameFromTexture(int texture_id, int width, int height);
  int GetRendererTextureId(const flutter::EncodableValue& renderer);
  bool IsFrameCaptureSupported();
};

}  // namespace frame_capture_windows

#endif  // FLUTTER_PLUGIN_FRAME_CAPTURE_PLUGIN_H_
