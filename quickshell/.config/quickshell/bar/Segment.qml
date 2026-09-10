// Reusable bar module: a padded, clickable/scrollable text label.
// Mirrors a single waybar module (icon + text, hover, click, scroll, right-click).
import QtQuick
import qs
import Quickshell

Item {
    id: root

    property alias text: label.text
    property color color: Theme.fg
    property alias bold: label.font.bold
    property alias italic: label.font.italic
    property int hpad: Theme.barPad
    property bool interactive: true
    // When > 0, long text is capped to this pixel width and elided (short text
    // keeps its natural width), so e.g. now-playing can't push other modules.
    property int maxContentWidth: 0
    // 2px accent bar along the bottom edge (used by the active workspace, and
    // lit up while a module's popover is open).
    property color underline: "transparent"
    property color hoverColor: color
    readonly property bool hovered: mouse.containsMouse

    signal clicked
    signal rightClicked
    signal middleClicked
    signal scrolled(int delta)

    readonly property bool clipping: maxContentWidth > 0 && label.implicitWidth > maxContentWidth
    implicitWidth: (clipping ? maxContentWidth : label.implicitWidth) + hpad * 2
    implicitHeight: Theme.barHeight

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        x: hpad
        width: root.clipping ? root.maxContentWidth : undefined
        elide: root.clipping ? Text.ElideRight : Text.ElideNone
        font.family: Theme.fontFamily
        font.pixelSize: Theme.barFontSize
        // Color is computed (not aliased) so hovering can't feed back into the
        // property it reads — avoids the hover binding loop.
        color: root.hovered ? root.hoverColor : root.color
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        color: root.underline
        visible: root.underline != "transparent"
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: me => {
            if (me.button === Qt.RightButton) root.rightClicked();
            else if (me.button === Qt.MiddleButton) root.middleClicked();
            else root.clicked();
        }
        onWheel: w => {
            root.scrolled(w.angleDelta.y > 0 ? 1 : (w.angleDelta.y < 0 ? -1 : 0));
            w.accepted = true;
        }
    }
}
