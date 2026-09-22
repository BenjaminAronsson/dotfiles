// A single notification card: app icon, summary, body, optional image,
// action buttons and a countdown bar. Dismisses on click or timeout.
import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs

Rectangle {
    id: card

    property var n: null             // the Notification object (null during rebind)
    property int total: 0            // ms before auto-expire; 0 = never
    property real startAt: 0         // wall-clock ms when shown

    signal expired
    signal dismissed

    readonly property bool critical: !!n && n.urgency === NotificationUrgency.Critical
    property real frac: 1
    property int pad: 12

    width: 360
    implicitWidth: width
    radius: Theme.popoverRadius
    color: Theme.popoverBg
    border.width: 1
    border.color: critical ? Theme.error : Theme.popoverBorder
    implicitHeight: col.implicitHeight + pad * 2
    height: implicitHeight

    Timer {
        running: card.total > 0
        repeat: true
        interval: 100
        onTriggered: {
            card.frac = Math.max(0, 1 - (Date.now() - card.startAt) / card.total);
            if (card.frac <= 0)
                card.expired();
        }
    }

    // Urgency accent stripe along the left edge.
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 6
        width: 3
        radius: 2
        color: card.critical ? Theme.error : Theme.keyword
    }

    Column {
        id: col
        x: card.pad
        y: card.pad
        width: card.width - card.pad * 2
        spacing: 6

        // Icon + text + optional image
        Item {
            width: parent.width
            height: Math.max(28, txt.implicitHeight, thumb.active ? 64 : 0)

            Loader {
                id: iconH
                width: 28
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                active: !!card.n && (card.n.appIcon || "").length > 0
                sourceComponent: IconImage {
                    anchors.fill: parent
                    source: card.n.appIcon
                }
            }
            Text {
                visible: !iconH.active
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf0f3"
                font.family: Theme.fontFamily
                font.pixelSize: 22
                color: Theme.comment
            }

            Column {
                id: txt
                anchors.left: parent.left
                anchors.leftMargin: 38
                anchors.right: parent.right
                anchors.rightMargin: card.n && card.n.image ? 72 : 0
                spacing: 2

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: card.n ? (card.n.summary || card.n.appName || "Notification") : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.fg
                }
                Text {
                    width: parent.width
                    visible: text.length > 0
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    text: card.n ? (card.n.body || "") : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.comment
                }
            }

            // Inline image thumbnail
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 64
                height: 64
                radius: 6
                color: Theme.inactiveBg
                clip: true
                visible: thumb.active
                Loader {
                    id: thumb
                    anchors.fill: parent
                    active: !!card.n && (card.n.image || "").length > 0
                    sourceComponent: Image {
                        anchors.fill: parent
                        source: card.n.image
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }
        }

    }

    // Countdown bar — an inset pill that depletes right-to-left.
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: card.pad
        anchors.rightMargin: card.pad
        anchors.bottomMargin: 6
        height: card.total > 0 ? 5 : 0
        radius: height / 2
        color: Theme.line
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * card.frac
            radius: parent.radius
            color: card.critical ? Theme.error : Theme.keyword
        }
    }

    // Click anywhere on the card to dismiss. Kept behind the content (z:-1) so
    // the action buttons above still receive their own clicks.
    MouseArea {
        z: -1
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: card.dismissed()
    }
}
