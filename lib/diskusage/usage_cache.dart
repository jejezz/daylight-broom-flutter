import 'dart:io';

import '../rules/rule_store.dart';
import '../storage/json_file.dart';
import 'usage_model.dart';

/// 디스크 분석 결과를 설정 폴더에 디스크마다 파일 하나로 저장한다. 다시 열었을 때 몇 분짜리 분석을 반복하지 않으려는 것.
class UsageCache {
  UsageCache(this.directory);

  factory UsageCache.standard() => UsageCache(Directory(RuleStore.appSupportPath()));

  final Directory directory;

  /// `C:\` -> `usage_C.json`, `/` -> `usage_root.json`, `/Volumes/Data` -> `usage_Volumes_Data.json`.
  static String fileNameFor(String root) {
    final slug = root.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    return 'usage_${slug.isEmpty ? 'root' : slug}.json';
  }

  JsonFile _file(String root) => JsonFile(directory, fileNameFor(root));

  /// 없거나 깨졌거나 옛 형식이면 null.
  Future<DiskUsage?> load(String root) async {
    final file = _file(root);
    try {
      final json = await file.read();
      if (json == null) return null;
      final usage = DiskUsage.fromJson(json);
      return usage.root == root ? usage : null;
    } on FormatException {
      await file.quarantine();
      return null;
    } on Object {
      return null;
    }
  }

  Future<void> save(DiskUsage usage) => _file(usage.root).write(usage.toJson());
}
