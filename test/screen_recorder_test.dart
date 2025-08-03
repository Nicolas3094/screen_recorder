import 'package:flutter_test/flutter_test.dart';
import 'package:screen_recorder/screen_recorder.dart';
import 'package:screen_recorder/screen_recorder_platform_interface.dart';
import 'package:screen_recorder/screen_recorder_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockScreenRecorderPlatform
    with MockPlatformInterfaceMixin
    implements ScreenRecorderPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
  
  @override
  Future<bool> startRecordScreen(String name) {
    // TODO: implement startRecordScreen
    throw UnimplementedError();
  }
  
  @override
  Future<String> stopRecordScreen() {
    // TODO: implement stopRecordScreen
    throw UnimplementedError();
  }
}

void main() {
  final ScreenRecorderPlatform initialPlatform = ScreenRecorderPlatform.instance;

  test('$MethodChannelScreenRecorder is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelScreenRecorder>());
  });

  test('getPlatformVersion', () async {
    ScreenRecorder screenRecorderPlugin = ScreenRecorder();
    MockScreenRecorderPlatform fakePlatform = MockScreenRecorderPlatform();
    ScreenRecorderPlatform.instance = fakePlatform;

    expect(await screenRecorderPlugin.getPlatformVersion(), '42');
  });
}
