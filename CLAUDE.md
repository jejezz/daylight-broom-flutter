릴리스·버전·패키징·정보 창·아이콘·라이선스·UI/UX·글꼴·언어·테마는
https://github.com/jejezz/application-release-templates/tree/main/conventions
규약을 따른다. 이 앱에 적용된 규약 버전: conventions-v1

# Daylight Broom

캐시·임시 파일·개발 도구 찌꺼기를 치우고(정크 정리), 앱을 남은 파일까지 제거하고(앱 제거, 현재 macOS만),
다운로드 폴더 등을 규칙(확장자·이름·크기·경과 일수)에 따라 자동 분류·정리하는(자동 정리)
상주형(트레이/메뉴바) 유틸리티. 개요 화면에서 디스크 사용량을 보여 준다. 대상 플랫폼: macOS, Windows (Linux 없음).
Stevedore(규칙 정리)와 MacBroom(정크·앱 제거·디스크 링·UI)을 합친 앱이다. 화면은 규약 테마(Saturn) 위에
`BroomStyle`(`lib/theme/broom_style.dart`, 글래스·그라디언트·글로우)을 얹은 것이고, 위젯은 `lib/ui/broom/`에 있다.

- 표시 이름 `Daylight Broom`, 패키지 `daylight_broom`, 식별자 `art.zoomon.daylightbroom`
- 규칙 정리의 삭제는 항상 휴지통으로 보낸다. 규칙 저장 전 dry-run 미리보기와 이동 이력(되돌리기)을 제공한다.
- 정크 정리(캐시·임시 파일·개발 도구 찌꺼기, `lib/cleaner/`)는 용량을 바로 확보하려고 **영구 삭제**한다. 이 경로만 예외이며, 항상 확인 창을 거치고 스캔 루트 밖의 경로는 `PermanentDeleter`가 거부한다. 스캔 대상은 `lib/cleaner/scan_target.dart`의 목록이 전부다(OS별 경로, 항목 추가 시 `target_labels.dart`와 arb도 함께).
- 앱 제거(`lib/uninstaller/`, 현재 macOS만)는 앱과 남은 파일을 **휴지통**으로 보낸다(영구 삭제 아님). 번들 id로 찾은 남은 파일만 미리 선택하고 이름으로 찾은 것은 사용자가 고른다. 자기 자신(`AppIdentity.bundleId`)은 목록에서 뺀다.
- 다운로드 중인 임시 파일(`.crdownload`, `.download`, `.part`)은 건드리지 않고, 크기가 안정된 뒤 처리한다.
- 아이콘 글리프는 Icons8 broom (`assets/icon/source_glyph.svg`), 고양이 판 색은 `assets/icon/cat.json`(hue 124). 고양이 원본은 유료 자산이라 저장소에 없어, cat 모드로 `python3 tool/icon/generate_icons.py <cat.png>`를 다시 돌리려면 원본 경로가 필요하다(지금 macOS 아이콘은 MacBroom에서 만든 것을 가져왔다). 트레이 아이콘(`assets/tray/`)도 함께 갱신.
- 옛 이름 Stevedore에서 넘어온 사용자를 위해 첫 실행 때 `LegacyMigration`(`lib/system/legacy_migration.dart`)이 옛 설정 폴더·저장 값·로그인 항목을 옮긴다. 옛 식별자 `art.zoomon.stevedore`는 이 코드 밖에서 쓰지 않는다.
- 로그인 시 자동 실행: macOS는 `~/Library/LaunchAgents/art.zoomon.daylightbroom.plist`, Windows는 HKCU `Run` 키에 `--background` 인자로 등록한다. 이 인자로 시작하면 창 없이 트레이에서만 뜬다 (macOS는 `MainFlutterWindow.swift`가 실행 인자를 Dart로 전달하고 창을 숨긴 채 시작).
