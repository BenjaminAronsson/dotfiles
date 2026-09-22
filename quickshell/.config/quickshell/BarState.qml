// Global bar state shared across the per-monitor Bar instances and popovers.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // The currently open Popover (so opening one closes any other).
    property var openPopover: null

    // Countdown timer — lives here (not in the transient popover) so it keeps
    // running and can fire a notification after the popover is closed.
    property real timerEnd: 0        // ms epoch; 0 = idle
    property string timerLabel: ""
    readonly property bool timerActive: timerEnd > 0

    // Alarm: loops the sound until the notification is dismissed.
    property bool alarmActive: false
    readonly property string alarmFile: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

    Process {
        id: alarm
        command: ["pw-play", root.alarmFile]
        // When a play finishes, loop again while the alarm is still active.
        onExited: if (root.alarmActive) alarm.exec(["pw-play", root.alarmFile])
    }

    function startTimer(ms, label) {
        timerEnd = Date.now() + ms;
        timerLabel = label;
    }
    function stopTimer() {
        timerEnd = 0;
        timerLabel = "";
    }

    function stopAlarm() {
        alarmActive = false;
        alarm.running = false;   // kill any in-flight play immediately
    }

    // --- Blue-light filter (global; one wlsunset for all outputs) ----------
    property bool blEnabled: false
    property int blTemp: 4500
    readonly property string blLat: "57.72"
    readonly property string blLon: "12.94"

    Process {
        id: sun
        command: []
    }
    function blApply() {
        if (!blEnabled) {
            sun.running = false;
            return;
        }
        sun.running = false;
        sun.command = ["wlsunset", "-l", blLat, "-L", blLon,
            "-t", String(blTemp), "-T", String(blTemp + 1)];
        sun.running = true;
    }
    function blSave() {
        blStore.setText(JSON.stringify({ enabled: blEnabled, temp: blTemp }));
    }
    // Sliding the temperature shouldn't restart wlsunset on every tick — update
    // the value live but only (re)apply ~700ms after the last change.
    function blSetTemp(v) {
        blTemp = v;
        blDebounce.restart();
    }
    Timer {
        id: blDebounce
        interval: 700
        onTriggered: {
            root.blApply();
            root.blSave();
        }
    }
    FileView {
        id: blStore
        path: Quickshell.statePath("bluelight.json")
        blockLoading: true
        onLoaded: {
            try {
                const j = JSON.parse(blStore.text() || "{}");
                root.blEnabled = !!j.enabled;
                root.blTemp = j.temp || 4500;
            } catch (e) {
            }
            root.blApply();
        }
    }

    Timer {
        running: root.timerActive
        repeat: true
        interval: 500
        onTriggered: {
            if (Date.now() >= root.timerEnd) {
                const l = root.timerLabel;
                root.stopTimer();
                root.alarmActive = true;
                alarm.exec(["pw-play", root.alarmFile]);
                // Critical → our daemon keeps it until dismissed, which stops the alarm.
                Quickshell.execDetached(["notify-send", "-u", "critical",
                    "Timer finished", (l ? l + " elapsed" : "Time's up")]);
            }
        }
    }

    // --- Centiro VPN (NetworkManager L2TP/IPsec connection) ----------------
    // Shared so the bar module and the launcher's quick action agree on
    // state, and so only one poller runs regardless of how many bar
    // instances (one per monitor) exist.
    readonly property string vpnName: "Centiro SSTP VPN"
    property bool vpnConnected: false
    property bool vpnConnecting: false

    function vpnPoll() {
        vpnPollProc.exec(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]);
    }
    function vpnToggle() {
        if (vpnConnecting)
            return;
        vpnConnecting = true;
        if (vpnConnected)
            vpnProc.exec(["nmcli", "connection", "down", vpnName]);
        else
            vpnProc.exec(["nmcli", "connection", "up", vpnName]);
    }

    Process {
        id: vpnPollProc
        stdout: StdioCollector {
            id: vpnPollOut
            onStreamFinished: {
                const lines = vpnPollOut.text.split("\n");
                root.vpnConnected = lines.some(l => l.startsWith(root.vpnName + ":vpn"));
            }
        }
    }
    // nmcli connection up/down blocks until the connection settles (or
    // nm-applet's secret agent finishes prompting for the password on first
    // use), so "connecting" stays true for exactly as long as that takes.
    Process {
        id: vpnProc
        onExited: {
            root.vpnConnecting = false;
            root.vpnPoll();
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 5000
        onTriggered: root.vpnPoll()
    }
    Component.onCompleted: vpnPoll()
}
