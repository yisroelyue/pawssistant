import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pawssistant_plugin_image_processer_platform_interface.dart';

/// An implementation of [PawssistantPluginImageProcesserPlatform] that uses method channels.
class MethodChannelPawssistantPluginImageProcesser extends PawssistantPluginImageProcesserPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pawssistant_plugin_image_processer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
