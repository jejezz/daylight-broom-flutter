import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // macOS는 실행 인자를 Dart로 넘겨주지 않는다. --background 같은 인자를 쓰려면 직접 전달한다.
    let project = FlutterDartProject()
    project.dartEntrypointArguments = Array(CommandLine.arguments.dropFirst())
    let flutterViewController = FlutterViewController(project: project)
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 휴지통 보내기: Finder의 "되돌려 놓기"가 되도록 FileManager.trashItem을 쓴다.
    let trashChannel = FlutterMethodChannel(
      name: "art.zoomon.daylightbroom/trash",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    trashChannel.setMethodCallHandler { call, result in
      guard call.method == "trash", let path = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        var trashed: NSURL?
        try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: &trashed)
        result(trashed?.path)
      } catch {
        result(FlutterError(code: "trash_failed", message: error.localizedDescription, details: path))
      }
    }

    // 디스크 용량과 전체 디스크 접근 권한: Dart만으로는 알 수 없는 것들 (lib/cleaner/disk_info.dart).
    let systemChannel = FlutterMethodChannel(
      name: "art.zoomon.daylightbroom/system",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    systemChannel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      // 내장 디스크만: 이동식·네트워크·디스크 이미지는 뺀다. 용량은 Finder와 같은 기준(비울 수 있는 공간을 여유로 센다).
      case "volumes":
        let keys: [URLResourceKey] = [
          .volumeNameKey, .volumeIsLocalKey, .volumeIsInternalKey, .volumeIsRemovableKey,
          .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey,
        ]
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        var list: [[String: Any]] = []
        for url in urls {
          guard let v = try? url.resourceValues(forKeys: Set(keys)),
                v.volumeIsLocal == true, v.volumeIsInternal == true, v.volumeIsRemovable != true else { continue }
          list.append([
            "name": v.volumeName ?? url.lastPathComponent,
            "path": url.path,
            "total": v.volumeTotalCapacity ?? 0,
            "free": v.volumeAvailableCapacityForImportantUsage ?? 0,
          ])
        }
        result(list)
      // TCC에는 공개 API가 없다. TCC가 지키는 파일을 실제로 열어 보는 것이 표준 방법이다
      // (isReadableFile/access(2)는 POSIX 권한만 보고 TCC를 무시한다).
      case "hasFullDiskAccess":
        let home = FileManager.default.homeDirectoryForCurrentUser
        let probes = ["Library/Application Support/com.apple.TCC/TCC.db", "Library/Safari/Bookmarks.plist"]
        result(probes.contains { FileHandle(forReadingAtPath: home.appendingPathComponent($0).path) != nil })
      case "openFullDiskAccessSettings":
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
        result(nil)
      case "revealInFinder":
        if let path = args["path"] as? String {
          NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  // 창은 항상 숨긴 채 시작하고, Dart가 준비된 뒤 보일지 정한다 (--background면 트레이에서만 시작).
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
