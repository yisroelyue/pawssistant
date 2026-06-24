import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pawssistant_plugin_screen_record_platform_interface.dart';

/// An implementation of [PawssistantPluginScreenRecordPlatform] that uses
/// method channels and event channels.
class MethodChannelPawssistantPluginScreenRecord
    extends PawssistantPluginScreenRecordPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('pawssistant_plugin_screen_record');

  /// Event channel for recording state changes.
  @visibleForTesting
  final stateEventChannel =
      const EventChannel('pawssistant_plugin_screen_record/state');

  /// Event channel for recording progress updates.
  @visibleForTesting
  final progressEventChannel =
      const EventChannel('pawssistant_plugin_screen_record/progress');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> isSupported() async {
    final result = await methodChannel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  @override
  Future<Map<String, dynamic>?> startRecording(
      Map<String, dynamic> config) async {
    final result =
        await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'startRecording',
      config,
    );
    return result?.cast<String, dynamic>();
  }

  @override
  Future<void> pauseRecording() async {
    await methodChannel.invokeMethod('pauseRecording');
  }

  @override
  Future<void> resumeRecording() async {
    await methodChannel.invokeMethod('resumeRecording');
  }

  @override
  Future<Map<String, dynamic>?> stopRecording() async {
    final result =
        await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'stopRecording',
    );
    return result?.cast<String, dynamic>();
  }

  @override
  @override
  Future<Map<String, dynamic>?> getRecordingProgress() async {
    final result =
        await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getRecordingProgress',
    );
    return result?.cast<String, dynamic>();
  }

  @override
  Stream<String> get onRecordingStateChanged {
    return stateEventChannel
        .receiveBroadcastStream()
        .map((event) => event.toString());
  }

  @override
  Stream<Map<String, dynamic>> get onRecordingProgress {
    return progressEventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
  }
}
