// Centiro VPN (NetworkManager L2TP/IPsec connection "Centiro SSTP VPN").
// State is shared via BarState so the launcher's quick action agrees with
// this module, and so only one nmcli poller runs across all monitors.
// Left click opens a toggle popover; right click toggles directly.
import QtQuick
import qs

Segment {
    id: root
    property var barWindow: null

    text: "" + (BarState.vpnConnecting ? " …" : BarState.vpnConnected ? " VPN" : "")
    color: BarState.vpnConnected ? Theme.plus : BarState.vpnConnecting ? Theme.warning : Theme.comment
    underline: pop.visible ? Theme.plus : "transparent"

    onClicked: pop.visible = !pop.visible
    function show(): void { pop.visible = true; }
    onRightClicked: BarState.vpnToggle()

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
                        text: "  Centiro VPN"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: BarState.vpnConnected ? Theme.plus : Theme.comment
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34; height: 18; radius: 9
                        color: BarState.vpnConnected ? Theme.plus : Theme.line
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            text: BarState.vpnConnecting ? "…" : BarState.vpnConnected ? "on" : "off"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.bg
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarState.vpnToggle()
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.line }

                Text {
                    width: parent.width
                    text: BarState.vpnConnecting
                        ? "Connecting… (check for a password prompt)"
                        : BarState.vpnConnected ? "Connected to ra-sstp.centiro.se" : "Disconnected"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.comment
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
