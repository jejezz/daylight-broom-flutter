// From jejezz/application-release-templates common/ @ conventions-v1.
// 설정 저장 키·기존 키 이전·언어 해석 (localization.md §3·§5).
// daylight_broom을 앱의 pubspec name으로 바꾼다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daylight_broom/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to system theme and system language', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppSettings.load();
    expect(s.themeMode, ThemeMode.system);
    expect(s.locale, isNull);
    expect(s.removeEmptyFolders, isFalse);
  });

  test('persists removeEmptyFolders', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppSettings.load();
    await s.setRemoveEmptyFolders(true);
    expect((await AppSettings.load()).removeEmptyFolders, isTrue);
  });

  test('text_scale defaults to 100%, persists, and stays within 50–150%', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppSettings.load();
    expect(s.textScale, 1.0);
    await s.setTextScale(1.3000000001);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('text_scale'), 1.3);
    expect((await AppSettings.load()).textScale, 1.3);
    await s.setTextScale(3);
    expect(s.textScale, 1.5);
    await s.setTextScale(0.1);
    expect(s.textScale, 0.5);

    SharedPreferences.setMockInitialValues({'text_scale': 9.0}); // 손으로 고친 값도 범위 안으로
    expect((await AppSettings.load()).textScale, 1.5);
  });

  test('persists collapsed rule folders', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppSettings.load();
    expect(s.collapsedRuleFolders, isEmpty);
    await s.setRuleFolderCollapsed('/a', true);
    await s.setRuleFolderCollapsed('/b', true);
    await s.setRuleFolderCollapsed('/a', false);
    expect((await AppSettings.load()).collapsedRuleFolders, {'/b'});
  });

  test('persists under theme_mode / app_locale', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppSettings.load();
    await s.setThemeMode(ThemeMode.dark);
    await s.setLocale(const Locale('en'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('app_locale'), 'en');
    await s.setLocale(null);
    expect(prefs.containsKey('app_locale'), isFalse);
  });

  test('moves a legacy key once', () async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final s = await AppSettings.load(legacyKeys: {'locale': AppSettings.localeKey});
    final prefs = await SharedPreferences.getInstance();
    expect(s.locale, const Locale('en'));
    expect(prefs.containsKey('locale'), isFalse);
  });

  test('non-Korean system languages resolve to English', () {
    const supported = [Locale('ko'), Locale('en')];
    expect(AppSettings.resolveLocale(const Locale('ko', 'KR'), supported), const Locale('ko'));
    expect(AppSettings.resolveLocale(const Locale('ja'), supported), const Locale('en'));
    expect(AppSettings.resolveLocale(null, supported), const Locale('en'));
  });
}
