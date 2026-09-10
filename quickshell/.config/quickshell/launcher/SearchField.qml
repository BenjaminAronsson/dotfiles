// Search field — styled after wofi's #input in dotfiles/wofi/style.css.
import QtQuick
import Quickshell
import qs

Rectangle {
    id: root

    property alias text: input.text
    signal accepted()
    signal moveSelection(int delta)
    signal cycleMode()
    signal dismissed()

    implicitHeight: 40
    color: Theme.inactiveBg
    border.width: 2
    border.color: input.activeFocus ? Theme.builtin : Theme.line
    radius: 6

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter

        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        clip: true

        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: root.dismissed()
        Keys.onTabPressed: root.cycleMode()
        Keys.onUpPressed: root.moveSelection(-1)
        Keys.onDownPressed: root.moveSelection(1)
        // vim-style navigation
        Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_N) { root.moveSelection(1); event.accepted = true; }
                else if (event.key === Qt.Key_P) { root.moveSelection(-1); event.accepted = true; }
            }
        }
    }

    function forceFocus() {
        input.forceActiveFocus();
    }

    function clear() {
        input.text = "";
    }
}
