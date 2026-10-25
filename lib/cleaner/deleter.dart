import 'dart:io';

import 'package:path/path.dart' as p;

/// 휴지통을 거치지 않고 지운다 (정크 정리는 용량을 바로 확보하는 것이 목적이다).
/// 규칙 정리는 이것을 쓰지 않고 항상 휴지통으로 보낸다.
///
/// 안전장치: [allowedRoots] 안의 경로만 지운다. 스캐너가 내놓은 경로만 들어오지만, 잘못된 값이
/// 홈이나 루트를 지우는 일이 없도록 한 번 더 막는다.
class PermanentDeleter {
  PermanentDeleter({required this.allowedRoots, Map<String, String>? env}) : _env = env ?? Platform.environment;

  final List<String> allowedRoots;
  final Map<String, String> _env;

  /// 실패한 경로와 이유. 비어 있으면 모두 지워진 것이다.
  Future<Map<String, String>> delete(List<String> paths) async {
    final failed = <String, String>{};
    for (final path in paths) {
      final reason = await _deleteOne(path);
      if (reason != null) failed[path] = reason;
    }
    return failed;
  }

  bool _allowed(String path) {
    final home = _env['HOME'] ?? _env['USERPROFILE'] ?? '';
    final normalized = p.normalize(path);
    if (normalized.isEmpty || normalized == '/' || p.rootPrefix(normalized) == normalized) return false;
    if (home.isNotEmpty && normalized == p.normalize(home)) return false;
    return allowedRoots.any((r) => r.isNotEmpty && (p.equals(normalized, r) || p.isWithin(r, normalized)));
  }

  Future<String?> _deleteOne(String path) async {
    if (!_allowed(path)) return 'outside the scanned folders';
    try {
      final type = await FileSystemEntity.type(path, followLinks: false);
      switch (type) {
        case FileSystemEntityType.notFound:
          return null;
        case FileSystemEntityType.directory:
          // 휴지통 폴더 자체는 지우지 않고 비운다.
          if (p.basename(path) == '.Trash') return await _emptyDirectory(path);
          await Directory(path).delete(recursive: true);
        case FileSystemEntityType.link:
          await Link(path).delete();
        default:
          await File(path).delete();
      }
      return null;
    } on FileSystemException catch (e) {
      return e.osError?.message.isNotEmpty == true ? e.osError!.message : e.message;
    }
  }

  Future<String?> _emptyDirectory(String path) async {
    String? firstError;
    for (final child in Directory(path).listSync(followLinks: false)) {
      try {
        await child.delete(recursive: true);
      } on FileSystemException catch (e) {
        firstError ??= e.osError?.message ?? e.message;
      }
    }
    return firstError;
  }
}
