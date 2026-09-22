// Volume via wpctl (matches waybar's backend; quickshell's PipeWire node
// volume reads unreliable). Click opens a volume popover; scroll adjusts +/-5%,
// right toggles mute.
import QtQuick
import qs
import Quickshell
import Quickshell.Io

Segment {
    id: root
    property var barWindow: null
    property real vol: 0      // 0..1+
    property bool muted: false
    property bool haveSink: false

    text: muted ? "\uf026 muted"
        : (vol < 0.34 ? "\uf027" : "\uf028") + " " + Math.round(vol * 100) + "%"
    underline: pop.visible ? Theme.builtin : "transparent"

    function setVol(v) {
        v = Math.max(0, Math.min(1.5, v));
        root.vol = v;
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.5",
            "@DEFAULT_AUDIO_SINK@", Math.round(v * 100) + "%"]);
        debounce.restart();
    }

    onClicked: pop.visible = !pop.visible
    function show(): void { pop.visible = true; }
    onRightClicked: {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        debounce.restart();
    }
    onScrolled: delta => setVol(root.vol + (delta > 0 ? 0.05 : -0.05))

    Process {
        id: wp
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                const line = out.text;
                root.muted = line.includes("MUTED");
                const m = line.match(/Volume:\s*([0-9.]+)/);
                if (m) {
                    root.vol = parseFloat(m[1]);
                    root.haveSink = true;
                }
            }
        }
        Component.onCompleted: exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    }

    Timer {
        id: debounce
        interval: 250
        onTriggered: wp.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    }
    Timer {
        running: true
        repeat: true
        interval: 2000
        onTriggered: wp.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    }

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component {
            Column {
                width: Theme.popoverWidth
                spacing: Theme.popoverSpacing

                Row {
                    width: parent.width
                    spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.muted ? "\uf026" : (root.vol < 0.34 ? "\uf027" : "\uf028")
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        color: root.muted ? Theme.error : Theme.builtin
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                                debounce.restart();
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(root.vol * 100) + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                        color: Theme.fg
                    }
                }

                Slider {
                    width: parent.width
                    from: 0
                    to: 1
                    value: Math.min(1, root.vol)
                    onMoved: v => root.setVol(v)
                }

                PopButton {
                    width: parent.width
                    text: "Open mixer (wiremix)"
                    icon: "\uf1de"
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", Quickshell.env("HOME") + "/.cargo/bin/wiremix"]);
                        pop.visible = false;
                    }
                }
            }
        }
    }
}
