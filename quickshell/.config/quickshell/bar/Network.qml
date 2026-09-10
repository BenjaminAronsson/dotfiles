// Network status, driven by the default route (so cable wins over a merely
// "connected" Wi-Fi radio). Wi-Fi shows SSID + signal; wired shows "wired".
// Left click opens a Wi-Fi popover (scan list, connect, radio toggle).
import QtQuick
import qs
import Quickshell
import Quickshell.Networking
import Quickshell.Io

Segment {
    id: root
    property var barWindow: null
    property string defIface: ""
    readonly property var devs: Networking.devices.values
    readonly property var dev: devs.find(d => d.name === defIface) ?? null
    readonly property bool isWifi: dev ? dev.type === DeviceType.Wifi : false
    readonly property bool isWired: dev ? dev.type === DeviceType.Wired : false
    readonly property var net: (isWifi && dev.networks) ? (dev.networks.values.find(n => n.connected) ?? null) : null
    readonly property var wifiDev: devs.find(d => d.type === DeviceType.Wifi) ?? null

    text: isWifi ? "\uf1eb " + (net ? net.name + " " + Math.round(net.signalStrength * 100) + "%" : "")
        : isWired ? "wired" : "\uf127 offline"
    color: dev ? Theme.fg : Theme.comment
    underline: pop.visible ? Theme.keyword : "transparent"

    onClicked: pop.visible = !pop.visible
    function show(): void { pop.visible = true; }

    // Sorted Wi-Fi scan: connected first, then strongest signal.
    function scanList() {
        if (!wifiDev || !wifiDev.networks)
            return [];
        const ns = wifiDev.networks.values.slice();
        ns.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0)
            || (b.signalStrength || 0) - (a.signalStrength || 0));
        return ns;
    }

    // Lowest-metric default route = the active interface (ip route sorts by metric).
    Process {
        id: route
        stdout: StdioCollector {
            id: routeOut
            onStreamFinished: root.defIface = routeOut.text.trim()
        }
        Component.onCompleted: exec(["sh", "-c", "ip route show default | awk '/^default/{print $5; exit}'"])
    }
    Timer {
        running: true
        repeat: true
        interval: 3000
        onTriggered: route.exec(["sh", "-c", "ip route show default | awk '/^default/{print $5; exit}'"])
    }

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component {
            Column {
                width: Theme.popoverWidth
                spacing: 6

                // Radio toggle + status
                Item {
                    width: parent.width
                    height: 20
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isWired ? "Wired" : root.isWifi ? "\uf1eb Wi-Fi" : "\uf127 offline"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: root.color
                    }
                    Rectangle {
                        id: wtoggle
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34; height: 18; radius: 9
                        color: Networking.wifiEnabled ? Theme.keyword : Theme.line
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            text: Networking.wifiEnabled ? "on" : "off"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.bg
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.line }

                // Scan list
                Item {
                    width: parent.width
                    height: listCol.implicitHeight
                    Column {
                        id: listCol
                        width: parent.width
                        Repeater {
                            model: pop.visible ? root.scanList() : []
                            delegate: Item {
                                required property var modelData
                                width: listCol.width
                                height: 30
                                Text {
                                    id: si
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (modelData.signalStrength >= 0.7 ? "\uf1eb" : modelData.signalStrength >= 0.4 ? "\uf1eb" : "\uf1eb")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    color: modelData.connected ? Theme.builtin : Theme.comment
                                }
                                Text {
                                    anchors.left: si.right; anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - si.width - 70
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.barFontSize
                                    elide: Text.ElideRight
                                    color: modelData.connected ? Theme.fg : Theme.comment
                                }
                                Text {
                                    anchors.right: parent.right; anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round((modelData.signalStrength || 0) * 100) + "%"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.comment
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: ma.containsMouse ? Theme.inactiveBg : "transparent"
                                    z: -1
                                }
                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (!modelData.connected) modelData.connect(); }
                                }
                            }
                        }
                    }
                }

                PopButton {
                    width: parent.width
                    text: "Network manager (impala)"
                    icon: "\uf1de"
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", Quickshell.env("HOME") + "/.cargo/bin/impala-nm"]);
                        pop.visible = false;
                    }
                }
            }
        }
    }
}
