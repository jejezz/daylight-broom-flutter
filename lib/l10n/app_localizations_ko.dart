// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get navTidy => '자동 정리';

  @override
  String get aboutTooltip => '정보';

  @override
  String aboutVersion(String version, String build) {
    return '버전 $version (빌드 $build)';
  }

  @override
  String get aboutOpenSourceLicenses => '오픈소스 라이선스';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => '닫기';

  @override
  String aboutMenuItem(String appName) {
    return '$appName 정보';
  }

  @override
  String get themeMenuTooltip => '테마';

  @override
  String get themeSystem => '시스템 설정 따르기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get languageMenuTooltip => '언어';

  @override
  String get languageSystem => '시스템 설정 따르기 / System';

  @override
  String get languageSystemShort => '시스템';

  @override
  String get aboutTagline => '다운로드 폴더를 규칙대로 알아서 정리합니다';

  @override
  String get aboutDescription =>
      'Daylight Broom은 다운로드 폴더 같은 곳에 생긴 파일을 확장자, 이름, 크기, 오래된 정도에 따라 자동으로 분류하고 정리합니다. 상주하며 바로 처리하거나, 원할 때 \"지금 정리\"로 직접 실행할 수 있습니다.';

  @override
  String get homeEmptyTitle => '아직 정리 규칙이 없습니다. 규칙을 추가해 다운로드 폴더 정리를 시작하세요';

  @override
  String get homeEmptyAction => '규칙 추가';

  @override
  String get trayOpen => 'Daylight Broom 열기';

  @override
  String get trayTidyNow => '지금 정리';

  @override
  String get trayQuit => '종료';

  @override
  String get commonCancel => '취소';

  @override
  String get commonCopy => '복사';

  @override
  String get tidyNow => '지금 정리';

  @override
  String homeRulesSummary(int count) {
    return '규칙 $count개 · 감시 중';
  }

  @override
  String get previewTitle => '정리 미리보기';

  @override
  String get previewNoRules => '켜져 있는 규칙이 없습니다. 규칙을 추가하면 여기서 결과를 미리 볼 수 있습니다.';

  @override
  String get previewNothing => '지금 정리할 파일이 없습니다.';

  @override
  String previewWaiting(int count) {
    return '$count개 파일은 받는 중이거나 방금 바뀌어서 이번에는 건너뜁니다.';
  }

  @override
  String previewSummary(int count) {
    return '$count개 파일을 정리합니다';
  }

  @override
  String previewRun(int count) {
    return '정리 실행 ($count)';
  }

  @override
  String previewRunning(int done, int total) {
    return '정리하는 중… ($done/$total)';
  }

  @override
  String actionMoveTo(String folder) {
    return '→ $folder';
  }

  @override
  String get actionTrash => '→ 휴지통';

  @override
  String get historyTitle => '최근 기록';

  @override
  String get historyEmpty => '아직 정리한 파일이 없습니다.';

  @override
  String get historyUndo => '되돌리기';

  @override
  String get historyUndone => '되돌림';

  @override
  String get historyFailed => '실패';

  @override
  String get historyUndoUnavailable =>
      '휴지통 위치를 알 수 없어 되돌릴 수 없습니다. 휴지통에서 직접 복원해 주세요.';

  @override
  String tidyDone(int count) {
    return '$count개 파일을 정리했습니다';
  }

  @override
  String tidyDonePartial(int done, int failed) {
    return '$done개 정리, $failed개 실패';
  }

  @override
  String get undoDone => '원래 위치로 되돌렸습니다';

  @override
  String undoFailed(String error) {
    return '되돌리지 못했습니다: $error';
  }

  @override
  String get watchErrorTitle => '폴더를 읽지 못했습니다';

  @override
  String get watchErrorHint =>
      '폴더가 있는지, 시스템 설정의 개인정보 보호 및 보안에서 Daylight Broom의 파일 및 폴더 접근이 허용돼 있는지 확인하세요.';

  @override
  String get rulesTitle => '규칙';

  @override
  String get rulesAdd => '규칙 추가';

  @override
  String get rulesEmpty => '규칙이 없습니다. 규칙을 추가해 정리를 시작하세요.';

  @override
  String get rulesOrderHint => '위에 있는 규칙이 먼저 적용됩니다.';

  @override
  String rulesGroupCount(int enabled, int total) {
    return '$total개 중 $enabled개 켜짐';
  }

  @override
  String get ruleEdit => '수정';

  @override
  String get ruleDelete => '삭제';

  @override
  String get ruleDeleteTitle => '규칙을 삭제할까요?';

  @override
  String ruleDeleteBody(String name) {
    return '“$name” 규칙이 삭제됩니다. 정리 기록은 남습니다.';
  }

  @override
  String get ruleEditorNewTitle => '새 규칙';

  @override
  String get ruleEditorEditTitle => '규칙 수정';

  @override
  String get ruleFieldName => '규칙 이름';

  @override
  String get ruleFieldFolder => '감시 폴더';

  @override
  String get ruleChooseFolder => '폴더 선택';

  @override
  String get ruleSectionCondition => '조건 (모두 만족해야 합니다)';

  @override
  String get ruleFieldExtensions => '확장자';

  @override
  String get ruleFieldExtensionsHint => 'pdf, docx, zip';

  @override
  String get ruleFieldNameContains => '이름에 포함';

  @override
  String get ruleFieldMinSize => '최소 크기';

  @override
  String get ruleFieldMaxSize => '최대 크기';

  @override
  String get ruleFieldOlderThan => '경과 일수';

  @override
  String get ruleOlderThanSuffix => '일 이상 지난 파일';

  @override
  String get ruleSectionAction => '동작';

  @override
  String get ruleActionMove => '폴더로 이동';

  @override
  String get ruleActionTrash => '휴지통으로';

  @override
  String get ruleFieldDestination => '이동할 폴더';

  @override
  String get ruleTrashNote => '휴지통으로 보냅니다. 영구 삭제하지 않습니다.';

  @override
  String get ruleSave => '저장';

  @override
  String get rulePreview => '미리보기';

  @override
  String get ruleErrName => '규칙 이름을 입력하세요';

  @override
  String get ruleErrFolder => '감시 폴더를 입력하세요';

  @override
  String get ruleErrCondition => '조건을 하나 이상 지정하세요';

  @override
  String get ruleErrDestination => '이동할 폴더를 입력하세요';

  @override
  String get ruleErrSameFolder => '이동할 폴더가 감시 폴더와 같습니다';

  @override
  String get ruleErrNumber => '0 이상의 숫자를 입력하세요';

  @override
  String get ruleErrSizeRange => '최소 크기가 최대 크기보다 큽니다';

  @override
  String get rulePreviewTitle => '이 규칙에 맞는 파일';

  @override
  String rulePreviewCount(int count) {
    return '지금 $count개 파일이 맞습니다';
  }

  @override
  String get rulePreviewNone => '지금 맞는 파일이 없습니다.';

  @override
  String condNameContains(String text) {
    return '이름에 “$text” 포함';
  }

  @override
  String condMinSize(String size) {
    return '$size 이상';
  }

  @override
  String condMaxSize(String size) {
    return '$size 이하';
  }

  @override
  String condOlderThan(int days) {
    return '$days일 이상 지남';
  }

  @override
  String get loginItemLabel => '로그인 시 자동 실행';

  @override
  String loginItemFailed(String error) {
    return '자동 실행 설정을 바꾸지 못했습니다: $error';
  }

  @override
  String get presetsStart => '추천 규칙으로 시작';

  @override
  String get presetsTitle => '추천 규칙';

  @override
  String get presetsIntro =>
      '고른 규칙은 Downloads 폴더에 적용됩니다. 이미 있는 파일도 바로 정리되고, 최근 기록에서 되돌릴 수 있습니다.';

  @override
  String presetsAdd(int count) {
    return '추가 ($count)';
  }

  @override
  String get presetsAlready => '이미 있음';

  @override
  String presetCount(int count) {
    return '지금 $count개';
  }

  @override
  String get presetDocuments => '문서';

  @override
  String get presetImages => '이미지';

  @override
  String get presetVideos => '동영상';

  @override
  String get presetAudio => '음악·오디오';

  @override
  String get presetInstallers => '설치 파일';

  @override
  String get presetArchives => '압축 파일';

  @override
  String get presetOldInstallers => '30일 지난 설치 파일';

  @override
  String get trayLoginItem => '로그인 시 자동 실행';

  @override
  String get ruleIncludeSubfolders => '하위 폴더의 파일도 포함';

  @override
  String get ruleSubfoldersSuffix => ' (하위 폴더 포함)';

  @override
  String get cleanupOptionsTooltip => '정리 옵션';

  @override
  String get optionRemoveEmptyFolders => '파일을 옮긴 뒤 비게 된 폴더 지우기';

  @override
  String get updateCheckMenuItem => '업데이트 확인';

  @override
  String get updateChecking => '업데이트를 확인하는 중…';

  @override
  String get updateAvailableTitle => '새 버전이 있습니다';

  @override
  String updateAvailableBody(String appName, String current, String latest) {
    return '$appName $latest 버전이 나왔습니다. (현재 $current)';
  }

  @override
  String get updateReleaseNotes => '변경 내용';

  @override
  String get updateNow => '지금 업데이트';

  @override
  String get updateLater => '나중에';

  @override
  String get updateSkipVersion => '이 버전 건너뛰기';

  @override
  String get updateDownloading => '내려받는 중…';

  @override
  String get updateVerifying => '파일을 확인하는 중…';

  @override
  String updateDownloadProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String get updateCancel => '취소';

  @override
  String get updateFailedTitle => '업데이트하지 못했습니다';

  @override
  String get updateCheckFailedTitle => '업데이트를 확인하지 못했습니다';

  @override
  String get updateErrorNetwork =>
      '업데이트 서버에 연결하지 못했습니다. 인터넷 연결을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get updateErrorChecksum =>
      '내려받은 파일이 올바르지 않아 설치하지 않았습니다. 잠시 뒤에 다시 시도해 주세요.';

  @override
  String get updateErrorInstall => '설치를 시작하지 못했습니다.';

  @override
  String get updateErrorGeneric =>
      '업데이트 서버에서 예상하지 못한 응답을 받았습니다. 잠시 뒤에 다시 시도해 주세요.';

  @override
  String get updateUpToDateTitle => '최신 버전입니다';

  @override
  String updateUpToDateBody(String version) {
    return '$version 버전을 사용 중입니다.';
  }

  @override
  String get updateUnavailableTitle => '직접 설치해 주세요';

  @override
  String updateUnavailableBody(String latest) {
    return '$latest 버전이 있지만 앱에서 자동으로 설치할 수 없습니다. 릴리스 페이지에서 받아 주세요.';
  }

  @override
  String get updateOpenReleasePage => '릴리스 페이지 열기';

  @override
  String get updateMacosOpenedTitle => '설치 창이 열렸습니다';

  @override
  String updateMacosOpenedBody(String appName) {
    return '열린 창에서 $appName 을(를) Applications 폴더로 끌어다 놓아 주세요. 실행 중이면 종료한 뒤 덮어쓰세요.';
  }

  @override
  String get updateWindowsInstallTitle => '설치 프로그램을 열었습니다';

  @override
  String updateWindowsInstallBody(String appName) {
    return '설치하려면 $appName 을(를) 종료해야 합니다. 설치 프로그램의 안내를 따라 주세요.';
  }

  @override
  String updateQuitApp(String appName) {
    return '$appName 종료';
  }

  @override
  String get updateLinuxInstallTitle => '설치를 준비했습니다';

  @override
  String updateLinuxInstallBody(String appName) {
    return '$appName 을(를) 종료하고 설치합니다. 설치가 끝나면 자동으로 다시 시작됩니다.';
  }

  @override
  String get updateQuitAndInstall => '종료하고 설치';

  @override
  String get targetUserCachesTitle => '사용자 캐시';

  @override
  String get targetUserCachesDesc =>
      '~/Library/Caches의 앱 캐시. 앱이 필요할 때 다시 만듭니다.';

  @override
  String get targetUserLogsTitle => '사용자 로그';

  @override
  String get targetUserLogsDesc => '~/Library/Logs의 진단 로그.';

  @override
  String get targetTrashTitle => '휴지통';

  @override
  String get targetTrashDesc => '휴지통(iCloud Drive 포함)에 있는 항목. 정리하면 휴지통을 비웁니다.';

  @override
  String get targetSavedStateTitle => '저장된 앱 상태';

  @override
  String get targetSavedStateDesc => '다시 열 때 복원하는 창 위치.';

  @override
  String get targetWinTempTitle => '임시 파일';

  @override
  String get targetWinTempDesc => '%TEMP% 폴더의 임시 파일. 사용 중인 파일은 건너뜁니다.';

  @override
  String get targetWinInetCacheTitle => '인터넷 임시 파일';

  @override
  String get targetWinInetCacheDesc => 'Windows 인터넷 캐시(INetCache).';

  @override
  String get targetWinCrashDumpsTitle => '충돌 덤프';

  @override
  String get targetWinCrashDumpsDesc => '프로그램이 비정상 종료될 때 남은 덤프 파일.';

  @override
  String get targetWinWerTitle => '오류 보고 파일';

  @override
  String get targetWinWerDesc => 'Windows 오류 보고(WER)가 쌓은 파일.';

  @override
  String get targetBrowserChromeTitle => 'Chrome 캐시';

  @override
  String get targetBrowserChromeDesc => 'Chrome 기본 프로필의 캐시. 북마크·로그인은 지우지 않습니다.';

  @override
  String get targetBrowserEdgeTitle => 'Edge 캐시';

  @override
  String get targetBrowserEdgeDesc => 'Edge 기본 프로필의 캐시. 북마크·로그인은 지우지 않습니다.';

  @override
  String get targetXcodeDerivedTitle => 'Xcode DerivedData';

  @override
  String get targetXcodeDerivedDesc => '빌드 중간 산출물. 다음 빌드는 처음부터 빌드합니다.';

  @override
  String get targetXcodeArchivesTitle => 'Xcode 아카이브';

  @override
  String get targetXcodeArchivesDesc => 'App Store 업로드에 쓴 보관 빌드(.xcarchive).';

  @override
  String get targetIosDeviceSupportTitle => 'iOS 기기 지원 파일';

  @override
  String get targetIosDeviceSupportDesc => 'iOS 버전별 디버그 심볼. 기기를 연결하면 다시 받습니다.';

  @override
  String get targetSimulatorsTitle => 'iOS 시뮬레이터 기기';

  @override
  String get targetSimulatorsDesc =>
      '시뮬레이터 디스크 이미지. 안 쓰는 것은 \"xcrun simctl delete unavailable\"로 지우세요.';

  @override
  String get targetGradleTitle => 'Gradle 캐시';

  @override
  String get targetGradleDesc => '~/.gradle/caches의 안드로이드 의존성·빌드 캐시.';

  @override
  String get targetPubCacheTitle => 'Dart Pub 캐시';

  @override
  String get targetPubCacheDesc =>
      '내려받은 Dart/Flutter 패키지. \"flutter pub get\"으로 다시 받습니다.';

  @override
  String get targetCocoapodsTitle => 'CocoaPods 캐시';

  @override
  String get targetCocoapodsDesc => '내려받은 pod.';

  @override
  String get targetNpmTitle => 'npm / Yarn / pnpm 캐시';

  @override
  String get targetNpmDesc => '패키지 관리자 다운로드 캐시.';

  @override
  String get targetHomebrewTitle => 'Homebrew 캐시';

  @override
  String get targetHomebrewDesc =>
      '내려받은 병/포뮬러. \"brew cleanup --prune=all\"과 같습니다.';

  @override
  String get targetPipTitle => 'pip 캐시';

  @override
  String get targetPipDesc => 'Python 패키지 다운로드.';

  @override
  String get targetNugetTitle => 'NuGet 캐시';

  @override
  String get targetNugetDesc => 'NuGet v3 다운로드 캐시. 다음 복원 때 다시 받습니다.';

  @override
  String get groupSystem => '시스템';

  @override
  String get groupDeveloper => '개발';

  @override
  String get groupBrowser => '브라우저';

  @override
  String get safetySafe => '안전';

  @override
  String get safetyRebuild => '다시 생성';

  @override
  String get safetyReview => '확인 필요';

  @override
  String get navJunk => '정크 정리';

  @override
  String get junkTitle => '정크 정리';

  @override
  String get junkScan => '스캔';

  @override
  String get junkRescan => '다시 스캔';

  @override
  String get junkScanning => '스캔하는 중…';

  @override
  String get junkIntro =>
      '캐시·임시 파일·개발 도구 찌꺼기를 찾아 용량을 되찾습니다. 지운 항목은 휴지통을 거치지 않고 바로 삭제됩니다.';

  @override
  String get junkEmptyScanned => '정리할 정크가 없습니다.';

  @override
  String junkSelectedSummary(int count, String size) {
    return '$count개 선택 · $size';
  }

  @override
  String junkTotalFound(String size) {
    return '총 $size를 찾았습니다';
  }

  @override
  String get junkClean => '선택 항목 정리';

  @override
  String junkCleaning(int done, int total) {
    return '정리하는 중… $done / $total';
  }

  @override
  String get junkConfirmTitle => '영구 삭제할까요?';

  @override
  String junkConfirmBody(int count, String size) {
    return '선택한 $count개 항목($size)을 휴지통을 거치지 않고 바로 삭제합니다. 되돌릴 수 없습니다.';
  }

  @override
  String junkConfirmReview(String names) {
    return '확인이 필요한 항목이 포함되어 있습니다: $names';
  }

  @override
  String get junkConfirmAction => '영구 삭제';

  @override
  String junkFreed(String size) {
    return '$size를 확보했습니다';
  }

  @override
  String junkFailed(int count, String reason) {
    return '$count개 항목을 지우지 못했습니다: $reason';
  }

  @override
  String junkUnreadable(String paths) {
    return '읽을 수 없는 폴더가 있습니다: $paths';
  }

  @override
  String get junkRestricted =>
      '일부 폴더는 권한 때문에 크기를 다 재지 못했습니다. 시스템 설정의 개인정보 보호 및 보안에서 전체 디스크 접근 권한을 허용하면 더 정확합니다.';

  @override
  String junkScanFailed(String error) {
    return '스캔하지 못했습니다: $error';
  }

  @override
  String get junkUnsupported => '이 운영체제에서는 정크 정리를 지원하지 않습니다.';

  @override
  String get junkSelectGroup => '그룹 전체 선택';
}
