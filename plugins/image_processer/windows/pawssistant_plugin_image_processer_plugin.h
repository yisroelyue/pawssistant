#ifndef FLUTTER_PLUGIN_PAWSSISTANT_PLUGIN_IMAGE_PROCESSER_PLUGIN_H_
#define FLUTTER_PLUGIN_PAWSSISTANT_PLUGIN_IMAGE_PROCESSER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace pawssistant_plugin_image_processer {

class PawssistantPluginImageProcesserPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  PawssistantPluginImageProcesserPlugin();

  virtual ~PawssistantPluginImageProcesserPlugin();

  // Disallow copy and assign.
  PawssistantPluginImageProcesserPlugin(const PawssistantPluginImageProcesserPlugin&) = delete;
  PawssistantPluginImageProcesserPlugin& operator=(const PawssistantPluginImageProcesserPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace pawssistant_plugin_image_processer

#endif  // FLUTTER_PLUGIN_PAWSSISTANT_PLUGIN_IMAGE_PROCESSER_PLUGIN_H_
