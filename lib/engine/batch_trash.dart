import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'file_ops.dart';

/// 파일 하나를 휴지통으로 보낸 결과. [error]가 null 이면 성공.
class TrashResult {
  const TrashResult(this.path, [this.error, this.location]);

  final String path;
  final String? error;

  /// 휴지통 안의 위치를 알면 (macOS, 되돌리기용). Windows 는 null.
  final String? location;

  bool get ok => error == null;
}

/// 여러 파일을 휴지통으로 보내며, 하나 끝날 때마다 결과를 흘려보낸다 (진행 표시용).
/// 구독을 취소하면 남은 파일은 보내지 않는다.
abstract class BatchTrasher {
  Stream<TrashResult> trashAll(List<String> paths);
}

/// [FileOps.trash]를 하나씩 부른다. macOS(채널 호출이 빠르다)와 테스트용.
class FileOpsBatchTrasher implements BatchTrasher {
  FileOpsBatchTrasher(this.ops);

  final FileOps ops;

  @override
  Stream<TrashResult> trashAll(List<String> paths) async* {
    for (final path in paths) {
      try {
        final location = await ops.trash(path);
        yield TrashResult(path, null, location);
      } on Object catch (e) {
        yield TrashResult(path, '$e');
      }
    }
  }
}

/// Windows 는 파일마다 PowerShell 을 띄우면 파일당 몇 초씩 걸린다. 한 번만 띄워 목록을 차례로 보내고,
/// 한 줄씩 결과를 받는다. 다른 OS 는 [FileOpsBatchTrasher]로 넘긴다.
class SystemBatchTrasher implements BatchTrasher {
  SystemBatchTrasher({FileOps? ops, bool? isWindows})
      : _fallback = FileOpsBatchTrasher(ops ?? SystemFileOps()),
        _windows = isWindows ?? Platform.isWindows;

  final FileOpsBatchTrasher _fallback;
  final bool _windows;

  /// 휴지통 용량을 넘기기 쉬운 폴더와 큰 파일은 확인 창이 뜨게 둔다 ([SystemFileOps.trash]와 같은 기준).
  /// 목록은 파일로 넘겨 경로의 따옴표·길이 문제를 피한다. 결과는 `OK<TAB>경로` / `ERR<TAB>경로<TAB>이유`.
  static const _script = r'''
Add-Type -AssemblyName Microsoft.VisualBasic
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
foreach ($p in (Get-Content -LiteralPath $env:DAYLIGHTBROOM_TRASH_LIST -Encoding UTF8)) {
  if ($p -eq '') { continue }
  $existed = Test-Path -LiteralPath $p
  try {
    if (Test-Path -LiteralPath $p -PathType Container) {
      [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($p, 'AllDialogs', 'SendToRecycleBin')
    } else {
      $big = (Get-Item -LiteralPath $p -Force).Length -ge 500000000
      $ui = if ($big) { 'AllDialogs' } else { 'OnlyErrorDialogs' }
      [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($p, $ui, 'SendToRecycleBin')
    }
    [Console]::Out.WriteLine("OK`t$p")
  } catch {
    if ($existed -and -not (Test-Path -LiteralPath $p)) {
      # 휴지통 호출이 가끔 옮기고도 "찾을 수 없음"을 던진다 (파일은 이미 없다): 옮긴 것으로 본다.
      [Console]::Out.WriteLine("OK`t$p")
    } else {
      $m = $_.Exception.Message -replace "[`r`n`t]", ' '
      [Console]::Out.WriteLine("ERR`t$p`t$m")
    }
  }
  [Console]::Out.Flush()
}
''';

  @override
  Stream<TrashResult> trashAll(List<String> paths) {
    if (!_windows || paths.isEmpty) return _fallback.trashAll(paths);
    late StreamController<TrashResult> out;
    Process? process;
    File? list;
    final reported = <String>{};

    Future<void> cleanup() async {
      process?.kill();
      try {
        await list?.delete();
      } on Object {
        // 임시 목록 파일은 못 지워도 그만이다.
      }
    }

    Future<void> run() async {
      try {
        final dir = await Directory.systemTemp.createTemp('daylight_broom_trash_');
        list = File('${dir.path}${Platform.pathSeparator}list.txt');
        await list!.writeAsString(paths.join('\r\n'), encoding: utf8);
        process = await Process.start(
          'powershell',
          ['-NoProfile', '-NonInteractive', '-Command', _script],
          environment: {'DAYLIGHTBROOM_TRASH_LIST': list!.path},
        );
        final errors = StringBuffer();
        final stderrDone = process!.stderr.transform(utf8.decoder).forEach(errors.write);
        await for (final line in process!.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
          if (out.isClosed) break;
          final parts = line.split('\t');
          if (parts.length < 2) continue;
          final path = parts[1];
          reported.add(path);
          out.add(parts[0] == 'OK' ? TrashResult(path) : TrashResult(path, parts.length > 2 ? parts[2] : 'error'));
        }
        await process!.exitCode;
        await stderrDone;
        // 결과 줄이 없었던 파일 (PowerShell 이 시작하지 못했거나 중간에 죽었다) 은 실패로 알린다.
        if (!out.isClosed) {
          final reason = errors.isEmpty ? 'PowerShell did not report a result' : errors.toString().trim();
          for (final p in paths) {
            if (!reported.contains(p)) out.add(TrashResult(p, reason));
          }
        }
      } on Object catch (e) {
        if (!out.isClosed) {
          for (final p in paths) {
            if (!reported.contains(p)) out.add(TrashResult(p, '$e'));
          }
        }
      } finally {
        await cleanup();
        if (!out.isClosed) await out.close();
      }
    }

    out = StreamController<TrashResult>(
      onListen: run,
      // 정지: 프로세스를 끝내 남은 파일은 보내지 않는다.
      onCancel: () async {
        await cleanup();
      },
    );
    return out.stream;
  }
}
