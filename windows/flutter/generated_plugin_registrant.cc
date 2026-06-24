//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_multi_window/desktop_multi_window_plugin.h>
#include <flutter_acrylic/flutter_acrylic_plugin.h>
#include <pawssistant_plugin_image_processer/pawssistant_plugin_image_processer_plugin_c_api.h>
#include <pawssistant_plugin_screen_record/pawssistant_plugin_screen_record_plugin_c_api.h>
#include <screen_retriever_windows/screen_retriever_windows_plugin_c_api.h>
#include <system_tray/system_tray_plugin.h>
#include <window_manager/window_manager_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DesktopMultiWindowPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DesktopMultiWindowPlugin"));
  FlutterAcrylicPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterAcrylicPlugin"));
  PawssistantPluginImageProcesserPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PawssistantPluginImageProcesserPluginCApi"));
  PawssistantPluginScreenRecordPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PawssistantPluginScreenRecordPluginCApi"));
  ScreenRetrieverWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ScreenRetrieverWindowsPluginCApi"));
  SystemTrayPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SystemTrayPlugin"));
  WindowManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowManagerPlugin"));
}
