import 'dart:io';

import '../engine/file_ops.dart';
import '../system/login_item.dart' show ProcessRunner;

/// 앱과 남은 파일을 휴지통으로 보낸다 (되돌릴 수 있다 — 정크 정리와 달리 영구 삭제가 아니다).
abstract class AppTrasher {
  /// 실패한 경로와 이유. 비어 있으면 모두 휴지통으로 갔다.
  Future<Map<String, String>> trash(List<String> paths);
}

class SystemAppTrasher implements AppTrasher {
  SystemAppTrasher({FileOps? ops, ProcessRunner? run, bool Function(String path)? exists})
      : _ops = ops ?? SystemFileOps(),
        _run = run ?? Process.run,
        _exists = exists ?? ((p) => FileSystemEntity.typeSync(p, followLinks: false) != FileSystemEntityType.notFound);

  final FileOps _ops;
  final ProcessRunner _run;
  final bool Function(String path) _exists;

  @override
  Future<Map<String, String>> trash(List<String> paths) async {
    final failed = <String, String>{};
    for (final path in paths) {
      try {
        await _ops.trash(path);
      } on Object catch (e) {
        // root 소유 항목(App Store·pkg 로 설치한 앱)은 우리가 휴지통에 못 넣는다.
        // Finder 는 관리자 인증을 물은 뒤 넣을 수 있다.
        if (!await _trashViaFinder(path)) failed[path] = '$e';
      }
    }
    return failed;
  }

  Future<bool> _trashViaFinder(String path) async {
    try {
      // 경로는 인자로 넘겨 스크립트에 끼워 넣지 않는다 (따옴표·이스케이프 문제 방지).
      final r = await _run('osascript', [
        '-e', 'on run argv',
        '-e', 'tell application "Finder" to delete (POSIX file (item 1 of argv))',
        '-e', 'end run',
        path,
      ]);
      // 종료 코드가 아니라 파일 시스템을 믿는다: 인증을 취소해도 성공으로 세면 안 된다.
      return r.exitCode == 0 && !_exists(path);
    } on ProcessException {
      return false;
    }
  }
}
