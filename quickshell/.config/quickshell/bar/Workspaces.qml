// Hyprland workspaces for this bar's monitor. Number label, accent underline
// when active, red when urgent. Click activates.
import QtQuick
import qs
import Quickshell
import Quickshell.Hyprland

Row {
    id: root
    required property var screen
    spacing: 0

    Repeater {
        model: Hyprland.workspaces
        delegate: Item {
            id: cell
            required property var modelData
            readonly property bool mine: screen
                && modelData.monitor
                && modelData.monitor.name === screen.name
            visible: mine
            implicitWidth: mine ? lbl.implicitWidth + 16 : 0
            implicitHeight: Theme.barHeight

            Text {
                id: lbl
                anchors.centerIn: parent
                text: cell.modelData.name
                font.family: Theme.fontFamily
                font.pixelSize: Theme.barFontSize
                color: cell.modelData.urgent ? Theme.error
                    : cell.modelData.active ? Theme.builtin
                    : ma.containsMouse ? Theme.fg : Theme.comment
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                visible: cell.modelData.active
                color: Theme.builtin
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                onClicked: cell.modelData.activate()
            }
        }
    }
}
