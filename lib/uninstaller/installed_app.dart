import 'package:path/path.dart' as p;

/// 설치된 앱 하나 (macOS: `.app` 번들).
class InstalledApp {
  const InstalledApp({required this.path, required this.bytes, this.bundleId, this.displayName, this.version});

  final String path;
  final int bytes;
  final String? bundleId;
  final String? displayName;
  final String? version;

  String get name => displayName ?? p.basenameWithoutExtension(path);
}

/// 남은 파일을 얼마나 믿을 수 있는지.
enum LeftoverMatch {
  /// 번들 id 가 경로에 들어 있다 (`com.spotify.client`). 거의 확실하다.
  bundleId,

  /// 앱 이름이 비슷해서 찾았다. 다른 앱의 데이터일 수 있어 직접 확인해야 한다.
  name,
}

class Leftover {
  const Leftover({required this.path, required this.bytes, required this.match});

  final String path;
  final int bytes;
  final LeftoverMatch match;
}
