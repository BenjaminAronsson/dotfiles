// Screen backlight via brightnessctl. Hidden when no backlight device exists
// (most desktops). Click opens a brightness popover; scroll adjusts +/-5%.
import QtQuick
import qs
import Quickshell
import Quickshell.Io

Segment {
    id: root
    property var barWindow: null
    property int percent: -1
    property bool hasDevice: false
    visible: hasDevice
    text: "\uf185 " + (percent >= 0 ? percent + "%" : "")
    underline: pop.visible ? Theme.builtin : "transparent"

    function setBright(p) {
        p = Math.max(1, Math.min(100, Math.round(p)));
        root.percent = p;
        Quickshell.execDetached(["brightnessctl", "set", p + "%"]);
        debounce.restart();
    }

    onClicked: pop.visible = !pop.visible
    function show(): void { pop.visible = true; }
    onScrolled: delta => {
        if (!hasDevice)
            return;
        setBright(root.percent + (delta > 0 ? 5 : -5));
    }

    Process {
        id: detect
        stdout: StdioCollector {
            id: detectOut
            onStreamFinished: {
                root.hasDevice = detectOut.text.trim() !== "";
                if (root.hasDevice)
                    poll.exec(["brightnessctl", "get"]);
            }
        }
        Component.onCompleted: exec(["ls", "/sys/class/backlight"])
    }

    Process {
        id: poll
        stdout: StdioCollector {
            id: pollOut
            onStreamFinished: {
                const v = parseInt(pollOut.text);
                if (!isNaN(v))
                    root.percent = v;
            }
        }
    }

    Timer {
        id: debounce
        interval: 250
        onTriggered: poll.exec(["brightnessctl", "get"])
    }
    Timer {
        running: root.visible
        repeat: true
        interval: 2000
        onTriggered: poll.exec(["brightnessctl", "get"])
    }

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component {
            Column {
                width: Theme.popoverWidth
                spacing: Theme.popoverSpacing
                Text {
                    text: "\uf185  " + (root.percent >= 0 ? root.percent : 0) + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.warning
                }
                Slider {
                    width: parent.width
                    from: 0
                    to: 100
                    value: root.percent >= 0 ? root.percent : 0
                    accent: Theme.warning
                    onMoved: v => root.setBright(v)
                }
            }
        }
    }
}
