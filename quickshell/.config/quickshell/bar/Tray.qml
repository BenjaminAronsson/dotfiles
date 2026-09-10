// System tray (StatusNotifierItem). Left click activates the app, right click
// pops the app's own context menu (DBusMenu) via QsMenuEntry.display().
import QtQuick
import qs
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    id: root
    required property var barWindow   // the PanelWindow, for menu anchoring
    spacing: 8

    // TEMP debug: trigger the first tray menu via `qs ipc call bartray menu`
    IpcHandler {
        target: "bartray"
        function menu(): void {
            const it = SystemTray.items.values.find(i => i.hasMenu);
            if (it) it.display(root.barWindow, 60, 32);
        }
    }

    Repeater {
        model: SystemTray.items
        delegate: Item {
            id: cell
            required property var modelData
            implicitWidth: Math.max(img.implicitSize, 16) + 6
            implicitHeight: Theme.barHeight

            IconImage {
                id: img
                anchors.centerIn: parent
                implicitSize: 18
                source: cell.modelData.icon ?? ""
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: me => {
                    const it = cell.modelData;
                    if (me.button === Qt.RightButton) {
                        if (it.hasMenu) {
                            const p = cell.mapToItem(root.barWindow.contentItem, me.x, me.y);
                            it.display(root.barWindow, p.x, p.y);
                        } else {
                            it.secondaryActivate();
                        }
                    } else {
                        it.activate();
                    }
                }
                onWheel: w => {
                    cell.modelData.scroll(w.angleDelta.y > 0 ? 120 : -120, false);
                    w.accepted = true;
                }
            }
        }
    }
}
