// Bluetooth. Hidden when the machine has no adapter (many desktops).
// Left click opens a device popover (connect/disconnect, radio toggle).
import QtQuick
import qs
import Quickshell
import Quickshell.Bluetooth

Segment {
    id: root
    property var barWindow: null
    readonly property var ad: Bluetooth.defaultAdapter
    visible: ad !== null
    readonly property int nConn: ad ? ad.devices.values.filter(d => d.connected).length : 0

    text: "\uf293" + (ad && ad.enabled ? (nConn > 0 ? " " + nConn : "") : " off")
    color: ad && ad.enabled ? Theme.fg : Theme.comment
    underline: pop.visible ? Theme.hint : "transparent"

    onClicked: pop.visible = !pop.visible
    function show(): void { pop.visible = true; }
    onRightClicked: if (ad) ad.enabled = !ad.enabled

    function devList() {
        if (!ad)
            return [];
        const ds = ad.devices.values.slice();
        ds.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0)
            || (b.paired ? 1 : 0) - (a.paired ? 1 : 0));
        return ds;
    }

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component {
            Column {
                width: Theme.popoverWidth
                spacing: 6

                Item {
                    width: parent.width
                    height: 20
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf293  " + (ad && ad.enabled ? "Bluetooth" : "Bluetooth off")
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: ad && ad.enabled ? Theme.hint : Theme.comment
                    }
                    Rectangle {
                        id: btoggle
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34; height: 18; radius: 9
                        color: ad && ad.enabled ? Theme.hint : Theme.line
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            text: ad && ad.enabled ? "on" : "off"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.bg
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (ad) ad.enabled = !ad.enabled
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.line }

                Item {
                    width: parent.width
                    height: btCol.implicitHeight
                    visible: ad && ad.enabled
                    Column {
                        id: btCol
                        width: parent.width
                        Repeater {
                            model: pop.visible && ad && ad.enabled ? root.devList() : []
                            delegate: Item {
                                required property var modelData
                                width: btCol.width
                                height: 30
                                Text {
                                    id: bi
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.connected ? "\uf00c" : modelData.paired ? "\uf294" : "\uf059"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    color: modelData.connected ? Theme.plus : Theme.comment
                                }
                                Text {
                                    anchors.left: bi.right; anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - bi.width - 80
                                    text: modelData.deviceName || modelData.name || modelData.address
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.barFontSize
                                    elide: Text.ElideRight
                                    color: modelData.connected ? Theme.fg : Theme.comment
                                }
                                Text {
                                    anchors.right: parent.right; anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "connected") : ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.comment
                                }
                                Rectangle { anchors.fill: parent; radius: 6; color: ma.containsMouse ? Theme.inactiveBg : "transparent"; z: -1 }
                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) modelData.disconnect();
                                        else if (modelData.paired) modelData.connect();
                                    }
                                }
                            }
                        }
                    }
                }

                PopButton {
                    width: parent.width
                    text: "Bluetooth manager (bluetui)"
                    icon: "\uf1de"
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", Quickshell.env("HOME") + "/.cargo/bin/bluetui"]);
                        pop.visible = false;
                    }
                }
            }
        }
    }
}
