// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navTidy => 'Auto tidy';

  @override
  String get aboutTooltip => 'About';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get aboutOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => 'Close';

  @override
  String aboutMenuItem(String appName) {
    return 'About $appName';
  }

  @override
  String get themeMenuTooltip => 'Theme';

  @override
  String get themeSystem => 'Follow System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageMenuTooltip => 'Language';

  @override
  String get languageSystem => 'System / 시스템 설정 따르기';

  @override
  String get languageSystemShort => 'System';

  @override
  String get aboutTagline => 'Keeps your Downloads folder tidy, by your rules';

  @override
  String get aboutDescription =>
      'Daylight Broom sorts and cleans up files that land in folders like Downloads, by extension, name, size and age. Let it run in the background, or tidy up on demand with \"Tidy now\".';

  @override
  String get homeEmptyTitle =>
      'No rules yet. Add a rule to start tidying your Downloads folder';

  @override
  String get homeEmptyAction => 'Add rule';

  @override
  String get trayOpen => 'Open Daylight Broom';

  @override
  String get trayTidyNow => 'Tidy now';

  @override
  String get trayQuit => 'Quit';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonCopy => 'Copy';

  @override
  String get tidyNow => 'Tidy now';

  @override
  String homeRulesSummary(int count) {
    return '$count rules · watching';
  }

  @override
  String get previewTitle => 'Tidy preview';

  @override
  String get previewNoRules =>
      'No rules are turned on. Add a rule to preview what it would do.';

  @override
  String get previewNothing => 'Nothing to tidy right now.';

  @override
  String previewWaiting(int count) {
    return '$count files are still downloading or just changed, so they are skipped this time.';
  }

  @override
  String previewSummary(int count) {
    return '$count files will be tidied';
  }

  @override
  String previewRun(int count) {
    return 'Tidy ($count)';
  }

  @override
  String previewRunning(int done, int total) {
    return 'Tidying… ($done/$total)';
  }

  @override
  String actionMoveTo(String folder) {
    return '→ $folder';
  }

  @override
  String get actionTrash => '→ Trash';

  @override
  String get historyTitle => 'Recent activity';

  @override
  String get historyEmpty => 'No files tidied yet.';

  @override
  String get historyUndo => 'Undo';

  @override
  String get historyUndone => 'Undone';

  @override
  String get historyFailed => 'Failed';

  @override
  String get historyUndoUnavailable =>
      'Can\'t tell where the file is in the Trash, so it can\'t be undone here. Restore it from the Trash yourself.';

  @override
  String tidyDone(int count) {
    return 'Tidied $count files';
  }

  @override
  String tidyDonePartial(int done, int failed) {
    return '$done tidied, $failed failed';
  }

  @override
  String get undoDone => 'Put back where it was';

  @override
  String undoFailed(String error) {
    return 'Couldn\'t undo: $error';
  }

  @override
  String get watchErrorTitle => 'Couldn\'t read a folder';

  @override
  String get watchErrorHint =>
      'Check that the folder exists and that Daylight Broom is allowed to access files and folders in System Settings › Privacy & Security.';

  @override
  String get rulesTitle => 'Rules';

  @override
  String get rulesAdd => 'Add rule';

  @override
  String get rulesEmpty => 'No rules yet. Add one to start tidying.';

  @override
  String get rulesOrderHint => 'Rules higher up are applied first.';

  @override
  String rulesGroupCount(int enabled, int total) {
    return '$enabled of $total on';
  }

  @override
  String get ruleEdit => 'Edit';

  @override
  String get ruleDelete => 'Delete';

  @override
  String get ruleDeleteTitle => 'Delete this rule?';

  @override
  String ruleDeleteBody(String name) {
    return 'The rule “$name” will be deleted. Your activity history is kept.';
  }

  @override
  String get ruleEditorNewTitle => 'New rule';

  @override
  String get ruleEditorEditTitle => 'Edit rule';

  @override
  String get ruleFieldName => 'Rule name';

  @override
  String get ruleFieldFolder => 'Watched folder';

  @override
  String get ruleChooseFolder => 'Choose folder';

  @override
  String get ruleSectionCondition => 'Conditions (all must match)';

  @override
  String get ruleFieldExtensions => 'Extensions';

  @override
  String get ruleFieldExtensionsHint => 'pdf, docx, zip';

  @override
  String get ruleFieldNameContains => 'Name contains';

  @override
  String get ruleFieldMinSize => 'Min size';

  @override
  String get ruleFieldMaxSize => 'Max size';

  @override
  String get ruleFieldOlderThan => 'Age';

  @override
  String get ruleOlderThanSuffix => 'days or older';

  @override
  String get ruleSectionAction => 'Action';

  @override
  String get ruleActionMove => 'Move to folder';

  @override
  String get ruleActionTrash => 'Move to Trash';

  @override
  String get ruleFieldDestination => 'Destination folder';

  @override
  String get ruleTrashNote =>
      'Files go to the Trash. Nothing is deleted permanently.';

  @override
  String get ruleSave => 'Save';

  @override
  String get rulePreview => 'Preview';

  @override
  String get ruleErrName => 'Enter a rule name';

  @override
  String get ruleErrFolder => 'Enter a folder to watch';

  @override
  String get ruleErrCondition => 'Set at least one condition';

  @override
  String get ruleErrDestination => 'Enter a destination folder';

  @override
  String get ruleErrSameFolder =>
      'The destination is the same as the watched folder';

  @override
  String get ruleErrNumber => 'Enter a number, 0 or more';

  @override
  String get ruleErrSizeRange => 'Min size is larger than max size';

  @override
  String get rulePreviewTitle => 'Files matching this rule';

  @override
  String rulePreviewCount(int count) {
    return '$count files match right now';
  }

  @override
  String get rulePreviewNone => 'No files match right now.';

  @override
  String condNameContains(String text) {
    return 'name contains “$text”';
  }

  @override
  String condMinSize(String size) {
    return '$size or larger';
  }

  @override
  String condMaxSize(String size) {
    return '$size or smaller';
  }

  @override
  String condOlderThan(int days) {
    return '$days days or older';
  }

  @override
  String get loginItemLabel => 'Launch at login';

  @override
  String loginItemFailed(String error) {
    return 'Couldn\'t change the launch-at-login setting: $error';
  }

  @override
  String get presetsStart => 'Start with suggested rules';

  @override
  String get presetsTitle => 'Suggested rules';

  @override
  String get presetsIntro =>
      'The rules you pick apply to your Downloads folder. Files already there are tidied right away, and you can undo from Recent activity.';

  @override
  String presetsAdd(int count) {
    return 'Add ($count)';
  }

  @override
  String get presetsAlready => 'Already added';

  @override
  String presetCount(int count) {
    return '$count now';
  }

  @override
  String get presetDocuments => 'Documents';

  @override
  String get presetImages => 'Images';

  @override
  String get presetVideos => 'Videos';

  @override
  String get presetAudio => 'Audio';

  @override
  String get presetInstallers => 'Installers';

  @override
  String get presetArchives => 'Archives';

  @override
  String get presetOldInstallers => 'Installers older than 30 days';

  @override
  String get trayLoginItem => 'Launch at login';

  @override
  String get ruleIncludeSubfolders => 'Include files in subfolders';

  @override
  String get ruleSubfoldersSuffix => ' (incl. subfolders)';

  @override
  String get cleanupOptionsTooltip => 'Tidy options';

  @override
  String get optionRemoveEmptyFolders =>
      'Remove folders left empty after moving files';

  @override
  String get updateCheckMenuItem => 'Check for Updates';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateAvailableTitle => 'A new version is available';

  @override
  String updateAvailableBody(String appName, String current, String latest) {
    return '$appName $latest is available. You have $current.';
  }

  @override
  String get updateReleaseNotes => 'What\'s new';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get updateSkipVersion => 'Skip this version';

  @override
  String get updateDownloading => 'Downloading…';

  @override
  String get updateVerifying => 'Verifying the file…';

  @override
  String updateDownloadProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String get updateCancel => 'Cancel';

  @override
  String get updateFailedTitle => 'Couldn\'t update';

  @override
  String get updateCheckFailedTitle => 'Couldn\'t check for updates';

  @override
  String get updateErrorNetwork =>
      'Couldn\'t reach the update server. Check your internet connection and try again.';

  @override
  String get updateErrorChecksum =>
      'The downloaded file didn\'t pass verification, so it was not installed. Please try again later.';

  @override
  String get updateErrorInstall => 'Couldn\'t start the installation.';

  @override
  String get updateErrorGeneric =>
      'The update server sent an unexpected response. Please try again later.';

  @override
  String get updateUpToDateTitle => 'You\'re up to date';

  @override
  String updateUpToDateBody(String version) {
    return 'You\'re using version $version.';
  }

  @override
  String get updateUnavailableTitle => 'Install it manually';

  @override
  String updateUnavailableBody(String latest) {
    return 'Version $latest is available, but the app can\'t install it automatically. Please download it from the release page.';
  }

  @override
  String get updateOpenReleasePage => 'Open release page';

  @override
  String get updateMacosOpenedTitle => 'The installer window is open';

  @override
  String updateMacosOpenedBody(String appName) {
    return 'In the window that opened, drag $appName to the Applications folder. If it\'s running, quit it first and replace the old copy.';
  }

  @override
  String get updateWindowsInstallTitle => 'The installer is open';

  @override
  String updateWindowsInstallBody(String appName) {
    return '$appName must quit before it can be updated. Follow the installer\'s instructions.';
  }

  @override
  String updateQuitApp(String appName) {
    return 'Quit $appName';
  }

  @override
  String get updateLinuxInstallTitle => 'Ready to install';

  @override
  String updateLinuxInstallBody(String appName) {
    return '$appName will quit and install the update, then start again automatically.';
  }

  @override
  String get updateQuitAndInstall => 'Quit and install';

  @override
  String get targetUserCachesTitle => 'User Caches';

  @override
  String get targetUserCachesDesc =>
      'App caches in ~/Library/Caches. Apps rebuild these on demand.';

  @override
  String get targetUserLogsTitle => 'User Logs';

  @override
  String get targetUserLogsDesc => 'Diagnostic logs in ~/Library/Logs.';

  @override
  String get targetTrashTitle => 'Trash';

  @override
  String get targetTrashDesc =>
      'Items already in the Trash (including iCloud Drive). Cleaning empties the Trash.';

  @override
  String get targetSavedStateTitle => 'Saved Application State';

  @override
  String get targetSavedStateDesc => 'Window positions restored on relaunch.';

  @override
  String get targetWinTempTitle => 'Temporary Files';

  @override
  String get targetWinTempDesc =>
      'Files in your %TEMP% folder. Files in use are skipped.';

  @override
  String get targetWinInetCacheTitle => 'Internet Cache';

  @override
  String get targetWinInetCacheDesc => 'Windows internet cache (INetCache).';

  @override
  String get targetWinCrashDumpsTitle => 'Crash Dumps';

  @override
  String get targetWinCrashDumpsDesc => 'Dump files left by crashed programs.';

  @override
  String get targetWinWerTitle => 'Error Reports';

  @override
  String get targetWinWerDesc => 'Files collected by Windows Error Reporting.';

  @override
  String get targetBrowserChromeTitle => 'Chrome Cache';

  @override
  String get targetBrowserChromeDesc =>
      'Cache of the default Chrome profile. Bookmarks and sign-ins are untouched.';

  @override
  String get targetBrowserEdgeTitle => 'Edge Cache';

  @override
  String get targetBrowserEdgeDesc =>
      'Cache of the default Edge profile. Bookmarks and sign-ins are untouched.';

  @override
  String get targetXcodeDerivedTitle => 'Xcode DerivedData';

  @override
  String get targetXcodeDerivedDesc =>
      'Intermediate build products. Next build is a clean build.';

  @override
  String get targetXcodeArchivesTitle => 'Xcode Archives';

  @override
  String get targetXcodeArchivesDesc =>
      'Archived builds (.xcarchive) used for App Store uploads.';

  @override
  String get targetIosDeviceSupportTitle => 'iOS Device Support';

  @override
  String get targetIosDeviceSupportDesc =>
      'Debug symbols per iOS version. Re-downloaded when you plug the device in.';

  @override
  String get targetSimulatorsTitle => 'iOS Simulator Devices';

  @override
  String get targetSimulatorsDesc =>
      'Simulator disk images. Delete unused ones via \"xcrun simctl delete unavailable\".';

  @override
  String get targetGradleTitle => 'Gradle Caches';

  @override
  String get targetGradleDesc =>
      'Android dependency and build caches in ~/.gradle/caches.';

  @override
  String get targetPubCacheTitle => 'Dart Pub Cache';

  @override
  String get targetPubCacheDesc =>
      'Downloaded Dart/Flutter packages. Re-fetched by \"flutter pub get\".';

  @override
  String get targetCocoapodsTitle => 'CocoaPods Cache';

  @override
  String get targetCocoapodsDesc => 'Downloaded pods.';

  @override
  String get targetNpmTitle => 'npm / Yarn / pnpm Cache';

  @override
  String get targetNpmDesc => 'Package manager download caches.';

  @override
  String get targetHomebrewTitle => 'Homebrew Cache';

  @override
  String get targetHomebrewDesc =>
      'Downloaded bottles/formulae. Same as \"brew cleanup --prune=all\".';

  @override
  String get targetPipTitle => 'pip Cache';

  @override
  String get targetPipDesc => 'Python package downloads.';

  @override
  String get targetNugetTitle => 'NuGet Cache';

  @override
  String get targetNugetDesc =>
      'NuGet v3 download cache. Re-fetched on the next restore.';

  @override
  String get groupSystem => 'System';

  @override
  String get groupDeveloper => 'Developer';

  @override
  String get groupBrowser => 'Browsers';

  @override
  String get safetySafe => 'SAFE';

  @override
  String get safetyRebuild => 'REBUILDS';

  @override
  String get safetyReview => 'REVIEW';

  @override
  String get navJunk => 'Junk';

  @override
  String get junkTitle => 'Junk cleanup';

  @override
  String get junkScan => 'Scan';

  @override
  String get junkRescan => 'Scan again';

  @override
  String get junkScanning => 'Scanning…';

  @override
  String get junkIntro =>
      'Finds caches, temporary files and developer leftovers to win back space. Cleaned items are deleted right away, not sent to the Trash.';

  @override
  String get junkEmptyScanned => 'No junk to clean.';

  @override
  String junkSelectedSummary(int count, String size) {
    return '$count selected · $size';
  }

  @override
  String junkTotalFound(String size) {
    return 'Found $size in total';
  }

  @override
  String get junkClean => 'Clean selected';

  @override
  String junkCleaning(int done, int total) {
    return 'Cleaning… $done / $total';
  }

  @override
  String get junkConfirmTitle => 'Delete permanently?';

  @override
  String junkConfirmBody(int count, String size) {
    return 'Deletes the $count selected items ($size) right away, without using the Trash. This cannot be undone.';
  }

  @override
  String junkConfirmReview(String names) {
    return 'Includes items that need a closer look: $names';
  }

  @override
  String get junkConfirmAction => 'Delete permanently';

  @override
  String junkFreed(String size) {
    return 'Freed $size';
  }

  @override
  String junkFailed(int count, String reason) {
    return 'Could not remove $count items: $reason';
  }

  @override
  String junkUnreadable(String paths) {
    return 'Some folders could not be read: $paths';
  }

  @override
  String get junkRestricted =>
      'Some folders could not be fully measured because of permissions. Allowing Full Disk Access in System Settings › Privacy & Security gives a more accurate result.';

  @override
  String junkScanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String get junkUnsupported =>
      'Junk cleanup is not supported on this operating system.';

  @override
  String get junkSelectGroup => 'Select whole group';

  @override
  String get navOverview => 'Overview';

  @override
  String get overviewTitle => 'Disk';

  @override
  String get overviewRefresh => 'Refresh';

  @override
  String get overviewUsedPercent => 'used';

  @override
  String get overviewFree => 'Free';

  @override
  String get overviewUsed => 'Used';

  @override
  String get overviewTotal => 'Total';

  @override
  String get overviewJunkFound => 'Junk found';

  @override
  String get overviewJunkNotScanned => 'Not scanned yet';

  @override
  String get overviewJunkScanning => 'Scanning…';

  @override
  String overviewFreeable(String size) {
    return 'Cleaning the current selection frees about $size';
  }

  @override
  String get overviewCardJunkTitle => 'Junk cleanup';

  @override
  String get overviewCardJunkSubtitle =>
      'Caches, temp files and developer leftovers';

  @override
  String get overviewCardTidyTitle => 'Auto tidy';

  @override
  String overviewCardTidySubtitle(int count) {
    return '$count rules are watching your folders';
  }

  @override
  String get overviewUnavailable => 'Could not read the disk capacity.';

  @override
  String get fdaBannerText =>
      'Full Disk Access is off — some caches (Safari, Mail…) stay hidden.';

  @override
  String get fdaShowMe => 'Show me how';

  @override
  String get fdaOpenSettings => 'Open Settings';

  @override
  String get fdaGranted => 'GRANTED';

  @override
  String get fdaWaiting => 'WAITING FOR PERMISSION…';

  @override
  String get fdaStep1Title => 'Open Full Disk Access settings';

  @override
  String get fdaStep1Body =>
      'macOS keeps some folders (Safari, Mail, Messages…) private unless you allow an app explicitly. Press the button below to jump straight to System Settings › Privacy & Security › Full Disk Access.';

  @override
  String get fdaStep2Title => 'Click \"+\" and unlock';

  @override
  String get fdaStep2Body =>
      'Click the \"+\" button under the list. macOS asks for Touch ID or your password before it lets you change this setting.';

  @override
  String fdaStep3Title(String appName) {
    return 'Pick $appName';
  }

  @override
  String fdaStep3Body(String appName) {
    return 'In the file picker, search for \"$appName\" (or browse to Applications), select it and click Open. You can also drag it from a Finder window straight into the list.';
  }

  @override
  String get fdaStep4Title => 'Quit & Reopen';

  @override
  String fdaStep4Body(String appName) {
    return 'macOS explains that $appName only gets the permission after a restart. Click \"Quit & Reopen\" — it comes right back and the warning banner is gone.';
  }

  @override
  String get fdaStep5Title => 'All set';

  @override
  String fdaStep5Body(String appName) {
    return '$appName now shows a switch turned on in the list. Scanning again will include caches that were hidden before.';
  }

  @override
  String fdaShowInFinder(String appName) {
    return 'Show $appName in Finder';
  }

  @override
  String get fdaBack => 'Back';

  @override
  String get fdaNext => 'Next';

  @override
  String get fdaDone => 'Done';

  @override
  String get fdaClose => 'Close';

  @override
  String get navApps => 'Uninstall';

  @override
  String get appsTitle => 'Apps';

  @override
  String get appsSearchHint => 'Search apps';

  @override
  String get appsRefresh => 'Reload';

  @override
  String get appsEmpty => 'No installed apps found.';

  @override
  String get appsSelectHint => 'Select an app to see its leftover files';

  @override
  String get appsNoBundleId => 'no bundle id';

  @override
  String appsVersion(String version) {
    return 'v$version';
  }

  @override
  String get appsFinding => 'Looking for leftover files…';

  @override
  String appsLeftoversTitle(int count) {
    return 'Leftovers in ~/Library · $count';
  }

  @override
  String get appsLeftoversNone => 'Nothing found.';

  @override
  String get appsLeftoversNameHint =>
      'Items found only by a similar name may belong to another app, so they are not selected by default. Check them yourself.';

  @override
  String get appsMatchName => 'NAME MATCH';

  @override
  String appsToRemove(String size) {
    return '$size to remove';
  }

  @override
  String get appsUninstall => 'Uninstall';

  @override
  String get appsUninstalling => 'Removing…';

  @override
  String appsConfirmTitle(String name) {
    return 'Uninstall $name?';
  }

  @override
  String appsConfirmBody(int count, String size) {
    return 'Moves $count items ($size) to the Trash. You can restore them from the Trash.';
  }

  @override
  String get appsConfirmAction => 'Move to Trash';

  @override
  String appsMoved(String size) {
    return 'Moved $size to the Trash';
  }

  @override
  String appsFailed(int count, String reason) {
    return 'Could not move $count items: $reason';
  }

  @override
  String get appsReveal => 'Show in Finder';
}
