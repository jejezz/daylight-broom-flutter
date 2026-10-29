import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @navTidy.
  ///
  /// In ko, this message translates to:
  /// **'자동 정리'**
  String get navTidy;

  /// No description provided for @aboutTooltip.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get aboutTooltip;

  /// No description provided for @aboutVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version} (빌드 {build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutOpenSourceLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @aboutRepository.
  ///
  /// In ko, this message translates to:
  /// **'GitHub'**
  String get aboutRepository;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @aboutMenuItem.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 정보'**
  String aboutMenuItem(String appName);

  /// No description provided for @themeMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get themeMenuTooltip;

  /// No description provided for @themeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get themeDark;

  /// No description provided for @languageMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageMenuTooltip;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기 / System'**
  String get languageSystem;

  /// No description provided for @languageSystemShort.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get languageSystemShort;

  /// No description provided for @settingsTooltip.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In ko, this message translates to:
  /// **'외형'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsMode.
  ///
  /// In ko, this message translates to:
  /// **'모드'**
  String get settingsMode;

  /// No description provided for @settingsModeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get settingsModeSystem;

  /// No description provided for @settingsPalette.
  ///
  /// In ko, this message translates to:
  /// **'색 구성'**
  String get settingsPalette;

  /// No description provided for @settingsPaletteSaturn.
  ///
  /// In ko, this message translates to:
  /// **'새턴'**
  String get settingsPaletteSaturn;

  /// No description provided for @settingsPaletteTeal.
  ///
  /// In ko, this message translates to:
  /// **'청록'**
  String get settingsPaletteTeal;

  /// No description provided for @settingsPaletteAmber.
  ///
  /// In ko, this message translates to:
  /// **'호박'**
  String get settingsPaletteAmber;

  /// No description provided for @settingsPaletteRose.
  ///
  /// In ko, this message translates to:
  /// **'장미'**
  String get settingsPaletteRose;

  /// No description provided for @settingsPaletteSlate.
  ///
  /// In ko, this message translates to:
  /// **'슬레이트'**
  String get settingsPaletteSlate;

  /// No description provided for @settingsPaletteHighContrast.
  ///
  /// In ko, this message translates to:
  /// **'고대비'**
  String get settingsPaletteHighContrast;

  /// No description provided for @aboutTagline.
  ///
  /// In ko, this message translates to:
  /// **'정크를 치우고, 앱을 깔끔히 지우고, 폴더를 규칙대로 정리합니다'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In ko, this message translates to:
  /// **'Daylight Broom은 캐시·임시 파일·개발 도구 찌꺼기를 찾아 용량을 되찾고, 앱을 남은 파일까지 함께 제거하며, 다운로드 폴더 같은 곳의 파일을 확장자·이름·크기·오래된 정도에 따라 자동으로 정리합니다. 트레이에 상주하며 바로 처리하거나, 원할 때 직접 실행할 수 있습니다.'**
  String get aboutDescription;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 정리 규칙이 없습니다. 규칙을 추가해 다운로드 폴더 정리를 시작하세요'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyAction.
  ///
  /// In ko, this message translates to:
  /// **'규칙 추가'**
  String get homeEmptyAction;

  /// No description provided for @trayOpen.
  ///
  /// In ko, this message translates to:
  /// **'Daylight Broom 열기'**
  String get trayOpen;

  /// No description provided for @trayTidyNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 정리'**
  String get trayTidyNow;

  /// No description provided for @trayQuit.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get trayQuit;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get commonCopy;

  /// No description provided for @tidyNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 정리'**
  String get tidyNow;

  /// No description provided for @homeRulesSummary.
  ///
  /// In ko, this message translates to:
  /// **'규칙 {count}개 · 감시 중'**
  String homeRulesSummary(int count);

  /// No description provided for @previewTitle.
  ///
  /// In ko, this message translates to:
  /// **'정리 미리보기'**
  String get previewTitle;

  /// No description provided for @previewNoRules.
  ///
  /// In ko, this message translates to:
  /// **'켜져 있는 규칙이 없습니다. 규칙을 추가하면 여기서 결과를 미리 볼 수 있습니다.'**
  String get previewNoRules;

  /// No description provided for @previewNothing.
  ///
  /// In ko, this message translates to:
  /// **'지금 정리할 파일이 없습니다.'**
  String get previewNothing;

  /// No description provided for @previewWaiting.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 파일은 받는 중이거나 방금 바뀌어서 이번에는 건너뜁니다.'**
  String previewWaiting(int count);

  /// No description provided for @previewSummary.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 파일을 정리합니다'**
  String previewSummary(int count);

  /// No description provided for @previewRun.
  ///
  /// In ko, this message translates to:
  /// **'정리 실행 ({count})'**
  String previewRun(int count);

  /// No description provided for @previewRunning.
  ///
  /// In ko, this message translates to:
  /// **'정리하는 중… ({done}/{total})'**
  String previewRunning(int done, int total);

  /// No description provided for @actionMoveTo.
  ///
  /// In ko, this message translates to:
  /// **'→ {folder}'**
  String actionMoveTo(String folder);

  /// No description provided for @actionTrash.
  ///
  /// In ko, this message translates to:
  /// **'→ 휴지통'**
  String get actionTrash;

  /// No description provided for @historyTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 기록'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 정리한 파일이 없습니다.'**
  String get historyEmpty;

  /// No description provided for @historyUndo.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get historyUndo;

  /// No description provided for @historyUndone.
  ///
  /// In ko, this message translates to:
  /// **'되돌림'**
  String get historyUndone;

  /// No description provided for @historyFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get historyFailed;

  /// No description provided for @historyUndoUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'휴지통 위치를 알 수 없어 되돌릴 수 없습니다. 휴지통에서 직접 복원해 주세요.'**
  String get historyUndoUnavailable;

  /// No description provided for @tidyDone.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 파일을 정리했습니다'**
  String tidyDone(int count);

  /// No description provided for @tidyDonePartial.
  ///
  /// In ko, this message translates to:
  /// **'{done}개 정리, {failed}개 실패'**
  String tidyDonePartial(int done, int failed);

  /// No description provided for @undoDone.
  ///
  /// In ko, this message translates to:
  /// **'원래 위치로 되돌렸습니다'**
  String get undoDone;

  /// No description provided for @undoFailed.
  ///
  /// In ko, this message translates to:
  /// **'되돌리지 못했습니다: {error}'**
  String undoFailed(String error);

  /// No description provided for @watchErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 읽지 못했습니다'**
  String get watchErrorTitle;

  /// No description provided for @watchErrorHint.
  ///
  /// In ko, this message translates to:
  /// **'폴더가 있는지, 시스템 설정의 개인정보 보호 및 보안에서 Daylight Broom의 파일 및 폴더 접근이 허용돼 있는지 확인하세요.'**
  String get watchErrorHint;

  /// No description provided for @rulesTitle.
  ///
  /// In ko, this message translates to:
  /// **'규칙'**
  String get rulesTitle;

  /// No description provided for @rulesAdd.
  ///
  /// In ko, this message translates to:
  /// **'규칙 추가'**
  String get rulesAdd;

  /// No description provided for @rulesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'규칙이 없습니다. 규칙을 추가해 정리를 시작하세요.'**
  String get rulesEmpty;

  /// No description provided for @rulesOrderHint.
  ///
  /// In ko, this message translates to:
  /// **'위에 있는 규칙이 먼저 적용됩니다.'**
  String get rulesOrderHint;

  /// No description provided for @rulesGroupCount.
  ///
  /// In ko, this message translates to:
  /// **'{total}개 중 {enabled}개 켜짐'**
  String rulesGroupCount(int enabled, int total);

  /// No description provided for @ruleEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get ruleEdit;

  /// No description provided for @ruleDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get ruleDelete;

  /// No description provided for @ruleDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'규칙을 삭제할까요?'**
  String get ruleDeleteTitle;

  /// No description provided for @ruleDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'“{name}” 규칙이 삭제됩니다. 정리 기록은 남습니다.'**
  String ruleDeleteBody(String name);

  /// No description provided for @ruleEditorNewTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 규칙'**
  String get ruleEditorNewTitle;

  /// No description provided for @ruleEditorEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'규칙 수정'**
  String get ruleEditorEditTitle;

  /// No description provided for @ruleFieldName.
  ///
  /// In ko, this message translates to:
  /// **'규칙 이름'**
  String get ruleFieldName;

  /// No description provided for @ruleFieldFolder.
  ///
  /// In ko, this message translates to:
  /// **'감시 폴더'**
  String get ruleFieldFolder;

  /// No description provided for @ruleChooseFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더 선택'**
  String get ruleChooseFolder;

  /// No description provided for @ruleSectionCondition.
  ///
  /// In ko, this message translates to:
  /// **'조건 (모두 만족해야 합니다)'**
  String get ruleSectionCondition;

  /// No description provided for @ruleFieldExtensions.
  ///
  /// In ko, this message translates to:
  /// **'확장자'**
  String get ruleFieldExtensions;

  /// No description provided for @ruleFieldExtensionsHint.
  ///
  /// In ko, this message translates to:
  /// **'pdf, docx, zip'**
  String get ruleFieldExtensionsHint;

  /// No description provided for @ruleFieldNameContains.
  ///
  /// In ko, this message translates to:
  /// **'이름에 포함'**
  String get ruleFieldNameContains;

  /// No description provided for @ruleFieldMinSize.
  ///
  /// In ko, this message translates to:
  /// **'최소 크기'**
  String get ruleFieldMinSize;

  /// No description provided for @ruleFieldMaxSize.
  ///
  /// In ko, this message translates to:
  /// **'최대 크기'**
  String get ruleFieldMaxSize;

  /// No description provided for @ruleFieldOlderThan.
  ///
  /// In ko, this message translates to:
  /// **'경과 일수'**
  String get ruleFieldOlderThan;

  /// No description provided for @ruleOlderThanSuffix.
  ///
  /// In ko, this message translates to:
  /// **'일 이상 지난 파일'**
  String get ruleOlderThanSuffix;

  /// No description provided for @ruleSectionAction.
  ///
  /// In ko, this message translates to:
  /// **'동작'**
  String get ruleSectionAction;

  /// No description provided for @ruleActionMove.
  ///
  /// In ko, this message translates to:
  /// **'폴더로 이동'**
  String get ruleActionMove;

  /// No description provided for @ruleActionTrash.
  ///
  /// In ko, this message translates to:
  /// **'휴지통으로'**
  String get ruleActionTrash;

  /// No description provided for @ruleFieldDestination.
  ///
  /// In ko, this message translates to:
  /// **'이동할 폴더'**
  String get ruleFieldDestination;

  /// No description provided for @ruleTrashNote.
  ///
  /// In ko, this message translates to:
  /// **'휴지통으로 보냅니다. 영구 삭제하지 않습니다.'**
  String get ruleTrashNote;

  /// No description provided for @ruleSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get ruleSave;

  /// No description provided for @rulePreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get rulePreview;

  /// No description provided for @ruleErrName.
  ///
  /// In ko, this message translates to:
  /// **'규칙 이름을 입력하세요'**
  String get ruleErrName;

  /// No description provided for @ruleErrFolder.
  ///
  /// In ko, this message translates to:
  /// **'감시 폴더를 입력하세요'**
  String get ruleErrFolder;

  /// No description provided for @ruleErrCondition.
  ///
  /// In ko, this message translates to:
  /// **'조건을 하나 이상 지정하세요'**
  String get ruleErrCondition;

  /// No description provided for @ruleErrDestination.
  ///
  /// In ko, this message translates to:
  /// **'이동할 폴더를 입력하세요'**
  String get ruleErrDestination;

  /// No description provided for @ruleErrSameFolder.
  ///
  /// In ko, this message translates to:
  /// **'이동할 폴더가 감시 폴더와 같습니다'**
  String get ruleErrSameFolder;

  /// No description provided for @ruleErrNumber.
  ///
  /// In ko, this message translates to:
  /// **'0 이상의 숫자를 입력하세요'**
  String get ruleErrNumber;

  /// No description provided for @ruleErrSizeRange.
  ///
  /// In ko, this message translates to:
  /// **'최소 크기가 최대 크기보다 큽니다'**
  String get ruleErrSizeRange;

  /// No description provided for @rulePreviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 규칙에 맞는 파일'**
  String get rulePreviewTitle;

  /// No description provided for @rulePreviewCount.
  ///
  /// In ko, this message translates to:
  /// **'지금 {count}개 파일이 맞습니다'**
  String rulePreviewCount(int count);

  /// No description provided for @rulePreviewNone.
  ///
  /// In ko, this message translates to:
  /// **'지금 맞는 파일이 없습니다.'**
  String get rulePreviewNone;

  /// No description provided for @condNameContains.
  ///
  /// In ko, this message translates to:
  /// **'이름에 “{text}” 포함'**
  String condNameContains(String text);

  /// No description provided for @condMinSize.
  ///
  /// In ko, this message translates to:
  /// **'{size} 이상'**
  String condMinSize(String size);

  /// No description provided for @condMaxSize.
  ///
  /// In ko, this message translates to:
  /// **'{size} 이하'**
  String condMaxSize(String size);

  /// No description provided for @condOlderThan.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 이상 지남'**
  String condOlderThan(int days);

  /// No description provided for @loginItemLabel.
  ///
  /// In ko, this message translates to:
  /// **'로그인 시 자동 실행'**
  String get loginItemLabel;

  /// No description provided for @loginItemFailed.
  ///
  /// In ko, this message translates to:
  /// **'자동 실행 설정을 바꾸지 못했습니다: {error}'**
  String loginItemFailed(String error);

  /// No description provided for @presetsStart.
  ///
  /// In ko, this message translates to:
  /// **'추천 규칙으로 시작'**
  String get presetsStart;

  /// No description provided for @presetsTitle.
  ///
  /// In ko, this message translates to:
  /// **'추천 규칙'**
  String get presetsTitle;

  /// No description provided for @presetsIntro.
  ///
  /// In ko, this message translates to:
  /// **'고른 규칙은 Downloads 폴더에 적용됩니다. 이미 있는 파일도 바로 정리되고, 최근 기록에서 되돌릴 수 있습니다.'**
  String get presetsIntro;

  /// No description provided for @presetsAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가 ({count})'**
  String presetsAdd(int count);

  /// No description provided for @presetsAlready.
  ///
  /// In ko, this message translates to:
  /// **'이미 있음'**
  String get presetsAlready;

  /// No description provided for @presetCount.
  ///
  /// In ko, this message translates to:
  /// **'지금 {count}개'**
  String presetCount(int count);

  /// No description provided for @presetDocuments.
  ///
  /// In ko, this message translates to:
  /// **'문서'**
  String get presetDocuments;

  /// No description provided for @presetImages.
  ///
  /// In ko, this message translates to:
  /// **'이미지'**
  String get presetImages;

  /// No description provided for @presetVideos.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get presetVideos;

  /// No description provided for @presetAudio.
  ///
  /// In ko, this message translates to:
  /// **'음악·오디오'**
  String get presetAudio;

  /// No description provided for @presetInstallers.
  ///
  /// In ko, this message translates to:
  /// **'설치 파일'**
  String get presetInstallers;

  /// No description provided for @presetArchives.
  ///
  /// In ko, this message translates to:
  /// **'압축 파일'**
  String get presetArchives;

  /// No description provided for @presetOldInstallers.
  ///
  /// In ko, this message translates to:
  /// **'30일 지난 설치 파일'**
  String get presetOldInstallers;

  /// No description provided for @trayLoginItem.
  ///
  /// In ko, this message translates to:
  /// **'로그인 시 자동 실행'**
  String get trayLoginItem;

  /// No description provided for @ruleIncludeSubfolders.
  ///
  /// In ko, this message translates to:
  /// **'하위 폴더의 파일도 포함'**
  String get ruleIncludeSubfolders;

  /// No description provided for @ruleSubfoldersSuffix.
  ///
  /// In ko, this message translates to:
  /// **' (하위 폴더 포함)'**
  String get ruleSubfoldersSuffix;

  /// No description provided for @cleanupOptionsTooltip.
  ///
  /// In ko, this message translates to:
  /// **'정리 옵션'**
  String get cleanupOptionsTooltip;

  /// No description provided for @optionRemoveEmptyFolders.
  ///
  /// In ko, this message translates to:
  /// **'파일을 옮긴 뒤 비게 된 폴더 지우기'**
  String get optionRemoveEmptyFolders;

  /// No description provided for @updateCheckMenuItem.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 확인'**
  String get updateCheckMenuItem;

  /// No description provided for @updateChecking.
  ///
  /// In ko, this message translates to:
  /// **'업데이트를 확인하는 중…'**
  String get updateChecking;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 버전이 있습니다'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In ko, this message translates to:
  /// **'{appName} {latest} 버전이 나왔습니다. (현재 {current})'**
  String updateAvailableBody(String appName, String current, String latest);

  /// No description provided for @updateReleaseNotes.
  ///
  /// In ko, this message translates to:
  /// **'변경 내용'**
  String get updateReleaseNotes;

  /// No description provided for @updateNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 업데이트'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get updateLater;

  /// No description provided for @updateSkipVersion.
  ///
  /// In ko, this message translates to:
  /// **'이 버전 건너뛰기'**
  String get updateSkipVersion;

  /// No description provided for @updateDownloading.
  ///
  /// In ko, this message translates to:
  /// **'내려받는 중…'**
  String get updateDownloading;

  /// No description provided for @updateVerifying.
  ///
  /// In ko, this message translates to:
  /// **'파일을 확인하는 중…'**
  String get updateVerifying;

  /// No description provided for @updateDownloadProgress.
  ///
  /// In ko, this message translates to:
  /// **'{received} / {total}'**
  String updateDownloadProgress(String received, String total);

  /// No description provided for @updateCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get updateCancel;

  /// No description provided for @updateFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트하지 못했습니다'**
  String get updateFailedTitle;

  /// No description provided for @updateCheckFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트를 확인하지 못했습니다'**
  String get updateCheckFailedTitle;

  /// No description provided for @updateErrorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 서버에 연결하지 못했습니다. 인터넷 연결을 확인한 뒤 다시 시도해 주세요.'**
  String get updateErrorNetwork;

  /// No description provided for @updateErrorChecksum.
  ///
  /// In ko, this message translates to:
  /// **'내려받은 파일이 올바르지 않아 설치하지 않았습니다. 잠시 뒤에 다시 시도해 주세요.'**
  String get updateErrorChecksum;

  /// No description provided for @updateErrorInstall.
  ///
  /// In ko, this message translates to:
  /// **'설치를 시작하지 못했습니다.'**
  String get updateErrorInstall;

  /// No description provided for @updateErrorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 서버에서 예상하지 못한 응답을 받았습니다. 잠시 뒤에 다시 시도해 주세요.'**
  String get updateErrorGeneric;

  /// No description provided for @updateUpToDateTitle.
  ///
  /// In ko, this message translates to:
  /// **'최신 버전입니다'**
  String get updateUpToDateTitle;

  /// No description provided for @updateUpToDateBody.
  ///
  /// In ko, this message translates to:
  /// **'{version} 버전을 사용 중입니다.'**
  String updateUpToDateBody(String version);

  /// No description provided for @updateUnavailableTitle.
  ///
  /// In ko, this message translates to:
  /// **'직접 설치해 주세요'**
  String get updateUnavailableTitle;

  /// No description provided for @updateUnavailableBody.
  ///
  /// In ko, this message translates to:
  /// **'{latest} 버전이 있지만 앱에서 자동으로 설치할 수 없습니다. 릴리스 페이지에서 받아 주세요.'**
  String updateUnavailableBody(String latest);

  /// No description provided for @updateOpenReleasePage.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 페이지 열기'**
  String get updateOpenReleasePage;

  /// No description provided for @updateMacosOpenedTitle.
  ///
  /// In ko, this message translates to:
  /// **'설치 창이 열렸습니다'**
  String get updateMacosOpenedTitle;

  /// No description provided for @updateMacosOpenedBody.
  ///
  /// In ko, this message translates to:
  /// **'열린 창에서 {appName} 을(를) Applications 폴더로 끌어다 놓아 주세요. 실행 중이면 종료한 뒤 덮어쓰세요.'**
  String updateMacosOpenedBody(String appName);

  /// No description provided for @updateWindowsInstallTitle.
  ///
  /// In ko, this message translates to:
  /// **'설치 프로그램을 열었습니다'**
  String get updateWindowsInstallTitle;

  /// No description provided for @updateWindowsInstallBody.
  ///
  /// In ko, this message translates to:
  /// **'설치하려면 {appName} 을(를) 종료해야 합니다. 설치 프로그램의 안내를 따라 주세요.'**
  String updateWindowsInstallBody(String appName);

  /// No description provided for @updateQuitApp.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 종료'**
  String updateQuitApp(String appName);

  /// No description provided for @updateLinuxInstallTitle.
  ///
  /// In ko, this message translates to:
  /// **'설치를 준비했습니다'**
  String get updateLinuxInstallTitle;

  /// No description provided for @updateLinuxInstallBody.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 을(를) 종료하고 설치합니다. 설치가 끝나면 자동으로 다시 시작됩니다.'**
  String updateLinuxInstallBody(String appName);

  /// No description provided for @updateQuitAndInstall.
  ///
  /// In ko, this message translates to:
  /// **'종료하고 설치'**
  String get updateQuitAndInstall;

  /// No description provided for @targetUserCachesTitle.
  ///
  /// In ko, this message translates to:
  /// **'사용자 캐시'**
  String get targetUserCachesTitle;

  /// No description provided for @targetUserCachesDesc.
  ///
  /// In ko, this message translates to:
  /// **'~/Library/Caches의 앱 캐시. 앱이 필요할 때 다시 만듭니다.'**
  String get targetUserCachesDesc;

  /// No description provided for @targetUserLogsTitle.
  ///
  /// In ko, this message translates to:
  /// **'사용자 로그'**
  String get targetUserLogsTitle;

  /// No description provided for @targetUserLogsDesc.
  ///
  /// In ko, this message translates to:
  /// **'~/Library/Logs의 진단 로그.'**
  String get targetUserLogsDesc;

  /// No description provided for @targetTrashTitle.
  ///
  /// In ko, this message translates to:
  /// **'휴지통'**
  String get targetTrashTitle;

  /// No description provided for @targetTrashDesc.
  ///
  /// In ko, this message translates to:
  /// **'휴지통(iCloud Drive 포함)에 있는 항목. 정리하면 휴지통을 비웁니다.'**
  String get targetTrashDesc;

  /// No description provided for @targetSavedStateTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장된 앱 상태'**
  String get targetSavedStateTitle;

  /// No description provided for @targetSavedStateDesc.
  ///
  /// In ko, this message translates to:
  /// **'다시 열 때 복원하는 창 위치.'**
  String get targetSavedStateDesc;

  /// No description provided for @targetWinTempTitle.
  ///
  /// In ko, this message translates to:
  /// **'임시 파일'**
  String get targetWinTempTitle;

  /// No description provided for @targetWinTempDesc.
  ///
  /// In ko, this message translates to:
  /// **'%TEMP% 폴더의 임시 파일. 사용 중인 파일은 건너뜁니다.'**
  String get targetWinTempDesc;

  /// No description provided for @targetWinInetCacheTitle.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 임시 파일'**
  String get targetWinInetCacheTitle;

  /// No description provided for @targetWinInetCacheDesc.
  ///
  /// In ko, this message translates to:
  /// **'Windows 인터넷 캐시(INetCache).'**
  String get targetWinInetCacheDesc;

  /// No description provided for @targetWinCrashDumpsTitle.
  ///
  /// In ko, this message translates to:
  /// **'충돌 덤프'**
  String get targetWinCrashDumpsTitle;

  /// No description provided for @targetWinCrashDumpsDesc.
  ///
  /// In ko, this message translates to:
  /// **'프로그램이 비정상 종료될 때 남은 덤프 파일.'**
  String get targetWinCrashDumpsDesc;

  /// No description provided for @targetWinWerTitle.
  ///
  /// In ko, this message translates to:
  /// **'오류 보고 파일'**
  String get targetWinWerTitle;

  /// No description provided for @targetWinWerDesc.
  ///
  /// In ko, this message translates to:
  /// **'Windows 오류 보고(WER)가 쌓은 파일.'**
  String get targetWinWerDesc;

  /// No description provided for @targetBrowserChromeTitle.
  ///
  /// In ko, this message translates to:
  /// **'Chrome 캐시'**
  String get targetBrowserChromeTitle;

  /// No description provided for @targetBrowserChromeDesc.
  ///
  /// In ko, this message translates to:
  /// **'Chrome 기본 프로필의 캐시. 북마크·로그인은 지우지 않습니다.'**
  String get targetBrowserChromeDesc;

  /// No description provided for @targetBrowserEdgeTitle.
  ///
  /// In ko, this message translates to:
  /// **'Edge 캐시'**
  String get targetBrowserEdgeTitle;

  /// No description provided for @targetBrowserEdgeDesc.
  ///
  /// In ko, this message translates to:
  /// **'Edge 기본 프로필의 캐시. 북마크·로그인은 지우지 않습니다.'**
  String get targetBrowserEdgeDesc;

  /// No description provided for @targetXcodeDerivedTitle.
  ///
  /// In ko, this message translates to:
  /// **'Xcode DerivedData'**
  String get targetXcodeDerivedTitle;

  /// No description provided for @targetXcodeDerivedDesc.
  ///
  /// In ko, this message translates to:
  /// **'빌드 중간 산출물. 다음 빌드는 처음부터 빌드합니다.'**
  String get targetXcodeDerivedDesc;

  /// No description provided for @targetXcodeArchivesTitle.
  ///
  /// In ko, this message translates to:
  /// **'Xcode 아카이브'**
  String get targetXcodeArchivesTitle;

  /// No description provided for @targetXcodeArchivesDesc.
  ///
  /// In ko, this message translates to:
  /// **'App Store 업로드에 쓴 보관 빌드(.xcarchive).'**
  String get targetXcodeArchivesDesc;

  /// No description provided for @targetIosDeviceSupportTitle.
  ///
  /// In ko, this message translates to:
  /// **'iOS 기기 지원 파일'**
  String get targetIosDeviceSupportTitle;

  /// No description provided for @targetIosDeviceSupportDesc.
  ///
  /// In ko, this message translates to:
  /// **'iOS 버전별 디버그 심볼. 기기를 연결하면 다시 받습니다.'**
  String get targetIosDeviceSupportDesc;

  /// No description provided for @targetSimulatorsTitle.
  ///
  /// In ko, this message translates to:
  /// **'iOS 시뮬레이터 기기'**
  String get targetSimulatorsTitle;

  /// No description provided for @targetSimulatorsDesc.
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이터 디스크 이미지. 안 쓰는 것은 \"xcrun simctl delete unavailable\"로 지우세요.'**
  String get targetSimulatorsDesc;

  /// No description provided for @targetGradleTitle.
  ///
  /// In ko, this message translates to:
  /// **'Gradle 캐시'**
  String get targetGradleTitle;

  /// No description provided for @targetGradleDesc.
  ///
  /// In ko, this message translates to:
  /// **'~/.gradle/caches의 안드로이드 의존성·빌드 캐시.'**
  String get targetGradleDesc;

  /// No description provided for @targetPubCacheTitle.
  ///
  /// In ko, this message translates to:
  /// **'Dart Pub 캐시'**
  String get targetPubCacheTitle;

  /// No description provided for @targetPubCacheDesc.
  ///
  /// In ko, this message translates to:
  /// **'내려받은 Dart/Flutter 패키지. \"flutter pub get\"으로 다시 받습니다.'**
  String get targetPubCacheDesc;

  /// No description provided for @targetCocoapodsTitle.
  ///
  /// In ko, this message translates to:
  /// **'CocoaPods 캐시'**
  String get targetCocoapodsTitle;

  /// No description provided for @targetCocoapodsDesc.
  ///
  /// In ko, this message translates to:
  /// **'내려받은 pod.'**
  String get targetCocoapodsDesc;

  /// No description provided for @targetNpmTitle.
  ///
  /// In ko, this message translates to:
  /// **'npm / Yarn / pnpm 캐시'**
  String get targetNpmTitle;

  /// No description provided for @targetNpmDesc.
  ///
  /// In ko, this message translates to:
  /// **'패키지 관리자 다운로드 캐시.'**
  String get targetNpmDesc;

  /// No description provided for @targetHomebrewTitle.
  ///
  /// In ko, this message translates to:
  /// **'Homebrew 캐시'**
  String get targetHomebrewTitle;

  /// No description provided for @targetHomebrewDesc.
  ///
  /// In ko, this message translates to:
  /// **'내려받은 병/포뮬러. \"brew cleanup --prune=all\"과 같습니다.'**
  String get targetHomebrewDesc;

  /// No description provided for @targetPipTitle.
  ///
  /// In ko, this message translates to:
  /// **'pip 캐시'**
  String get targetPipTitle;

  /// No description provided for @targetPipDesc.
  ///
  /// In ko, this message translates to:
  /// **'Python 패키지 다운로드.'**
  String get targetPipDesc;

  /// No description provided for @targetNugetTitle.
  ///
  /// In ko, this message translates to:
  /// **'NuGet 캐시'**
  String get targetNugetTitle;

  /// No description provided for @targetNugetDesc.
  ///
  /// In ko, this message translates to:
  /// **'NuGet v3 다운로드 캐시. 다음 복원 때 다시 받습니다.'**
  String get targetNugetDesc;

  /// No description provided for @groupSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get groupSystem;

  /// No description provided for @groupDeveloper.
  ///
  /// In ko, this message translates to:
  /// **'개발'**
  String get groupDeveloper;

  /// No description provided for @groupBrowser.
  ///
  /// In ko, this message translates to:
  /// **'브라우저'**
  String get groupBrowser;

  /// No description provided for @safetySafe.
  ///
  /// In ko, this message translates to:
  /// **'안전'**
  String get safetySafe;

  /// No description provided for @safetyRebuild.
  ///
  /// In ko, this message translates to:
  /// **'다시 생성'**
  String get safetyRebuild;

  /// No description provided for @safetyReview.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요'**
  String get safetyReview;

  /// No description provided for @navJunk.
  ///
  /// In ko, this message translates to:
  /// **'정크 정리'**
  String get navJunk;

  /// No description provided for @junkTitle.
  ///
  /// In ko, this message translates to:
  /// **'정크 정리'**
  String get junkTitle;

  /// No description provided for @junkScan.
  ///
  /// In ko, this message translates to:
  /// **'스캔'**
  String get junkScan;

  /// No description provided for @junkRescan.
  ///
  /// In ko, this message translates to:
  /// **'다시 스캔'**
  String get junkRescan;

  /// No description provided for @junkScanning.
  ///
  /// In ko, this message translates to:
  /// **'스캔하는 중…'**
  String get junkScanning;

  /// No description provided for @junkIntro.
  ///
  /// In ko, this message translates to:
  /// **'캐시·임시 파일·개발 도구 찌꺼기를 찾아 용량을 되찾습니다. 지운 항목은 휴지통을 거치지 않고 바로 삭제됩니다.'**
  String get junkIntro;

  /// No description provided for @junkEmptyScanned.
  ///
  /// In ko, this message translates to:
  /// **'정리할 정크가 없습니다.'**
  String get junkEmptyScanned;

  /// No description provided for @junkSelectedSummary.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택 · {size}'**
  String junkSelectedSummary(int count, String size);

  /// No description provided for @junkTotalFound.
  ///
  /// In ko, this message translates to:
  /// **'총 {size}를 찾았습니다'**
  String junkTotalFound(String size);

  /// No description provided for @junkClean.
  ///
  /// In ko, this message translates to:
  /// **'선택 항목 정리'**
  String get junkClean;

  /// No description provided for @junkCleaning.
  ///
  /// In ko, this message translates to:
  /// **'정리하는 중… {done} / {total}'**
  String junkCleaning(int done, int total);

  /// No description provided for @junkConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'영구 삭제할까요?'**
  String get junkConfirmTitle;

  /// No description provided for @junkConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'선택한 {count}개 항목({size})을 휴지통을 거치지 않고 바로 삭제합니다. 되돌릴 수 없습니다.'**
  String junkConfirmBody(int count, String size);

  /// No description provided for @junkConfirmReview.
  ///
  /// In ko, this message translates to:
  /// **'확인이 필요한 항목이 포함되어 있습니다: {names}'**
  String junkConfirmReview(String names);

  /// No description provided for @junkConfirmAction.
  ///
  /// In ko, this message translates to:
  /// **'영구 삭제'**
  String get junkConfirmAction;

  /// No description provided for @junkFreed.
  ///
  /// In ko, this message translates to:
  /// **'{size}를 확보했습니다'**
  String junkFreed(String size);

  /// No description provided for @junkFailed.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 항목을 지우지 못했습니다: {reason}'**
  String junkFailed(int count, String reason);

  /// No description provided for @junkUnreadable.
  ///
  /// In ko, this message translates to:
  /// **'읽을 수 없는 폴더가 있습니다: {paths}'**
  String junkUnreadable(String paths);

  /// No description provided for @junkRestricted.
  ///
  /// In ko, this message translates to:
  /// **'일부 폴더는 권한 때문에 크기를 다 재지 못했습니다. 시스템 설정의 개인정보 보호 및 보안에서 전체 디스크 접근 권한을 허용하면 더 정확합니다.'**
  String get junkRestricted;

  /// No description provided for @junkScanFailed.
  ///
  /// In ko, this message translates to:
  /// **'스캔하지 못했습니다: {error}'**
  String junkScanFailed(String error);

  /// No description provided for @junkUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 운영체제에서는 정크 정리를 지원하지 않습니다.'**
  String get junkUnsupported;

  /// No description provided for @junkSelectGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹 전체 선택'**
  String get junkSelectGroup;

  /// No description provided for @navOverview.
  ///
  /// In ko, this message translates to:
  /// **'개요'**
  String get navOverview;

  /// No description provided for @overviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'디스크'**
  String get overviewTitle;

  /// No description provided for @overviewRefresh.
  ///
  /// In ko, this message translates to:
  /// **'새로 고침'**
  String get overviewRefresh;

  /// No description provided for @overviewUsedPercent.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get overviewUsedPercent;

  /// No description provided for @overviewFree.
  ///
  /// In ko, this message translates to:
  /// **'여유'**
  String get overviewFree;

  /// No description provided for @overviewUsed.
  ///
  /// In ko, this message translates to:
  /// **'사용'**
  String get overviewUsed;

  /// No description provided for @overviewTotal.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get overviewTotal;

  /// No description provided for @overviewJunkFound.
  ///
  /// In ko, this message translates to:
  /// **'찾은 정크'**
  String get overviewJunkFound;

  /// No description provided for @overviewJunkNotScanned.
  ///
  /// In ko, this message translates to:
  /// **'아직 스캔 전'**
  String get overviewJunkNotScanned;

  /// No description provided for @overviewJunkScanning.
  ///
  /// In ko, this message translates to:
  /// **'스캔하는 중…'**
  String get overviewJunkScanning;

  /// No description provided for @overviewFreeable.
  ///
  /// In ko, this message translates to:
  /// **'지금 선택한 항목을 정리하면 약 {size}를 확보합니다'**
  String overviewFreeable(String size);

  /// No description provided for @overviewCardJunkTitle.
  ///
  /// In ko, this message translates to:
  /// **'정크 정리'**
  String get overviewCardJunkTitle;

  /// No description provided for @overviewCardJunkSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'캐시, 임시 파일, 개발 찌꺼기'**
  String get overviewCardJunkSubtitle;

  /// No description provided for @overviewCardTidyTitle.
  ///
  /// In ko, this message translates to:
  /// **'자동 정리'**
  String get overviewCardTidyTitle;

  /// No description provided for @overviewCardTidySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'규칙 {count}개가 폴더를 감시합니다'**
  String overviewCardTidySubtitle(int count);

  /// No description provided for @overviewUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'디스크 용량을 읽지 못했습니다.'**
  String get overviewUnavailable;

  /// No description provided for @fdaBannerText.
  ///
  /// In ko, this message translates to:
  /// **'전체 디스크 접근 권한이 꺼져 있어 일부 캐시(Safari, 메일 등)는 보이지 않습니다.'**
  String get fdaBannerText;

  /// No description provided for @fdaShowMe.
  ///
  /// In ko, this message translates to:
  /// **'방법 보기'**
  String get fdaShowMe;

  /// No description provided for @fdaOpenSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get fdaOpenSettings;

  /// No description provided for @fdaGranted.
  ///
  /// In ko, this message translates to:
  /// **'허용됨'**
  String get fdaGranted;

  /// No description provided for @fdaWaiting.
  ///
  /// In ko, this message translates to:
  /// **'권한을 기다리는 중…'**
  String get fdaWaiting;

  /// No description provided for @fdaStep1Title.
  ///
  /// In ko, this message translates to:
  /// **'전체 디스크 접근 설정 열기'**
  String get fdaStep1Title;

  /// No description provided for @fdaStep1Body.
  ///
  /// In ko, this message translates to:
  /// **'macOS는 Safari, 메일, 메시지 같은 일부 폴더를 앱이 따로 허락받기 전에는 보여 주지 않습니다. 아래 단추를 누르면 시스템 설정 › 개인정보 보호 및 보안 › 전체 디스크 접근으로 바로 이동합니다.'**
  String get fdaStep1Body;

  /// No description provided for @fdaStep2Title.
  ///
  /// In ko, this message translates to:
  /// **'\"+\"를 누르고 잠금 풀기'**
  String get fdaStep2Title;

  /// No description provided for @fdaStep2Body.
  ///
  /// In ko, this message translates to:
  /// **'목록 아래의 \"+\" 단추를 누르세요. 이 설정을 바꾸려면 Touch ID나 암호를 묻습니다.'**
  String get fdaStep2Body;

  /// No description provided for @fdaStep3Title.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 고르기'**
  String fdaStep3Title(String appName);

  /// No description provided for @fdaStep3Body.
  ///
  /// In ko, this message translates to:
  /// **'파일 선택 창에서 \"{appName}\"을 검색하거나 응용 프로그램 폴더에서 찾아 열기를 누르세요. Finder 창에서 목록으로 끌어다 놓아도 됩니다.'**
  String fdaStep3Body(String appName);

  /// No description provided for @fdaStep4Title.
  ///
  /// In ko, this message translates to:
  /// **'종료 후 다시 열기'**
  String get fdaStep4Title;

  /// No description provided for @fdaStep4Body.
  ///
  /// In ko, this message translates to:
  /// **'{appName}은 다시 시작해야 권한이 적용된다고 macOS가 안내합니다. \"종료 후 다시 열기\"를 누르면 곧바로 다시 열리고 경고 배너가 사라집니다.'**
  String fdaStep4Body(String appName);

  /// No description provided for @fdaStep5Title.
  ///
  /// In ko, this message translates to:
  /// **'모두 끝났습니다'**
  String get fdaStep5Title;

  /// No description provided for @fdaStep5Body.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 {appName} 스위치가 켜져 있습니다. 다시 스캔하면 전에는 숨겨져 있던 캐시도 포함됩니다.'**
  String fdaStep5Body(String appName);

  /// No description provided for @fdaShowInFinder.
  ///
  /// In ko, this message translates to:
  /// **'Finder에서 {appName} 보기'**
  String fdaShowInFinder(String appName);

  /// No description provided for @fdaBack.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get fdaBack;

  /// No description provided for @fdaNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get fdaNext;

  /// No description provided for @fdaDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get fdaDone;

  /// No description provided for @fdaClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get fdaClose;

  /// No description provided for @navApps.
  ///
  /// In ko, this message translates to:
  /// **'앱 제거'**
  String get navApps;

  /// No description provided for @appsTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱'**
  String get appsTitle;

  /// No description provided for @appsSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'앱 검색'**
  String get appsSearchHint;

  /// No description provided for @appsRefresh.
  ///
  /// In ko, this message translates to:
  /// **'다시 읽기'**
  String get appsRefresh;

  /// No description provided for @appsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'설치된 앱을 찾지 못했습니다.'**
  String get appsEmpty;

  /// No description provided for @appsSelectHint.
  ///
  /// In ko, this message translates to:
  /// **'앱을 고르면 남은 파일을 보여 줍니다'**
  String get appsSelectHint;

  /// No description provided for @appsNoBundleId.
  ///
  /// In ko, this message translates to:
  /// **'번들 id 없음'**
  String get appsNoBundleId;

  /// No description provided for @appsVersion.
  ///
  /// In ko, this message translates to:
  /// **'v{version}'**
  String appsVersion(String version);

  /// No description provided for @appsFinding.
  ///
  /// In ko, this message translates to:
  /// **'남은 파일을 찾는 중…'**
  String get appsFinding;

  /// No description provided for @appsLeftoversTitle.
  ///
  /// In ko, this message translates to:
  /// **'~/Library의 남은 파일 · {count}'**
  String appsLeftoversTitle(int count);

  /// No description provided for @appsLeftoversNone.
  ///
  /// In ko, this message translates to:
  /// **'남은 파일이 없습니다.'**
  String get appsLeftoversNone;

  /// No description provided for @appsLeftoversNameHint.
  ///
  /// In ko, this message translates to:
  /// **'이름이 비슷해서 찾은 항목은 다른 앱의 파일일 수 있어 기본으로 선택하지 않았습니다. 직접 확인하세요.'**
  String get appsLeftoversNameHint;

  /// No description provided for @appsMatchName.
  ///
  /// In ko, this message translates to:
  /// **'이름 일치'**
  String get appsMatchName;

  /// No description provided for @appsToRemove.
  ///
  /// In ko, this message translates to:
  /// **'{size} 제거 예정'**
  String appsToRemove(String size);

  /// No description provided for @appsUninstall.
  ///
  /// In ko, this message translates to:
  /// **'제거'**
  String get appsUninstall;

  /// No description provided for @appsUninstalling.
  ///
  /// In ko, this message translates to:
  /// **'제거하는 중…'**
  String get appsUninstalling;

  /// No description provided for @appsConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}을(를) 제거할까요?'**
  String appsConfirmTitle(String name);

  /// No description provided for @appsConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 항목({size})을 휴지통으로 옮깁니다. 휴지통에서 되돌릴 수 있습니다.'**
  String appsConfirmBody(int count, String size);

  /// No description provided for @appsConfirmAction.
  ///
  /// In ko, this message translates to:
  /// **'휴지통으로 옮기기'**
  String get appsConfirmAction;

  /// No description provided for @appsMoved.
  ///
  /// In ko, this message translates to:
  /// **'{size}를 휴지통으로 옮겼습니다'**
  String appsMoved(String size);

  /// No description provided for @appsFailed.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 항목을 옮기지 못했습니다: {reason}'**
  String appsFailed(int count, String reason);

  /// No description provided for @appsReveal.
  ///
  /// In ko, this message translates to:
  /// **'Finder에서 보기'**
  String get appsReveal;

  /// No description provided for @historyJunkTitle.
  ///
  /// In ko, this message translates to:
  /// **'정크 {count}개 항목 정리'**
  String historyJunkTitle(int count);

  /// No description provided for @historyJunkWhere.
  ///
  /// In ko, this message translates to:
  /// **'영구 삭제 · {size}'**
  String historyJunkWhere(String size);

  /// No description provided for @historyJunkIrreversible.
  ///
  /// In ko, this message translates to:
  /// **'정크 정리는 휴지통을 거치지 않고 바로 삭제해서 되돌릴 수 없습니다.'**
  String get historyJunkIrreversible;

  /// No description provided for @historyUninstallTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 제거'**
  String historyUninstallTitle(String name);

  /// No description provided for @historyUninstallWhere.
  ///
  /// In ko, this message translates to:
  /// **'휴지통으로 이동 · {count}개 항목 · {size}'**
  String historyUninstallWhere(int count, String size);

  /// No description provided for @historyUninstallUndoHint.
  ///
  /// In ko, this message translates to:
  /// **'앱 제거는 휴지통으로 옮겼습니다. 되돌리려면 휴지통에서 직접 복원하세요.'**
  String get historyUninstallUndoHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
