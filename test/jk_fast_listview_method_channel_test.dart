import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:jk_fast_listview/jk_fast_listview_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  //MethodChannelJkFastListview platform = MethodChannelJkFastListview();
  const MethodChannel channel = MethodChannel('jk_fast_listview');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    //expect(await platform.getPlatformVersion(), '42');
  });
}
