import 'screen_recorder_platform_interface.dart';

class ScreenRecorder {
  Future<String?> getPlatformVersion() {
    return ScreenRecorderPlatform.instance.getPlatformVersion();
  }

  Future<bool> startRecording(
          {required String name, bool? audio = true, String? dirPath = ""}) =>
      ScreenRecorderPlatform.instance
          .startRecordScreen(name: name, audio: audio, dirPath: dirPath);

  Future<String> stopRecording() =>
      ScreenRecorderPlatform.instance.stopRecordScreen();
}
