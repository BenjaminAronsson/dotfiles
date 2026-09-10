// A full-width clickable row (icon + label) for popover actions.
import QtQuick
import qs

Item {
    id: root
    property string text: ""
    property string icon: ""
    property color color: Theme.fg
    property bool hover: true

    signal clicked

    implicitHeight: 30
    implicitWidth: 100

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: ma.containsMouse && root.hover ? Theme.inactiveBg : "transparent"
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            color: root.color
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            color: root.color
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
