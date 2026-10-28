/// 삭제 단추를 보여 주지 않는 곳: 디스크 루트, 루트 바로 아래의 시스템 폴더, 사용자 홈 폴더 자체.
/// 안에 들어가서 고르는 것은 막지 않는다 — 폴더 통째로 보내는 실수를 막으려는 것이다.
bool isProtectedPath(String path, {required String root, required String separator, required bool windows}) {
  final p = windows ? path.toLowerCase().replaceAll('/', r'\') : path;
  final r = windows ? root.toLowerCase().replaceAll('/', r'\') : root;
  final base = r.endsWith(separator) ? r : '$r$separator';
  if (p == r || p == base || !p.startsWith(base)) return true;
  final rel = p.substring(base.length).split(separator).where((s) => s.isNotEmpty).toList();
  if (rel.isEmpty) return true;
  if (windows) {
    const top = {
      'windows', 'program files', 'program files (x86)', 'programdata', 'users', r'$recycle.bin',
      'system volume information', 'recovery', 'boot', 'efi',
    };
    if (rel.length == 1) return top.contains(rel.first);
    // C:\Users\<이름> 과 Default 같은 사용자 폴더 자체.
    return rel.length == 2 && rel.first == 'users';
  }
  const top = {
    'system', 'library', 'usr', 'bin', 'sbin', 'private', 'applications', 'users', 'cores', 'opt', 'etc', 'var', 'volumes',
  };
  if (rel.length == 1) return top.contains(rel.first.toLowerCase());
  return rel.length == 2 && rel.first.toLowerCase() == 'users';
}
