import 'dart:io';

/// 삭제 위험도. 기본 선택 여부와 화면 색을 정한다.
enum Safety {
  /// 앱이 알아서 다시 만든다. 지워도 다음 실행이 조금 느릴 뿐이다.
  safe,

  /// 안전하지만 다음 빌드·설치 때 다시 내려받는다 (개발 캐시).
  rebuild,

  /// 지우기 전에 확인이 필요하다 (원하는 데이터가 있을 수 있다).
  review,
}

enum TargetGroup { system, developer, browser }

enum CleanerPlatform {
  macos,
  windows;

  /// 정크 정리를 지원하지 않는 OS(Linux 등)는 null.
  static CleanerPlatform? get current {
    if (Platform.isMacOS) return CleanerPlatform.macos;
    if (Platform.isWindows) return CleanerPlatform.windows;
    return null;
  }
}

/// 정크로 알려진 폴더. 이 목록이 곧 제품이다: 항목을 더하면 화면에 나타나고, 스캔되고,
/// 정리된다. 제목·설명은 l10n(`target_labels.dart`)에서 id 로 찾는다.
///
/// [paths]에 키가 없는 OS에서는 항목이 나타나지 않는다. 경로는 `~`(홈)와 `%VAR%`(환경 변수)를 쓸 수 있다.
class ScanTarget {
  const ScanTarget({
    required this.id,
    required this.group,
    required this.safety,
    required this.paths,
    this.listChildren = true,
  });

  final String id;
  final TargetGroup group;
  final Safety safety;
  final Map<CleanerPlatform, List<String>> paths;

  /// true 이면 폴더의 자식 하나하나가 선택 가능한 행이 된다 (`~/Library/Caches/Google` 등).
  /// false 이면 폴더 전체가 한 행이다.
  final bool listChildren;

  bool supports(CleanerPlatform platform) => paths.containsKey(platform);

  List<String> resolvedPaths(CleanerPlatform platform, Map<String, String> env) =>
      [for (final p in paths[platform] ?? const <String>[]) expandTargetPath(p, env, platform)];
}

/// `~`와 `%VAR%`를 푼다. 풀 수 없는 변수가 있으면 빈 문자열을 돌려줘 그 경로를 건너뛰게 한다.
String expandTargetPath(String path, Map<String, String> env, CleanerPlatform platform) {
  final home = env['HOME'] ?? env['USERPROFILE'] ?? '';
  var p = path;
  if (p == '~' || p.startsWith('~/') || p.startsWith('~\\')) {
    if (home.isEmpty) return '';
    p = '$home${p.substring(1)}';
  }
  var missing = false;
  p = p.replaceAllMapped(RegExp(r'%([^%]+)%'), (m) {
    final value = env[m.group(1)!] ?? env[m.group(1)!.toUpperCase()];
    if (value == null || value.isEmpty) missing = true;
    return value ?? '';
  });
  if (missing) return '';
  // 같은 OS의 구분자로 맞춘다 (목록에는 `~/…`와 `\`가 섞여 있다).
  return platform == CleanerPlatform.windows ? p.replaceAll('/', '\\') : p.replaceAll('\\', '/');
}

const _mac = CleanerPlatform.macos;
const _win = CleanerPlatform.windows;

