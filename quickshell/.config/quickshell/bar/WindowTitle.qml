// Active window title for this bar's monitor — italic, dimmed, elides when long.
import QtQuick
import qs
import Quickshell
import Quickshell.Hyprland

Segment {
    id: root
    required property var screen
    italic: true
    color: Theme.comment
    hoverColor: Theme.fg
    // maxContentWidth is bound by Bar.qml to the leftover space before the clock.
    text: {
        const t = Hyprland.activeToplevel;
        if (!t)
            return "";
        if (screen && t.monitor && t.monitor.name !== screen.name)
            return "";
        return t.title;
    }
}
