//@ pragma UseQApplication
// quickshell entry point — bar + launcher (notifications land later).
// UseQApplication is required for Qt platform menus (system-tray context menus).
import Quickshell
import Quickshell.Io
import "bar"
import "launcher"
import "notifications"

ShellRoot {
    // One status bar per monitor.
    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }

    Launcher { id: launcher }

    Notifications {}

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle(); }
        function open(): void { launcher.open(); }
        function close(): void { launcher.close(); }
        // power/session menu (SUPER+Esc)
        function power(): void { launcher.openMode("power"); }
        // test hooks
        function debugType(text: string): void { launcher.debugType(text); }
        function debugKey(key: string): void { launcher.debugKey(key); }
        function debugFirstRow(): string { return launcher.debugFirstRow(); }
    }
}





