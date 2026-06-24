import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pawssistant_plugin_image_processer_method_channel.dart';

abstract class PawssistantPluginImageProcesserPlatform extends PlatformInterface {
  /// Constructs a PawssistantPluginImageProcesserPlatform.
  PawssistantPluginImageProcesserPlatform() : super(token: _token);

  static final Object _token = Object();

  static PawssistantPluginImageProcesserPlatform _instance = MethodChannelPawssistantPluginImageProcesser();

  /// The default instance of [PawssistantPluginImageProcesserPlatform] to use.
  ///
  /// Defaults to [MethodChannelPawssistantPluginImageProcesser].
  static PawssistantPluginImageProcesserPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PawssistantPluginImageProcesserPlatform] when
  /// they register themselves.
  static set instance(PawssistantPluginImageProcesserPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
