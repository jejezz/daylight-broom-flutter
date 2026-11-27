#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cwchar>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr wchar_t kWindowTitle[] = L"Daylight Broom";
constexpr wchar_t kWindowClass[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

// Named mutex that keeps a single running instance. Debug builds use their own
// name so `flutter run` still starts while the installed app is open.
#ifdef _DEBUG
constexpr wchar_t kInstanceMutex[] = L"Local\\art.zoomon.daylightbroom.instance.debug";
#else
constexpr wchar_t kInstanceMutex[] = L"Local\\art.zoomon.daylightbroom.instance";
#endif

// How long a new launch waits for an instance that is shutting down.
constexpr DWORD kShutdownWaitMs = 5000;
// After handing off to a running window, how long to check that the instance
// is not in the middle of quitting (quitting takes ~150 ms).
constexpr DWORD kHandOffCheckMs = 500;

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Single instance: launching again (e.g. from the taskbar while the app sits
  // in the tray) used to start another process with another tray icon.
  // The running instance owns the mutex; the OS releases it (as abandoned)
  // when that process exits.
  HANDLE instance_mutex = ::CreateMutexW(nullptr, TRUE, kInstanceMutex);
  if (instance_mutex && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing = ::FindWindowW(kWindowClass, kWindowTitle);
    DWORD wait_ms = kShutdownWaitMs;
    if (existing) {
      // Bring the running instance forward (its window may be hidden in the
      // tray). A login-item launch (--background) exits quietly instead.
      if (std::wcsstr(command_line, L"--background") == nullptr) {
        ::ShowWindow(existing, ::IsIconic(existing) ? SW_RESTORE : SW_SHOW);
        ::SetForegroundWindow(existing);
      }
      // If that instance was quitting, take over once it is gone; otherwise
      // it is running normally and this launch is done.
      wait_ms = kHandOffCheckMs;
    }
    // Without a window the other instance is shutting down: wait for it to
    // finish, then start normally instead of silently doing nothing.
    const DWORD wait = ::WaitForSingleObject(instance_mutex, wait_ms);
    if (wait != WAIT_OBJECT_0 && wait != WAIT_ABANDONED) return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  // Impeller is off by default; the app renders with the Skia backend.
  project.set_impeller_switch(flutter::ImpellerSwitch::Disabled);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
