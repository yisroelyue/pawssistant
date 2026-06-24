#include "include/pawssistant_plugin_image_processer/pawssistant_plugin_image_processer_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "pawssistant_plugin_image_processer_plugin.h"

void PawssistantPluginImageProcesserPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  pawssistant_plugin_image_processer::PawssistantPluginImageProcesserPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
