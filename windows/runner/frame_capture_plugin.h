#ifndef FRAME_CAPTURE_PLUGIN_H_
#define FRAME_CAPTURE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace frame_capture_plugin {

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
      
  // Capture frame from WebRTC video renderer
  void CaptureFrame(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
      
  // Get renderer texture ID
  void GetRendererTextureId(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
      
  // Check if frame capture is supported
  void IsSupported(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace frame_capture_plugin

#endif  // FRAME_CAPTURE_PLUGIN_H_
