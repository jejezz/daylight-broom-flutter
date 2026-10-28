import 'dart:io';

import 'package:daylight_broom/cleaner/disk_info.dart';
import 'package:daylight_broom/cleaner/folder_sizer.dart';
import 'package:daylight_broom/cleaner/junk_controller.dart';
import 'package:daylight_broom/cleaner/scan_target.dart';
import 'package:daylight_broom/cleaner/scanner.dart';
import 'package:daylight_broom/engine/history.dart';
import 'package:daylight_broom/engine/tidy_engine.dart';
import 'package:daylight_broom/engine/tidy_service.dart';
import 'package:daylight_broom/l10n/app_localizations.dart';
import 'package:daylight_broom/rules/rule_store.dart';
import 'package:daylight_broom/theme/app_theme.dart';
import 'package:daylight_broom/ui/fda_guide.dart';
import 'package:daylight_broom/ui/overview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _WalkSizer implements FolderSizer {
  @override
  Future<SizeResult> measure(List<String> paths) async {
    final (bytes, restricted) = walkSizes(paths);
    return SizeResult(bytes, restricted);
  }
}

/// 채널 대신 값을 돌려주는 DiskInfo.
class _FakeDisk extends DiskInfo {
  _FakeDisk({this.vol = const [], this.fda, this.onOpen});

  final List<DiskVolume> vol;
  final bool? fda;
  final VoidCallback? onOpen;

  @override
  Future<List<DiskVolume>> volumes() async => vol;

  @override
  Future<bool?> hasFullDiskAccess() async => fda;

  @override
  Future<void> openFullDiskAccessSettings() async => onOpen?.call();
}

