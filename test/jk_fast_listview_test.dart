import 'package:flutter_test/flutter_test.dart';
import 'package:jk_fast_listview/jk_fast_listview.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockJkFastListviewPlatform
    with MockPlatformInterfaceMixin
    /*implements JkFastListviewPlatform*/ {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  /*
  final JkFastListviewPlatform initialPlatform = JkFastListviewPlatform.instance;

  test('$MethodChannelJkFastListview is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelJkFastListview>());
  });

  test('getPlatformVersion', () async {
    JkFastListview jkFastListviewPlugin = JkFastListview();
    MockJkFastListviewPlatform fakePlatform = MockJkFastListviewPlatform();
    JkFastListviewPlatform.instance = fakePlatform;

    expect(await jkFastListviewPlugin.getPlatformVersion(), '42');
  });
  */
}
