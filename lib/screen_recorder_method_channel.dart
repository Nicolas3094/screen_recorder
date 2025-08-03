import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screen_recorder_platform_interface.dart';

/// An implementation of [ScreenRecorderPlatform] that uses method channels.
class MethodChannelScreenRecorder extends ScreenRecorderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('screen_recorder');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> startRecordScreen({required String name,bool? audio,String? dirPath}) async {
    bool? result = await methodChannel
        .invokeMethod<bool>("startRecording", {"name": name, "audio": audio, "dirPath":dirPath});
    if (result == null || !result) {
      throw Exception("Start recording error");
    } else {
      return result;
    }
  }

  @override
  Future<String> stopRecordScreen() async {
    final String? path =
        await methodChannel.invokeMethod<String>("stopRecording");
    if (path == null) {
      throw Exception("No path found");
    } else {
      return path;
    }
  }
}