void main() {
  group('DiskInfo', () {
    test('PowerShell 출력 "<이름>|<라벨>|<총량>|<여유>"를 읽는다', () {
      final v = DiskInfo.parseDrivesOutput('C:\\|OS|500000000000|125000000000\r\nD:\\||2000|1000\r\n', systemLetter: 'C');
      expect(v.length, 2);
      expect(v[0].name, 'C: OS');
      expect(v[0].isSystem, isTrue);
      expect(v[0].used, 375000000000);
      expect(v[0].usedRatio, closeTo(0.75, 1e-9));
      expect(v[1].name, 'D:');
      expect(v[1].isSystem, isFalse);
    });

    test('이상한 줄은 건너뛴다', () {
      expect(DiskInfo.parseDrivesOutput(''), isEmpty);
      expect(DiskInfo.parseDrivesOutput('abc def'), isEmpty);
      expect(DiskInfo.parseDrivesOutput('C:\\||0|0'), isEmpty);
      expect(DiskInfo.parseDrivesOutput('C:\\||x|y'), isEmpty);
    });

    test('Windows 는 PowerShell 로 고정 디스크만 읽고 시스템 디스크를 앞에 둔다', () async {
      List<String>? args;
      final info = DiskInfo(
        isMac: false,
        isWindows: true,
        env: {'SystemDrive': 'D:'},
        run: (exe, a) async {
          args = a;
          return ProcessResult(0, 0, 'C:\\||1000|500\r\nD:\\|Sys|2000|400\r\n', '');
        },
      );
      final v = await info.volumes();
      expect(v.map((e) => e.path), [r'D:\', r'C:\']);
      expect(v.first.free, 400);
      expect(args!.last, contains("'Fixed'")); // 이동식·네트워크는 제외
      expect(await info.hasFullDiskAccess(), isNull); // macOS 에서만 의미가 있다
    });

    test('macOS 는 채널 값을 쓰고, 채널이 없으면 빈 목록', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('art.zoomon.daylightbroom/system');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'volumes') {
          return [
            {'name': 'Data', 'path': '/Volumes/Data', 'total': 2000, 'free': 500},
            {'name': 'Macintosh HD', 'path': '/', 'total': 1000, 'free': 250},
          ];
        }
        if (call.method == 'hasFullDiskAccess') return false;
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
      final info = DiskInfo(isMac: true, isWindows: false);
      final v = await info.volumes();
      expect(v.length, 2);
      expect(v.first.isSystem, isTrue);
      expect(v.first.usedRatio, 0.75);
      expect(await info.hasFullDiskAccess(), isFalse);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      expect(await info.volumes(), isEmpty);
    });
  });

  group('개요 화면', () {
    late Directory root;
    late TidyService service;
    late JunkController junk;

    setUp(() async {
      root = Directory.systemTemp.createTempSync('daylight_broom_overview_');
      File('${root.path}/c/cache1/f')
        ..createSync(recursive: true)
        ..writeAsBytesSync(List.filled(2000, 1));
      final support = Directory('${root.path}/DaylightBroom');
      service = TidyService(engine: TidyEngine(), ruleStore: RuleStore(support), historyStore: HistoryStore(support));
      await service.init();
      await service.engine.stop();
      junk = JunkController(
        scanner: JunkScanner(
          platform: CleanerPlatform.macos,
          env: {'HOME': root.path},
          sizer: _WalkSizer(),
          targetsOverride: [
            ScanTarget(id: 'user_caches', group: TargetGroup.system, safety: Safety.safe, paths: {CleanerPlatform.macos: ['~/c']}),
          ],
        ),
      );
    });
    tearDown(() async {
      junk.dispose();
      await service.engine.dispose();
      root.deleteSync(recursive: true);
    });

    Widget host(DiskController disk, {VoidCallback? onGoToJunk}) => MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OverviewPage(disk: disk, junk: junk, service: service, onGoToJunk: onGoToJunk ?? () {}, onGoToTidy: () {}),
          ),
        );

    testWidgets('사용률, 여유, 선택한 정크의 확보 예상 용량을 보여 준다', (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final disk = DiskController(_FakeDisk(vol: const [DiskVolume(name: 'C:', path: r'C:', isSystem: true, total: 1000000, free: 250000)], fda: true));
      await tester.runAsync(disk.refresh);
      await tester.pumpWidget(host(disk));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('250.0 KB'), findsOneWidget);
      expect(find.text('Not scanned yet'), findsOneWidget);
      expect(find.text('Show me how'), findsNothing); // 권한이 있으면 배너 없음

      await tester.runAsync(junk.scan);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Cleaning the current selection frees about 2.0 KB'), findsOneWidget);
    });

    testWidgets('디스크가 둘 이상이면 칩으로 고르고, 정크 정보는 시스템 디스크에서만 보인다', (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final disk = DiskController(_FakeDisk(vol: const [
        DiskVolume(name: 'C:', path: r'C:\', isSystem: true, total: 1000000, free: 250000),
        DiskVolume(name: 'D: Data', path: r'D:\', isSystem: false, total: 2000000, free: 1000000),
      ]));
      await tester.runAsync(disk.refresh);
      await tester.pumpWidget(host(disk));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Junk found'), findsOneWidget);

      await tester.tap(find.textContaining('D: Data'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Junk found'), findsNothing);
    });

    testWidgets('전체 디스크 접근이 꺼져 있으면 배너와 설정 열기가 나온다', (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var opened = 0;
      final disk = DiskController(_FakeDisk(vol: const [DiskVolume(name: 'C:', path: r'C:', isSystem: true, total: 100, free: 50)], fda: false, onOpen: () => opened++));
      await tester.runAsync(disk.refresh);
      await tester.pumpWidget(host(disk));
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('Full Disk Access is off'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      expect(opened, 1);
    });

    testWidgets('용량을 읽지 못하면 안내하고 크래시하지 않는다', (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final disk = DiskController(_FakeDisk());
      await tester.runAsync(disk.refresh);
      await tester.pumpWidget(host(disk));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Could not read the disk capacity.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('정크 카드를 누르면 정크 페이지로 가고 첫 스캔을 시작한다', (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var went = 0;
      final disk = DiskController(_FakeDisk(vol: const [DiskVolume(name: 'C:', path: r'C:', isSystem: true, total: 100, free: 50)]));
      await tester.runAsync(disk.refresh);
      await tester.pumpWidget(host(disk, onGoToJunk: () => went++));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Junk cleanup'));
      expect(went, 1);
      expect(junk.scanning || junk.scanned, isTrue);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    });

    testWidgets('FDA 안내는 단계를 넘기고 권한이 생기면 마지막 단계로 간다', (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var granted = false;
      var cbCalls = 0;
      final info = _GrantingDisk(() => granted);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showFdaGuide(context, info: info, onGranted: () async => cbCalls++),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('1. Open Full Disk Access settings'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('2. Click "+" and unlock'), findsOneWidget);

      granted = true;
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('5. All set'), findsOneWidget);
      expect(find.text('GRANTED'), findsOneWidget);
      expect(cbCalls, 1);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('5. All set'), findsNothing);
    });
  });
}

class _GrantingDisk extends DiskInfo {
  _GrantingDisk(this.granted);

  final bool Function() granted;

  @override
  Future<bool?> hasFullDiskAccess() async => granted();
}
