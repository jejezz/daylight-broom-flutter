import '../l10n/app_localizations.dart';

/// 대상 id 로 현지화된 제목·설명을 찾는다. id 를 더하면 여기도 한 줄씩 더한다.
class TargetLabels {
  const TargetLabels(this.title, this.description);

  final String title;
  final String description;
}

TargetLabels targetLabels(AppLocalizations l, String id) => switch (id) {
      'user_caches' => TargetLabels(l.targetUserCachesTitle, l.targetUserCachesDesc),
      'user_logs' => TargetLabels(l.targetUserLogsTitle, l.targetUserLogsDesc),
      'trash' => TargetLabels(l.targetTrashTitle, l.targetTrashDesc),
      'saved_state' => TargetLabels(l.targetSavedStateTitle, l.targetSavedStateDesc),
      'win_temp' => TargetLabels(l.targetWinTempTitle, l.targetWinTempDesc),
      'win_inet_cache' => TargetLabels(l.targetWinInetCacheTitle, l.targetWinInetCacheDesc),
      'win_crash_dumps' => TargetLabels(l.targetWinCrashDumpsTitle, l.targetWinCrashDumpsDesc),
      'win_wer' => TargetLabels(l.targetWinWerTitle, l.targetWinWerDesc),
      'browser_chrome' => TargetLabels(l.targetBrowserChromeTitle, l.targetBrowserChromeDesc),
      'browser_edge' => TargetLabels(l.targetBrowserEdgeTitle, l.targetBrowserEdgeDesc),
      'xcode_derived' => TargetLabels(l.targetXcodeDerivedTitle, l.targetXcodeDerivedDesc),
      'xcode_archives' => TargetLabels(l.targetXcodeArchivesTitle, l.targetXcodeArchivesDesc),
      'ios_device_support' => TargetLabels(l.targetIosDeviceSupportTitle, l.targetIosDeviceSupportDesc),
      'simulators' => TargetLabels(l.targetSimulatorsTitle, l.targetSimulatorsDesc),
      'gradle' => TargetLabels(l.targetGradleTitle, l.targetGradleDesc),
      'pub_cache' => TargetLabels(l.targetPubCacheTitle, l.targetPubCacheDesc),
      'cocoapods' => TargetLabels(l.targetCocoapodsTitle, l.targetCocoapodsDesc),
      'npm' => TargetLabels(l.targetNpmTitle, l.targetNpmDesc),
      'homebrew' => TargetLabels(l.targetHomebrewTitle, l.targetHomebrewDesc),
      'pip' => TargetLabels(l.targetPipTitle, l.targetPipDesc),
      'nuget' => TargetLabels(l.targetNugetTitle, l.targetNugetDesc),
      _ => TargetLabels(id, ''),
    };
