// Now-playing popover body: album art, metadata, a draggable seek bar and
// transport controls. Receives the active MprisPlayer from the Mpris module.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs

Item {
    id: root
    required property var player

    width: Theme.popoverWidth
    implicitWidth: width
    implicitHeight: col.implicitHeight

    property real pos: player ? player.position : 0
    property bool seeking: false
    readonly property real len: player && player.lengthSupported ? player.length : 0

    // PipeWire sink-input (per-app playback node) for the active player, so the
    // volume slider drives that app's own volume (works for Brave, where MPRIS
    // volume is ignored). Matched by application name / desktop entry.
    readonly property var sinkNodes: Pipewire.nodes.values.filter(
        n => n.isStream && (n.type & PwNodeType.AudioOutStream))
    readonly property var node: {
        const id = ((player && player.identity) || "").toLowerCase().trim();
        const de = ((player && player.desktopEntry) || "").toLowerCase().trim();
        const base = de.split(".").pop();   // org.bravebrowser.Brave -> Brave
        if (!id && !base)
            return null;
        return sinkNodes.find(n => {
            const p = n.properties || {};
            const name = (n.name || "").toLowerCase();
            const desc = (n.description || "").toLowerCase();
            const an = (p["application.name"] || "").toLowerCase();
            const hay = [name, desc, an];
            const hit = t => t && hay.some(h => h && (h === t || h.includes(t) || t.includes(h)));
            if (hit(id) || hit(base))
                return true;
            return false;
        }) ?? null;
    }

    // Volume — drive the playing app's PipeWire sink-input via wpctl (quickshell's
    // PwNodeAudio.volume write is a no-op). Falls back to MPRIS volume if no node.
    property int volId: node ? node.id : -1
    property real vol: 0
    property bool volDrag: false
    readonly property bool hasVol: node ? true : (player ? player.volumeSupported : false)

    Process {
        id: volRead
        stdout: StdioCollector {
            id: volOut
            onStreamFinished: {
                const m = volOut.text.match(/Volume:\s*([0-9.]+)/);
                if (m && !root.volDrag)
                    root.vol = parseFloat(m[1]);
            }
        }
    }
    function refreshVol() {
        if (volId > 0)
            volRead.exec(["wpctl", "get-volume", String(volId)]);
        else if (player)
            vol = player.volume;
    }
    function setVol(v) {
        vol = v;
        if (volId > 0)
            Quickshell.execDetached(["wpctl", "set-volume", String(volId), Math.round(v * 100) + "%"]);
        else if (player)
            player.volume = v;
    }
    onVolIdChanged: refreshVol()

    // Sync the slider to the live node/player volume on open and while shown
    // (unless mid-drag), since onVolIdChanged may not fire on initial mount.
    Component.onCompleted: refreshVol()
    Timer {
        running: root.visible
        repeat: true
        interval: 400
        onTriggered: root.refreshVol()
    }

    // Keep the playhead fresh while playing (MPRIS position isn't always a
    // live Qt property); don't fight the user while they drag.
    Timer {
        running: root.visible && root.player && root.player.isPlaying
        repeat: true
        interval: 500
        onTriggered: if (!root.seeking) root.pos = root.player.position;
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0));
        const m = Math.floor(s / 60);
        const ss = s % 60;
        return m + ":" + (ss < 10 ? "0" : "") + ss;
    }

    visible: player !== null && player !== undefined

    Column {
        id: col
        width: parent.width
        spacing: 12

        // Art + metadata
        Row {
            width: parent.width
            spacing: 12

            Rectangle {
                width: 88
                height: 88
                radius: 8
                color: Theme.inactiveBg
                clip: true
                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.player ? (root.player.trackArtUrl || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !(root.player && root.player.trackArtUrl)
                    text: "\uf001"
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    color: Theme.comment
                }
            }

            Column {
                width: parent.width - 88 - 12
                spacing: 3
                y: 4
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.player ? (root.player.trackTitle || "") : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.fg
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.player ? (root.player.trackArtist || "") : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.mpris
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text.length > 0
                    text: root.player ? (root.player.trackAlbum || "") : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.comment
                }
            }
        }

        // Seek bar
        Row {
            width: parent.width
            spacing: 8
            Text {
                width: 34
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
                text: root.fmt(root.pos)
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.comment
            }
            Slider {
                id: seek
                width: parent.width - 76
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: root.len > 0 ? root.len : 1
                value: root.pos
                enabled: root.player ? root.player.canSeek : false
                opacity: enabled ? 1 : 0.4
                onMoved: v => { root.seeking = true; root.pos = v; }
                onReleased: v => {
                    root.seeking = false;
                    if (root.player && root.player.canSeek)
                        root.player.position = v;
                }
            }
            Text {
                width: 34
                anchors.verticalCenter: parent.verticalCenter
                text: root.fmt(root.len)
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.comment
            }
        }

        // Transport
        Row {
            width: parent.width
            spacing: 0
            Repeater {
                model: [
                    { icon: "\uf074", on: root.player ? root.player.shuffle : false, act: "shuffle" },
                    { icon: "\uf048", on: false, act: "prev" },
                    { icon: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b", on: false, act: "play" },
                    { icon: "\uf051", on: false, act: "next" },
                    { icon: "\uf021", on: root.player ? root.player.loopState !== MprisLoopState.None : false, act: "loop" }
                ]
                delegate: Item {
                    required property var modelData
                    width: parent.width / 5
                    height: 34
                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.family: Theme.fontFamily
                        font.pixelSize: modelData.act === "play" ? 20 : 15
                        color: modelData.on ? Theme.builtin : Theme.fg
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.act(modelData.act)
                    }
                }
            }
        }

        // Volume — drives the playing app's PipeWire sink-input (per-app),
        // falling back to the MPRIS player volume.
        Row {
            width: parent.width
            spacing: 10
            visible: root.hasVol
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.vol <= 0 ? "\uf026" : (root.vol < 0.5 ? "\uf027" : "\uf028")
                font.family: Theme.fontFamily
                font.pixelSize: 15
                color: Theme.mpris
            }
            Slider {
                width: parent.width - 30
                anchors.verticalCenter: parent.verticalCenter
                accent: Theme.mpris
                from: 0
                to: 1
                value: root.vol
                onMoved: v => { root.volDrag = true; root.setVol(v); }
                onReleased: root.volDrag = false
            }
        }
    }

    function act(kind) {
        const p = root.player;
        if (!p)
            return;
        switch (kind) {
        case "prev": p.previous(); break;
        case "next": p.next(); break;
        case "play": p.togglePlaying(); break;
        case "shuffle": p.shuffle = !p.shuffle; break;
        case "loop":
            p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Track
                : p.loopState === MprisLoopState.Track ? MprisLoopState.Playlist : MprisLoopState.None;
            break;
        }
    }
}
