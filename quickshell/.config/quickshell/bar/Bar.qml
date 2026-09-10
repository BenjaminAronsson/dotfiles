// Quickshell status bar — replaces waybar. One instance per monitor (created
// via Variants in shell.qml). Layout mirrors the old waybar config:
//   left: workspaces + window title | center: clock | right: modules + tray
import QtQuick
import qs
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    // Uses the built-in PanelWindow.screen; shell.qml's Variants delegate sets it
    // per monitor. Declaring our own `screen` here would shadow it and stack
    // every bar onto the primary monitor.

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Theme.barHeight

    color: Theme.panelBg
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "waybar"   // reuse the existing blur layer rule
    exclusionMode: ExclusionMode.Auto

    // Bottom hairline, matching waybar's border-bottom.
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        color: Theme.line
    }

    // Enable the shared clock once (system-wide, not per monitor).
    Component.onCompleted: {
        SystemClock.enabled = true;
        SystemClock.precision = SystemClock.Minutes;
    }

    // Three-zone layout: the clock is centered and each side row is bounded by
    // its edges. The one flexible item per row (window title / now-playing) is
    // given exactly the leftover space, so it only elides when it would run
    // into the clock — ample room on a wide monitor, tighter on a narrow one.

    Clock {
        id: clock
        barWindow: root
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
        id: leftRow
        anchors.left: parent.left
        anchors.right: clock.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 10
        spacing: 6
        clip: true

        Workspaces { id: workspaces; screen: root.screen }
        WindowTitle {
            id: windowTitle
            screen: root.screen
            // Fill the space left of the clock; elides only when it would overlap.
            // Subtract the title's own horizontal padding so it can't push under
            // the clock (Segment width = maxContentWidth + hpad*2).
            maxContentWidth: Math.max(0,
                leftRow.width - workspaces.implicitWidth - leftRow.spacing - Theme.barPad * 2)
        }
    }

    // Right row: laid out right-to-left so it hugs the right edge. MPRIS is the
    // flexible item and takes whatever space the other modules leave before the
    // clock. Children are declared in reverse so visual order matches waybar.
    Row {
        id: rightRow
        anchors.left: clock.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 6
        layoutDirection: Qt.RightToLeft
        clip: true

        Tray { id: tray; barWindow: root }
        Temperature { id: temperature }
        PowerMode { id: powerMode; barWindow: root }
        Battery { id: battery; barWindow: root }
        Audio { id: audio; barWindow: root }
        Network { id: network; barWindow: root }
        VPN { id: vpn; barWindow: root }
        Bluetooth { id: bluetooth; barWindow: root }
        Backlight { id: backlight; barWindow: root }
        TimerBar { id: timer; barWindow: root }
        BlueLight { id: bluelight; barWindow: root }
        Mpris {
            id: mpris
            barWindow: root
            // Sum of the other visible modules' widths + their gaps.
            readonly property int others: (tray.visible ? tray.implicitWidth : 0)
                + (temperature.visible ? temperature.implicitWidth : 0)
                + (powerMode.visible ? powerMode.implicitWidth : 0)
                + (battery.visible ? battery.implicitWidth : 0)
                + (audio.visible ? audio.implicitWidth : 0)
                + (network.visible ? network.implicitWidth : 0)
                + (vpn.visible ? vpn.implicitWidth : 0)
                + (bluetooth.visible ? bluetooth.implicitWidth : 0)
                + (backlight.visible ? backlight.implicitWidth : 0)
                + (timer.visible ? timer.implicitWidth : 0)
                + (bluelight.visible ? bluelight.implicitWidth : 0)
                + (idle.visible ? idle.implicitWidth : 0)
            readonly property int gaps: rightRow.spacing * ((tray.visible ? 1 : 0)
                + (temperature.visible ? 1 : 0) + (powerMode.visible ? 1 : 0)
                + (battery.visible ? 1 : 0) + (audio.visible ? 1 : 0)
                + (network.visible ? 1 : 0) + (vpn.visible ? 1 : 0) + (bluetooth.visible ? 1 : 0)
                + (backlight.visible ? 1 : 0) + (timer.visible ? 1 : 0)
                + (bluelight.visible ? 1 : 0) + (idle.visible ? 1 : 0))
            maxContentWidth: Math.max(0,
                rightRow.width - others - gaps - Theme.barPad * 2)
        }
        IdleInhibit { id: idle }
    }
}
