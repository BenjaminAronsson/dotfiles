// Minimal themed horizontal slider for bar popovers (seek, volume, brightness).
// Emits `moved` continuously while dragging and `released` on lift, so hosts can
// choose live-apply (volume) vs. apply-on-release (seek).
import QtQuick
import qs

Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property color accent: Theme.builtin
    readonly property real frac: to > from ? (value - from) / (to - from) : 0
    readonly property bool dragging: ma.pressed

    signal moved(real value)
    signal released(real value)

    implicitHeight: 22
    implicitWidth: 120

    function setFromX(x) {
        const f = Math.max(0, Math.min(1, x / width));
        value = from + f * (to - from);
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.line

        Rectangle {
            width: root.frac * parent.width
            height: parent.height
            radius: parent.radius
            color: root.accent
        }
    }

    Rectangle {
        id: knob
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, root.frac * root.width - width / 2))
        width: 12
        height: 12
        radius: 6
        color: root.dragging ? Theme.fg : root.accent
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onPressed: me => { root.setFromX(me.x); root.moved(root.value); }
        onPositionChanged: me => { root.setFromX(me.x); root.moved(root.value); }
        onReleased: root.released(root.value)
    }
}
