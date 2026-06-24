#include "include/pawssistant_plugin_screen_record/pawssistant_plugin_screen_record_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "pawssistant_plugin_screen_record_plugin.h"

void PawssistantPluginScreenRecordPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  pawssistant_plugin_screen_record::PawssistantPluginScreenRecordPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
