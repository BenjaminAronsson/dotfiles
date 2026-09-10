// Idle inhibitor. Holds the session awake while active (spawns
// `systemd-inhibit ... sleep infinity`). Click toggles.
import QtQuick
import qs
import Quickshell
import Quickshell.Io

Segment {
    id: root
    text: "\uf0f4"
    color: proc.running ? Theme.warning : Theme.comment
    onClicked: proc.running = !proc.running

    Process {
        id: proc
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell",
            "--why=presentation", "sleep", "infinity"]
    }
}
