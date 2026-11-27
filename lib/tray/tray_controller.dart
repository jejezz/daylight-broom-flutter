import 'dart:io';
import 'dart:ui';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_localizations.dart';
import '../app_identity.dart';
import '../settings/app_settings.dart';
import '../system/login_item.dart';

/// 상주 동작을 맡는다. 설정의 "시스템 상주"(= 로그인 시 자동 실행)를 따른다:
/// - 켜짐: 트레이/메뉴바 아이콘과 메뉴를 두고, 창을 닫으면 숨기기만 한다 (끝내는 길은 트레이의 "종료").
/// - 꺼짐: 아이콘을 두지 않고, 창을 닫으면 앱을 끝낸다.
class TrayController with TrayListener, WindowListener {
  TrayController({
    required this.settings,
    required this.loginItem,
    required this.onAbout,
    required this.onTidyNow,
    this.onBeforeExit,
    void Function(int code)? exitProcess,
  }) : _exit = exitProcess ?? exit;

  final AppSettings settings;
  final LoginItemController loginItem;

  /// 끝내기 직전에 정리할 것 (자동 정리 감시 멈추기 등).
  final Future<void> Function()? onBeforeExit;
  final void Function(int code) _exit;

  /// 정보 창 열기. 창을 먼저 보여준 뒤 부른다 (about-dialog.md §1: 앱 메뉴가
  /// 없는 상주 앱은 트레이 메뉴가 그 자리를 대신한다).
  final Future<void> Function() onAbout;

  /// "지금 정리": 창을 보여준 뒤 미리보기를 연다.
  final Future<void> Function() onTidyNow;

  static const _keyOpen = 'open';
  static const _keyTidyNow = 'tidy_now';
  static const _keyAbout = 'about';
  static const _keyLogin = 'login_item';
  static const _keyQuit = 'quit';

  bool _iconShown = false;

  /// 상주할지. 로그인 항목을 지원하지 않는 OS 는 예전처럼 늘 상주한다.
  bool get resident => !loginItem.supported || loginItem.enabled;

  Future<void> init() async {
    trayManager.addListener(this);
    windowManager.addListener(this);
    // 닫기는 늘 직접 받는다: 상주면 숨기고, 아니면 끝낸다 (onWindowClose).
    await windowManager.setPreventClose(true);
    settings.addListener(_rebuildMenu);
    loginItem.addListener(_sync);
    // 처음에는 창을 건드리지 않는다: 보일지와 언제 보일지는 main 이 정한다 (깜박임 방지).
    await _sync(initial: true);
  }

  Future<void> dispose() async {
    settings.removeListener(_rebuildMenu);
    loginItem.removeListener(_sync);
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    await _hideIcon();
  }

  /// 상주 설정에 맞춰 아이콘을 두거나 걷는다.
  Future<void> _sync({bool initial = false}) async {
    if (resident) {
      await _showIcon();
      await _rebuildMenu();
      return;
    }
    await _hideIcon();
    // 트레이 메뉴에서 끈 경우 창이 숨어 있으면 앱에 닿을 길이 없다: 창을 다시 보인다.
    if (!initial && !await windowManager.isVisible()) await showWindow();
  }

  Future<void> _showIcon() async {
    if (_iconShown) return;
    // Windows: tray_manager가 setIcon 때 초기화되지 않은 szTip을 복사해 툴팁이
    // 깨진 글자(CJK처럼 보이는 쓰레기 값)로 나온다. 아이콘보다 먼저 툴팁을 지정한다.
    if (Platform.isWindows) {
      await trayManager.setToolTip(AppIdentity.displayName);
    }
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/tray/tray_icon.ico' : 'assets/tray/tray_icon.png',
      isTemplate: true, // macOS: 라이트/다크 메뉴바 색을 OS가 맡는다 (icons.md §4).
    );
    _iconShown = true;
  }

  Future<void> _hideIcon() async {
    if (!_iconShown) return;
    _iconShown = false;
    await trayManager.destroy();
  }

  /// 메뉴는 위젯 트리 밖이라 로케일을 직접 구한다.
  AppLocalizations get _l10n {
    final locale = settings.locale ??
        AppSettings.resolveLocale(PlatformDispatcher.instance.locale, AppLocalizations.supportedLocales);
    return lookupAppLocalizations(locale);
  }

  Future<void> _rebuildMenu() async {
    if (!_iconShown) return;
    final l10n = _l10n;
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: _keyOpen, label: l10n.trayOpen),
      MenuItem(key: _keyTidyNow, label: l10n.trayTidyNow),
      MenuItem.separator(),
      if (loginItem.supported)
        MenuItem.checkbox(key: _keyLogin, label: l10n.trayLoginItem, checked: loginItem.enabled),
      MenuItem(key: _keyAbout, label: l10n.aboutMenuItem(AppIdentity.displayName)),
      MenuItem.separator(),
      MenuItem(key: _keyQuit, label: l10n.trayQuit),
    ]));
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  // macOS는 아이콘을 누르면 메뉴, Windows는 왼쪽 클릭이 창 열기, 오른쪽 클릭이 메뉴.
  @override
  void onTrayIconMouseDown() {
    if (Platform.isWindows) {
      showWindow();
    } else {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case _keyOpen:
        showWindow();
      case _keyTidyNow:
        showWindow().then((_) => onTidyNow());
      case _keyLogin:
        loginItem.setEnabled(!loginItem.enabled);
      case _keyAbout:
        showWindow().then((_) => onAbout());
      case _keyQuit:
        quit();
    }
  }

  /// 창의 닫기 버튼: 상주 중이면 숨기기만 하고, 아니면 앱을 끝낸다.
  @override
  void onWindowClose() {
    if (resident) {
      windowManager.hide();
    } else {
      quit();
    }
  }

  bool _quitting = false;

  /// 앱을 끝낸다. windowManager.destroy() 로 엔진이 스스로 내려가게 두면 Windows 에서는 창이 멈춘 채
  /// 9–13초 남아 있었다 (측정, Dart 쪽 정리는 80ms 안에 끝난다). 트레이 아이콘을 걷고 감시를 멈춘 뒤
  /// 프로세스를 바로 끝낸다 (약 70ms). 아이콘을 먼저 걷어야 끝난 뒤 트레이에 유령 아이콘이 남지 않는다.
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    try {
      await dispose();
      await onBeforeExit?.call();
    } finally {
      _exit(0);
    }
  }
}
