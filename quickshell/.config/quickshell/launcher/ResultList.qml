// Result list — ListView with keyboard-driven selection, styled after
// wofi's #entry / #entry:selected in dotfiles/wofi/style.css.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

ListView {
    id: root

    signal activated(var item)

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: 0

    // Keep the highlight visible while navigating
    highlightFollowsCurrentItem: true
    highlightMoveDuration: 60
    highlightResizeDuration: 0

    highlight: Rectangle {
        color: Theme.line
        radius: 6
    }

    delegate: Item {
        id: row
        required property var modelData
        required property int index

        width: root.width
        implicitHeight: 36

        // Click to activate, hover moves selection
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.currentIndex = row.index
            onClicked: root.activated(row.modelData)
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 22
                source: {
                    const icon = row.modelData.icon ?? "";
                    return icon ? Quickshell.iconPath(icon, true) : "";
                }
                visible: source != ""
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32

                Text {
                    text: row.modelData.display ?? ""
                    color: root.currentIndex === row.index ? Theme.builtin : Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    visible: text !== ""
                    text: row.modelData.sub ?? ""
                    color: Theme.comment
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }
    }

    function moveSelection(delta) {
        if (count === 0)
            return;
        currentIndex = (currentIndex + delta + count) % count;
    }

    function activateCurrent() {
        if (count > 0 && currentIndex >= 0 && currentIndex < count)
            activated(model[currentIndex]);
    }

    onCountChanged: currentIndex = 0
}
