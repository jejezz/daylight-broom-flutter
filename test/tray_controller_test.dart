import 'package:daylight_broom/settings/app_settings.dart';
import 'package:daylight_broom/system/login_item.dart';
import 'package:daylight_broom/tray/tray_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart' show MenuItem;

class _Backend implements LoginItemBackend {
  _Backend(this.on);

  bool on;

  @override
  Future<bool> isEnabled() async => on;

  @override
  Future<void> setEnabled(bool enabled) async => on = enabled;

  @override
  Future<void> refresh() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> tray;
  late List<String> window;
  var visible = true;

  setUp(() {
    tray = [];
    window = [];
    visible = true;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('tray_manager'), (call) async {
      tray.add(call.method);
      return null;
    });
    messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (call) async {
      window.add(call.method);
      if (call.method == 'isVisible') return visible;
      if (call.method == 'hide') visible = false;
      if (call.method == 'show') visible = true;
      if (call.method.startsWith('is')) return false; // isMinimized 등
      return null;
    });
  });

  late List<String> events;

  Future<(TrayController, LoginItemController)> make(bool on) async {
    SharedPreferences.setMockInitialValues({});
    events = [];
    final login = LoginItemController(_Backend(on));
    await login.init();
    final c = TrayController(
      settings: await AppSettings.load(),
      loginItem: login,
      onAbout: () async {},
      onTidyNow: () async {},
      onBeforeExit: () async => events.add('beforeExit'),
      exitProcess: (code) => events.add('exit $code'), // 테스트 프로세스를 끝내지 않게
    );
    await c.init();
    return (c, login);
  }

  test('상주가 꺼져 있으면 트레이 아이콘을 두지 않고, 창을 닫으면 앱을 끝낸다', () async {
    final (c, _) = await make(false);
    expect(c.resident, isFalse);
    expect(tray, isNot(contains('setIcon')));
    expect(window, isNot(contains('show'))); // 처음에는 창을 건드리지 않는다 (main 이 띄운다)

    c.onWindowClose();
    await pumpEventQueue();
    expect(events, ['beforeExit', 'exit 0']); // 정리한 뒤 바로 끝낸다 (엔진이 내려가길 기다리지 않는다)
    expect(window, isNot(contains('hide')));
  });

  test('끝내기는 트레이 아이콘을 먼저 걷고, 두 번 불러도 한 번만 끝낸다', () async {
    final (c, _) = await make(true);
    tray.clear();
    c.onTrayMenuItemClick(MenuItem(key: 'quit', label: 'quit'));
    await c.quit();
    await pumpEventQueue();
    expect(tray, contains('destroy'));
    expect(events, ['beforeExit', 'exit 0']);
  });

  test('상주가 켜져 있으면 아이콘을 두고, 창을 닫으면 숨기기만 한다', () async {
    final (c, _) = await make(true);
    expect(tray, containsAll(['setIcon', 'setContextMenu']));
    c.onWindowClose();
    await pumpEventQueue();
    expect(window, contains('hide'));
    expect(window, isNot(contains('destroy')));
  });

  test('켜고 끄면 아이콘이 생기고 사라지며, 창이 숨은 채 끄면 창을 다시 보인다', () async {
    final (_, login) = await make(true);
    visible = false; // 트레이에서만 실행 중
    tray.clear();
    await login.setEnabled(false);
    await pumpEventQueue();
    expect(tray, contains('destroy'));
    expect(window, contains('show'));

    tray.clear();
    await login.setEnabled(true);
    await pumpEventQueue();
    expect(tray, contains('setIcon'));
  });

  test('로그인 항목을 지원하지 않는 OS 는 예전처럼 늘 상주한다', () async {
    SharedPreferences.setMockInitialValues({});
    final c = TrayController(
      settings: await AppSettings.load(),
      loginItem: LoginItemController(null),
      onAbout: () async {},
      onTidyNow: () async {},
    );
    expect(c.resident, isTrue);
  });
}
