// Clock. Left click opens a calendar popover. Scroll toggles HH:MM <-> full
// date. Uses a 1s timer + JS Date (quickshell 0.3.1's SystemClock.date is
// unreliable).
import QtQuick
import qs

Segment {
    id: root
    property var barWindow: null
    property bool alt: false
    property var now: new Date()
    color: Theme.builtin
    bold: true
    text: "\uf017 " + Qt.formatDateTime(now, alt ? "dddd d MMMM" : "HH:mm")
    underline: pop.visible ? Theme.builtin : "transparent"
    onScrolled: alt = !alt
    onClicked: pop.visible = !pop.visible
    function toggle(): void { pop.visible = !pop.visible; }
    function show(): void { pop.visible = true; }

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: root.now = new Date()
    }

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component { Calendar {} }
    }
}
