// Bar segment shown only while a countdown is running: live remaining time,
// click to open a popover to stop/reset, right-click to stop immediately.
import QtQuick
import qs

Segment {
    id: root
    property var barWindow: null
    visible: BarState.timerActive
    property real remaining: BarState.timerEnd - Date.now()

    color: remaining <= 60000 ? Theme.error : Theme.warning
    underline: pop.visible ? Theme.warning : "transparent"

    text: {
        const s = Math.max(0, Math.ceil(remaining / 1000));
        const h = Math.floor(s / 3600), mm = Math.floor((s % 3600) / 60), ss = s % 60;
        const p = n => (n < 10 ? "0" : "") + n;
        return "\uf017 " + (h > 0 ? h + ":" + p(mm) + ":" + p(ss) : mm + ":" + p(ss));
    }

    Timer {
        running: root.visible
        repeat: true
        interval: 500
        onTriggered: root.remaining = BarState.timerEnd - Date.now()
    }

    onClicked: pop.visible = !pop.visible
    function show(): void { pop.visible = true; }
    onRightClicked: BarState.stopTimer()

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component { Countdown {} }
    }
}
