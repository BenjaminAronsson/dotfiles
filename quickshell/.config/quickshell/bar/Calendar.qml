// Calendar body for the Clock popover: big clock, month grid (Mon-first),
// today highlighted, prev/next month navigation. Sized to fit Popover.
import QtQuick
import qs

Item {
    id: root

    readonly property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()   // 0-based

    width: 268
    height: col.implicitHeight
    implicitWidth: width
    implicitHeight: col.implicitHeight

    readonly property var weekdayShort: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    readonly property var monthName: ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]

    function shift(delta) {
        const m = viewMonth + delta;
        viewMonth = ((m % 12) + 12) % 12;
        viewYear += Math.floor(m / 12);
    }

    // First cell index of this month in a Monday-first grid (0..6).
    readonly property int lead: (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()

    readonly property int cell: Math.floor(width / 7)

    Column {
        id: col
        width: root.width
        spacing: Theme.popoverSpacing

        // Month navigation header
        Item {
            width: parent.width
            height: 22
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf053"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.fg
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.shift(-1) }
            }
            Text {
                anchors.centerIn: parent
                text: root.monthName[root.viewMonth] + " " + root.viewYear
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: Theme.fg
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf054"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.fg
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.shift(1) }
            }
        }

        // Weekday header + day grid share a 7-column metric.
        Grid {
            width: parent.width
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: 7
                Text {
                    required property int index
                    width: root.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: root.weekdayShort[index]
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.comment
                }
            }

            Repeater {
                model: Math.ceil((root.lead + root.daysInMonth) / 7) * 7
                delegate: Item {
                    required property int index
                    readonly property int dayNum: index - root.lead + 1
                    readonly property bool inMonth: dayNum >= 1 && dayNum <= root.daysInMonth
                    readonly property bool isToday: inMonth
                        && root.viewYear === root.today.getFullYear()
                        && root.viewMonth === root.today.getMonth()
                        && dayNum === root.today.getDate()
                    width: root.cell
                    height: root.cell

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 2
                        height: width
                        radius: width / 2
                        color: parent.isToday ? Theme.keyword : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: parent.inMonth ? parent.dayNum : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: parent.isToday ? Theme.bg
                            : parent.inMonth ? Theme.fg : Theme.line
                    }
                }
            }
        }

        Countdown {}
    }
}
