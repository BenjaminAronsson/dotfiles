// Native notification daemon (replaces mako). Registers a NotificationServer
// and shows notifications as themed cards, bottom-right on every screen.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs

Item {
    id: root

    // Active notifications, oldest first. Each entry: { n, total, start }.
    property var items: []
    readonly property int maxVisible: 5
    readonly property int defaultTimeout: 5000   // ms for normal/low with no hint

    function add(n) {
        n.tracked = true;   // keep the Notification object alive while shown
        // The server can tear down `n` for reasons that never touch our own
        // timer/click paths (the sending app calls CloseNotification, or a
        // replace supersedes it) — without this, that leaves a blank,
        // never-removed card behind since nothing else prunes `items`.
        n.closed.connect(() => root.close(n));
        const total = (n.urgency === NotificationUrgency.Critical)
            ? 0
            : (n.expireTimeout > 0 ? n.expireTimeout : defaultTimeout);
        items = items.concat([{ n: n, total: total, start: Date.now() }]);
        if (items.length > maxVisible)
            close(items[0].n);
    }

    function close(n) {
        const i = items.findIndex(x => x.n === n);
        if (i < 0)
            return;   // already removed (e.g. closed(s) already handled it)
        // Dismissing the timer's notification silences the looping alarm.
        if (n && n.summary === "Timer finished")
            BarState.stopAlarm();
        items = items.slice(0, i).concat(items.slice(i + 1));
        Qt.callLater(() => {
            try {
                n.dismiss();
            } catch (e) {
            }
        });
    }

    NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: false
        imageSupported: true
        persistenceSupported: true
        onNotification: n => root.add(n);
    }

    // One display window per screen; all share the same `items` model.
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData

            anchors.top: true
            anchors.right: true
            margins.top: Theme.barHeight + 12
            margins.right: 12
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "notifications"
            color: "transparent"

            implicitWidth: col.implicitWidth
            implicitHeight: col.implicitHeight

            Column {
                id: col
                spacing: 8
                Repeater {
                    model: root.items
                    delegate: NotificationCard {
                        required property var modelData
                        n: modelData.n
                        total: modelData.total
                        startAt: modelData.start
                        onExpired: root.close(modelData.n)
                        onDismissed: root.close(modelData.n)
                    }
                }
            }
        }
    }
}
