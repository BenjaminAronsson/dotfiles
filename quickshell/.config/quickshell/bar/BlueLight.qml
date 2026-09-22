// Blue-light filter bar segment — a view of the global BarState.bl* values.
// Popover has an on/off switch and a temperature slider; the actual wlsunset
// process + persistence live in BarState (single, across all monitors).
import QtQuick
import qs

Segment {
    id: root
    property var barWindow: null

    text: BarState.blEnabled ? "\uf186 " + BarState.blTemp + "K" : "\uf186"
    color: BarState.blEnabled ? Theme.orange : Theme.comment
    underline: pop.visible ? Theme.orange : "transparent"

    onClicked: pop.visible = !pop.visible
    function show(): void { pop.visible = true; }
    onRightClicked: { BarState.blEnabled = !BarState.blEnabled; BarState.blSave(); BarState.blApply(); }

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component {
            Column {
                width: Theme.popoverWidth
                spacing: Theme.popoverSpacing

                Item {
                    width: parent.width
                    height: 22
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf186  Blue light"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.orange
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34; height: 18; radius: 9
                        color: BarState.blEnabled ? Theme.orange : Theme.line
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            text: BarState.blEnabled ? "on" : "off"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.bg
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { BarState.blEnabled = !BarState.blEnabled; BarState.blSave(); BarState.blApply(); }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4
                    Text {
                        text: "Temperature — " + BarState.blTemp + "K"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.comment
                    }
                    Slider {
                        width: parent.width
                        from: 2700
                        to: 6500
                        value: BarState.blTemp
                        accent: Theme.orange
                        onMoved: v => BarState.blSetTemp(Math.round(v))
                    }
                    Row {
                        width: parent.width
                        Text {
                            width: parent.width / 2
                            text: "warm 2700K"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.comment
                        }
                        Text {
                            width: parent.width / 2
                            horizontalAlignment: Text.AlignRight
                            text: "6500K neutral"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.comment
                        }
                    }
                }
            }
        }
    }
}
