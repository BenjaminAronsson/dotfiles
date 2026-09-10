// Now-playing (MPRIS). Prefers a playing player, else the first one.
// Hidden when nothing is playing. Left click opens the player popover;
// scroll skips tracks.
import QtQuick
import qs
import Quickshell
import Quickshell.Services.Mpris

Segment {
    id: root
    property var barWindow: null
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    visible: players.length > 0
    readonly property bool playing: player ? player.isPlaying : false
    // maxContentWidth is bound by Bar.qml to the leftover space before the clock.

    text: {
        if (!player)
            return "";
        const icon = playing ? "\uf04b " : "\uf04c ";
        const title = player.trackTitle ?? "";
        const artist = player.trackArtist ?? "";
        // Length is bounded visually by maxContentWidth (dynamic elide), so only
        // apply a generous backstop for pathological strings.
        let s = playing && artist ? title + " — " + artist : title;
        if (s.length > 140)
            s = s.slice(0, 140);
        return icon + s;
    }
    color: playing ? Theme.mpris : Theme.comment
    underline: pop.visible ? Theme.mpris : "transparent"

    onClicked: pop.visible = !pop.visible
    function toggle(): void { pop.visible = !pop.visible; }
    function show(): void { pop.visible = true; }
    onScrolled: delta => {
        if (!player)
            return;
        if (delta > 0) player.next();
        else if (delta < 0) player.previous();
    }

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component { Player { player: root.player } }
    }
}
