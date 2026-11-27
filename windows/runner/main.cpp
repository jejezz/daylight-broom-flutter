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

// Shows the running instance's window (it may be hidden in the tray) and
// brings it to the front.
void ActivateExistingWindow() {
  HWND existing = ::FindWindowW(kWindowClass, kWindowTitle);
  if (!existing) return;
  ::ShowWindow(existing, ::IsIconic(existing) ? SW_RESTORE : SW_SHOW);
  ::SetForegroundWindow(existing);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Single instance: launching again (e.g. from the taskbar while the app sits
  // in the tray) used to start another process with another tray icon. The OS
  // closes the mutex handle when this process exits.
  ::CreateMutexW(nullptr, FALSE, kInstanceMutex);
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    // A login-item launch (--background) exits quietly without showing anything.
    if (std::wcsstr(command_line, L"--background") == nullptr) ActivateExistingWindow();
    return EXIT_SUCCESS;
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
