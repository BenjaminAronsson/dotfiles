// Countdown timer control for the calendar / timer popover. The running state
// lives in BarState (so it survives the popover closing); this only edits it.
// Accepts a duration ("2h", "30m", "1h15m", "45s", bare minutes) or a clock
// time ("18:30" or "1420" / "930" = 24h without a colon).
import QtQuick
import qs

Item {
    id: root
    width: parent ? parent.width : 268
    implicitWidth: width
    implicitHeight: col.implicitHeight

    readonly property bool running: BarState.timerActive
    property real remaining: BarState.timerEnd - Date.now()

    // Refresh the display while running (expiry + notification are in BarState).
    Timer {
        running: root.running
        repeat: true
        interval: 250
        onTriggered: root.remaining = BarState.timerEnd - Date.now()
    }

    function parse(s) {
        s = (s || "").trim().toLowerCase();
        if (!s)
            return null;
        // clock time with colon: "18:30"
        let m = s.match(/^(\d{1,2}):(\d{2})$/);
        if (m)
            return clockDelta(+m[1], +m[2]);
        // clock time without colon: "1420", "930", "930" (3-4 digits, valid h/m)
        if (/^\d{3,4}$/.test(s)) {
            const h = s.length === 4 ? +s.slice(0, 2) : +s[0];
            const mi = +s.slice(-2);
            if (h < 24 && mi < 60)
                return clockDelta(h, mi);
        }
        // duration tokens: 1h30m15s
        const re = /(\d+(?:\.\d+)?)\s*(h|hr|hrs|hour|hours|m|min|mins|minute|minutes|s|sec|secs|second|seconds)/g;
        let total = 0, t, matched = false;
        while ((t = re.exec(s))) {
            matched = true;
            const v = parseFloat(t[1]);
            const u = t[2][0];
            total += (u === "h" ? 3600000 : u === "m" ? 60000 : 1000) * v;
        }
        if (matched)
            return total;
        // bare 1-2 digits = minutes
        if (/^\d{1,2}$/.test(s))
            return parseInt(s) * 60000;
        return null;
    }

    function clockDelta(h, mi) {
        const now = new Date();
        const t = new Date(now.getFullYear(), now.getMonth(), now.getDate(), h, mi, 0, 0);
        if (t.getTime() <= now.getTime())
            t.setDate(t.getDate() + 1);
        return t.getTime() - now.getTime();
    }

    function fmt(ms) {
        const s = Math.max(0, Math.ceil(ms / 1000));
        const h = Math.floor(s / 3600), mm = Math.floor((s % 3600) / 60), ss = s % 60;
        const p = n => (n < 10 ? "0" : "") + n;
        return h > 0 ? h + ":" + p(mm) + ":" + p(ss) : mm + ":" + p(ss);
    }

    function start(str) {
        const dur = parse(str);
        if (!dur || dur <= 0) {
            field.text = "";
            return;
        }
        BarState.startTimer(dur, str.trim());
        field.text = "";
    }

    Column {
        id: col
        width: parent.width
        spacing: 6

        Rectangle { width: parent.width; height: 1; color: Theme.line }

        // Idle: input + start
        Row {
            width: parent.width
            spacing: 8
            visible: !root.running
            Rectangle {
                width: parent.width
                height: 28
                radius: 6
                color: Theme.inactiveBg
                border.width: 1
                border.color: field.activeFocus ? Theme.keyword : Theme.line
                TextInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: Theme.fg
                    selectedTextColor: Theme.bg
                    selectionColor: Theme.keyword
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    cursorVisible: field.activeFocus
                    onAccepted: root.start(text)
                }
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    visible: field.text.length === 0 && !field.activeFocus
                    text: "timer: 2h · 30m · 1420"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.comment
                }
            }
        }

        // Running: remaining + label + stop
        Row {
            width: parent.width
            spacing: 8
            visible: root.running
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf017"
                font.family: Theme.fontFamily
                font.pixelSize: 16
                color: Theme.warning
            }
            Column {
                width: parent.width - 72
                spacing: 1
                Text {
                    text: root.fmt(root.remaining)
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.warning
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: BarState.timerLabel
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.comment
                }
            }
            Item {
                width: 32
                height: 28
                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    color: Theme.error
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BarState.stopTimer()
                }
            }
        }
    }
}
