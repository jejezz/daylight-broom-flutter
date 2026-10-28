/// 디스크 사용량을 나누는 종류. 이미지 등 나머지는 모두 [other].
enum FileCategory { applications, documents, music, video, other }

const _documentExts = {
  'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'pdf', 'txt', 'md', 'rtf', 'odt', 'ods', 'odp', 'csv',
  'hwp', 'hwpx', 'pages', 'numbers', 'key', 'epub',
};
const _musicExts = {'mp3', 'flac', 'wav', 'aac', 'm4a', 'ogg', 'oga', 'wma', 'aiff', 'aif', 'opus', 'alac'};
const _videoExts = {'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', 'mpg', 'mpeg', 'm2ts', 'mts'};

/// 확장자로 나눈다. 어플리케이션은 확장자가 아니라 위치로 정한다 ([isApplicationRoot]).
FileCategory categoryOfFile(String path) {
  final slash = path.lastIndexOf(RegExp(r'[\\/]'));
  final dot = path.lastIndexOf('.');
  if (dot <= slash + 1) return FileCategory.other; // 확장자가 없거나 ".gitignore" 같은 숨김 파일
  final ext = path.substring(dot + 1).toLowerCase();
  if (_documentExts.contains(ext)) return FileCategory.documents;
  if (_musicExts.contains(ext)) return FileCategory.music;
  if (_videoExts.contains(ext)) return FileCategory.video;
  return FileCategory.other;
}

/// 이 폴더 아래는 통째로 어플리케이션이다.
/// Windows: `X:\Program Files`, `X:\Program Files (x86)`, `X:\Users\<이름>\AppData\Local\Programs`.
/// macOS: `*.app` 번들, `/Applications`, `/Users/<이름>/Applications`.
bool isApplicationRoot(String path, {required bool windows}) {
  final p = path.toLowerCase();
  if (windows) {
    final q = p.replaceAll('/', r'\');
    if (q.length < 4 || q[1] != ':' || q[2] != r'\') return false;
    final rest = q.substring(3);
    if (rest == 'program files' || rest == r'program files (x86)') return true;
    if (rest.startsWith(r'users\') && rest.endsWith(r'\appdata\local\programs')) {
      final seg = rest.split(r'\');
      return seg.length == 5 && seg[2] == 'appdata' && seg[3] == 'local';
    }
    return false;
  }
  if (p.endsWith('.app') || p == '/applications') return true;
  return p.startsWith('/users/') && p.endsWith('/applications') && '/'.allMatches(p).length == 3;
}
