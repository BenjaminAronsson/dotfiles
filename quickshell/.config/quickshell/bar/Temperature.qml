// CPU temperature (hottest thermal zone). Click opens btop.
import QtQuick
import qs
import Quickshell
import Quickshell.Io

Segment {
    id: root
    property int temp: -1
    visible: temp >= 0
    text: "\uf2c9 " + (temp >= 0 ? temp + "°" : "")
    color: temp >= 85 ? Theme.error : Theme.fg
    onClicked: Quickshell.execDetached(["kitty", "-e", "btop"])

    Process {
        id: poll
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                const v = parseInt(out.text);
                if (!isNaN(v))
                    root.temp = Math.round(v / 1000);
            }
        }
        Component.onCompleted: exec(["sh", "-c",
            "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1"])
    }

    Timer {
        running: true
        repeat: true
        interval: 3000
        onTriggered: poll.exec(["sh", "-c",
            "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1"])
    }
}