const scanTargets = <ScanTarget>[
  // ── 시스템 · 사용자 ──────────────────────────────────────────────────────
  ScanTarget(
    id: 'user_caches',
    group: TargetGroup.system,
    safety: Safety.safe,
    paths: {_mac: ['~/Library/Caches']},
  ),
  ScanTarget(
    id: 'user_logs',
    group: TargetGroup.system,
    safety: Safety.safe,
    paths: {_mac: ['~/Library/Logs']},
  ),
  ScanTarget(
    id: 'trash',
    group: TargetGroup.system,
    safety: Safety.safe,
    // iCloud Drive 는 자기 휴지통을 따로 두고 Finder 가 하나로 합쳐 보여 준다.
    paths: {_mac: ['~/.Trash', '~/Library/Mobile Documents/.Trash']},
    listChildren: false,
  ),
  ScanTarget(
    id: 'saved_state',
    group: TargetGroup.system,
    safety: Safety.safe,
    paths: {_mac: ['~/Library/Saved Application State']},
    listChildren: false,
  ),
  ScanTarget(
    id: 'win_temp',
    group: TargetGroup.system,
    safety: Safety.rebuild,
    // 실행 중인 프로그램이 쓰는 파일은 지워지지 않고 실패로 남는다.
    paths: {_win: ['%TEMP%']},
  ),
  ScanTarget(
    id: 'win_inet_cache',
    group: TargetGroup.system,
    safety: Safety.safe,
    paths: {_win: ['%LOCALAPPDATA%\\Microsoft\\Windows\\INetCache']},
    listChildren: false,
  ),
  ScanTarget(
    id: 'win_crash_dumps',
    group: TargetGroup.system,
    safety: Safety.safe,
    paths: {_win: ['%LOCALAPPDATA%\\CrashDumps']},
    listChildren: false,
  ),
  ScanTarget(
    id: 'win_wer',
    group: TargetGroup.system,
    safety: Safety.safe,
    paths: {_win: ['%LOCALAPPDATA%\\Microsoft\\Windows\\WER']},
    listChildren: false,
  ),

  // ── 브라우저 ─────────────────────────────────────────────────────────────
  // 프로필 폴더 전체가 아니라 캐시 폴더만 지정한다 (프로필에는 북마크·로그인이 있다).
  ScanTarget(
    id: 'browser_chrome',
    group: TargetGroup.browser,
    safety: Safety.rebuild,
    paths: {
      _win: [
        '%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Default\\Cache',
        '%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Default\\Code Cache',
        '%LOCALAPPDATA%\\Google\\Chrome\\User Data\\Default\\GPUCache',
      ],
    },
    listChildren: false,
  ),
  ScanTarget(
    id: 'browser_edge',
    group: TargetGroup.browser,
    safety: Safety.rebuild,
    paths: {
      _win: [
        '%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Default\\Cache',
        '%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Default\\Code Cache',
        '%LOCALAPPDATA%\\Microsoft\\Edge\\User Data\\Default\\GPUCache',
      ],
    },
    listChildren: false,
  ),

  // ── 개발 ─────────────────────────────────────────────────────────────────
  ScanTarget(
    id: 'xcode_derived',
    group: TargetGroup.developer,
    safety: Safety.rebuild,
    paths: {_mac: ['~/Library/Developer/Xcode/DerivedData']},
  ),
  ScanTarget(
    id: 'xcode_archives',
    group: TargetGroup.developer,
    safety: Safety.review,
    paths: {_mac: ['~/Library/Developer/Xcode/Archives']},
  ),
  ScanTarget(
    id: 'ios_device_support',
    group: TargetGroup.developer,
    safety: Safety.rebuild,
    paths: {_mac: ['~/Library/Developer/Xcode/iOS DeviceSupport']},
  ),
  ScanTarget(
    id: 'simulators',
    group: TargetGroup.developer,
    safety: Safety.review,
    paths: {_mac: ['~/Library/Developer/CoreSimulator/Devices']},
  ),
  ScanTarget(
    id: 'gradle',
    group: TargetGroup.developer,
    safety: Safety.rebuild,
    paths: {_mac: ['~/.gradle/caches'], _win: ['~/.gradle/caches']},
  ),
  ScanTarget(
    id: 'pub_cache',
    group: TargetGroup.developer,
    safety: Safety.rebuild,
    paths: {_mac: ['~/.pub-cache/hosted'], _win: ['%LOCALAPPDATA%\\Pub\\Cache\\hosted']},
  ),
  ScanTarget(
    id: 'cocoapods',
    group: TargetGroup.developer,
    safety: Safety.rebuild,
    paths: {_mac: ['~/Library/Caches/CocoaPods', '~/.cocoapods/repos']},
    listChildren: false,
  ),
  ScanTarget(
    id: 'npm',
    group: TargetGroup.developer,
    safety: Safety.rebuild,
    paths: {
      _mac: ['~/.npm/_cacache', '~/Library/Caches/Yarn', '~/Library/pnpm/store'],
      _win: ['%LOCALAPPDATA%\\npm-cache\\_cacache', '%LOCALAPPDATA%\\Yarn\\Cache', '%LOCALAPPDATA%\\pnpm\\store'],
    },
    listChildren: false,
  ),
  ScanTarget(
    id: 'homebrew',
    group: TargetGroup.developer,
    safety: Safety.rebuild,
    paths: {_mac: ['~/Library/Caches/Homebrew']},
    listChildren: false,
  ),
  ScanTarget(
    id: 'pip',
    group: TargetGroup.developer,
    safety: Safety.rebuild,
    paths: {_mac: ['~/Library/Caches/pip'], _win: ['%LOCALAPPDATA%\\pip\\Cache']},
    listChildren: false,
  ),
  ScanTarget(
    id: 'nuget',
    group: TargetGroup.developer,
    safety: Safety.rebuild,
    paths: {_win: ['%LOCALAPPDATA%\\NuGet\\v3-cache']},
    listChildren: false,
  ),
];

List<ScanTarget> targetsFor(CleanerPlatform platform) => [for (final t in scanTargets) if (t.supports(platform)) t];
