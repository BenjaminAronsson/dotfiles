// Rofi-style launcher overlay — drun + window switcher + run mode.
// Replaces `wofi --show drun`; toggled via `qs ipc call launcher toggle`.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import "Fuzzy.js" as Fuzzy

PanelWindow {
    id: root

    // ---- modes ------------------------------------------------------
    readonly property var modes: ["drun", "windows"]
    property string mode: "drun"

    // ---- frecency (launch counts, persisted) ------------------------
    // { desktopId: { count: int, last: epochSeconds } }, stored as JSON in
    // the quickshell state dir so it survives restarts (not just reloads).
    property var frecency: ({})

    FileView {
        id: frecencyFile
        path: Quickshell.statePath("launcher-frecency.json")
        // Blocking load so the persisted weights are available before any
        // launch/rebuild — otherwise an early write would clobber the file.
        blockLoading: true
        onLoaded: root.loadFrecency()
        onLoadFailed: root.frecency = ({})   // first run / unreadable
        onSaveFailed: error => console.warn("launcher: frecency save failed:", error)
    }

    function loadFrecency() {
        try {
            frecency = JSON.parse(frecencyFile.text()) || {};
        } catch (e) {
            frecency = {};
        }
    }

    function recordLaunch(id) {
        if (!id)
            return;
        const entry = frecency[id] || { count: 0, last: 0 };
        frecency[id] = { count: entry.count + 1, last: Math.floor(Date.now() / 1000) };
        frecency = frecency;   // trigger change notification
        frecencyFile.setText(JSON.stringify(frecency));
    }

    // Weight: log-scaled count bonus + a strong bonus if launched recently.
    function frecencyWeight(id) {
        const f = frecency[id];
        if (!f || !f.count)
            return 0;
        const countBonus = 4 * Math.log(f.count + 1);
        const ageHours = (Date.now() / 1000 - f.last) / 3600;
        const recencyBonus = ageHours < 1 ? 15 : (ageHours < 24 ? 8 : 0);
        return countBonus + recencyBonus;
    }

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        bottom: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Click outside the dialog dismisses the launcher. The grab is only
    // considered "real" once it has actually begun (grab.active goes true);
    // a cleared signal before that (e.g. the compositor refusing the grab
    // right at open) must not immediately close the window.
    HyprlandFocusGrab {
        id: grab
        active: root.visible
        windows: [root]
        property bool armed: false
        onActiveChanged: if (active) armed = true
        onCleared: {
            if (armed) root.close();
            armed = false;
        }
    }

    // ---- model ------------------------------------------------------
    // Rows are plain objects: { display, sub, icon, entry|toplevel|command }
    property string query: ""
    property var rows: []

    onQueryChanged: rebuild()
    onModeChanged: rebuild()

    Component.onCompleted: {
        loadFrecency();   // blocking read guarantees weights are present first
        rebuild();
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.rebuild(); }
    }
    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() { if (root.mode === "windows") root.rebuild(); }
    }

    function rebuild() {
        if (mode === "windows")
            rows = buildWindowRows(query);
        else if (mode === "power")
            rows = buildPowerRows(query);
        else if (query.startsWith("!"))
            rows = buildRunRows(query.substring(1));
        else if (query.startsWith("/")) {
            ensureFileIndex();
            rows = buildFileRows();
        } else
            rows = buildDefaultRows(query);
    }

    // ---- calculator + web search ------------------------------------
    // Search engine used by the "Search:" row. Change the URL here to switch
    // engines (keep the trailing `?q=` — the query is appended + url-encoded).
    readonly property string searchEngine: "https://kagi.com/search?q="

    function evalMath(q) {
        const expr = q.trim();
        // Only pure arithmetic, and require at least one operator so a bare
        // number or a word never triggers the calculator.
        if (!/^[0-9+\-*/().^ ]+$/.test(expr) || !/[0-9]/.test(expr) || !/[+\-*/^]/.test(expr))
            return null;
        try {
            const js = expr.replace(/\^/g, "**");
            const val = Function('"use strict"; return (' + js + ');')();
            if (typeof val !== "number" || !isFinite(val))
                return null;
            return val;
        } catch (e) {
            return null;
        }
    }

    function fmtNum(v) {
        return Number.isInteger(v) ? v.toString() : parseFloat(v.toPrecision(10)).toString();
    }

    // Ordering for the default (drun) mode:
    //   1. calculator result, if the query is a valid expression
    //   2. best match (program or power action), if any
    //   3. web-search row (always second after a match)
    //   4. remaining matches
    // Power/session actions are ranked in alongside apps by the same fuzzy
    // score, so "shutdown"/"reboot"/"suspend" surface without Super+Esc.
    function buildDefaultRows(q) {
        const apps = buildAppRows(q);
        if (q.trim() === "")
            return apps;
        const power = [];
        for (const a of powerActions) {
            const s = Fuzzy.scoreFields(q, [[a.display, 3], [a.keywords, 2.5], [a.sub, 1]]);
            if (s >= 0)
                power.push({ _s: s, row: a });
        }
        const merged = apps.map(r => ({ _s: r._s ?? 0, row: r })).concat(power);
        merged.sort((x, y) => y._s - x._s);
        const list = merged.map(m => m.row);

        const out = [];
        const calc = evalMath(q);
        if (calc !== null)
            out.push({
                display: "= " + fmtNum(calc),
                sub: "calculator · Enter copies to clipboard",
                icon: "accessories-calculator",
                calc: calc
            });
        const search = {
            display: "Search: " + q,
            sub: "open in default browser",
            icon: "system-search",
            searchUrl: searchEngine + encodeURIComponent(q)
        };
        if (list.length > 0) {
            out.push(list[0]);   // best match on top
            out.push(search);    // search second
            for (let i = 1; i < list.length; i++)
                out.push(list[i]);
        } else {
            out.push(search);
        }
        return out;
    }

    function buildAppRows(q) {
        const apps = DesktopEntries.applications.values;
        const scored = [];
        for (const e of apps) {
            let s;
            if (q === "")
                s = 0;   // no query: rank purely by frecency
            else {
                s = Fuzzy.scoreFields(q, [
                    [e.name, 3],
                    [e.genericName, 2],
                    [(e.keywords || []).join(" "), 1.5],
                    [e.comment, 1],
                    [e.id, 0.5]
                ]);
                if (s < 0)
                    continue;
            }
            scored.push({ s: s + frecencyWeight(e.id), e });
        }
        scored.sort((a, b) => b.s - a.s);
        return scored.map(x => ({
            display: x.e.name, sub: x.e.genericName || x.e.comment || "",
            icon: x.e.icon, entry: x.e, _s: x.s
        }));
    }

    function buildWindowRows(q) {
        const wins = Hyprland.toplevels.values;
        const scored = [];
        for (const w of wins) {
            const cls = w.lastIpcObject ? (w.lastIpcObject.class ?? "") : "";
            const ws = w.workspace ? w.workspace.name : "?";
            if (q === "") {
                scored.push({ s: 0, w, cls, ws });
                continue;
            }
            const s = Fuzzy.scoreFields(q, [[w.title, 3], [cls, 2]]);
            if (s >= 0)
                scored.push({ s, w, cls, ws });
        }
        scored.sort((a, b) => b.s - a.s);
        return scored.map(x => ({
            display: x.w.title || x.cls,
            sub: x.cls + " — ws " + x.ws,
            icon: "",
            toplevel: x.w
        }));
    }

    function buildRunRows(cmd) {
        if (cmd.trim() === "")
            return [];
        return [{
            display: "Run: " + cmd,
            sub: "execute in shell",
            icon: "utilities-terminal",
            command: cmd
        }];
    }

    // ---- file search ("/" prefix, fzf-style) ------------------------
    // Build one index of every file under $HOME (incl. dotfiles, minus caches
    // and build dirs), then filter it client-side as you type. Matching is
    // substring (native, fast over ~200k paths); multi-word = AND. Enter opens
    // the selection in nvim (kitty).
    property var fileIndex: []        // array of { p, lc, base, baseLc }
    property bool fileIndexing: false
    readonly property string fdPath: "/usr/bin/fdfind"
    readonly property string homeDir: Quickshell.env("HOME")

    function ensureFileIndex() {
        if (fileIndex.length > 0 || fileIndexing)
            return;
        fileIndexing = true;
        fdIndex.exec([fdPath, "-a", "--hidden",
            "--exclude", ".git", "--exclude", ".cache",
            "--exclude", "node_modules", "--exclude", "target",
            "--exclude", ".rustup", "--exclude", ".cargo",
            ".", homeDir]);
    }

    function buildFileRows() {
        const term = query.substring(1).trim();
        if (fileIndexing)
            return [{ display: "Indexing files…", sub: "building the file list", icon: "system-search" }];
        if (term === "")
            return [{ display: "Find files…", sub: "type to search every file in your home", icon: "system-search" }];
        const terms = term.toLowerCase().split(/\s+/).filter(x => x.length > 0);
        const scored = [];
        for (let i = 0; i < fileIndex.length; i++) {
            const e = fileIndex[i];
            let ok = true;
            for (let j = 0; j < terms.length; j++) {
                if (e.lc.indexOf(terms[j]) === -1) { ok = false; break; }
            }
            if (!ok)
                continue;
            // Rank: basename match > path match; shorter paths win ties.
            let s = 0;
            if (e.baseLc.startsWith(terms[0])) s += 100;
            else if (e.baseLc.indexOf(terms[0]) >= 0) s += 50;
            s -= Math.min(e.p.length, 250) * 0.1;
            scored.push({ s, e });
        }
        scored.sort((a, b) => b.s - a.s);
        const out = [];
        for (let i = 0; i < scored.length && i < 50; i++) {
            const e = scored[i].e;
            out.push({ display: e.base, sub: e.p.substring(0, e.p.length - e.base.length - 1),
                icon: "text-x-generic", filePath: e.p });
        }
        if (out.length === 0)
            out.push({ display: "No files match: " + term, sub: "", icon: "system-search" });
        return out;
    }

    Process {
        id: fdIndex
        stdout: StdioCollector {
            id: fdIndexOut
            onStreamFinished: {
                const lines = fdIndexOut.text.split("\n");
                const idx = [];
                for (const p of lines) {
                    if (!p)
                        continue;
                    const base = p.substring(p.lastIndexOf("/") + 1);
                    idx.push({ p, lc: p.toLowerCase(), base, baseLc: base.toLowerCase() });
                }
                root.fileIndex = idx;
                root.fileIndexing = false;
                if (root.query.startsWith("/"))
                    root.rebuild();
            }
        }
    }

    // Power/session actions — shown both by Super+Esc and, when the query
    // matches, inline in the default launcher (keywords drive the matching).
    readonly property var powerActions: [
        { display: "Lock",     sub: "hyprlock",          icon: "system-lock-screen", command: "hyprlock",
          keywords: "lock lockscreen screen" },
        { display: "Logout",   sub: "exit Hyprland",     icon: "system-log-out",     command: "hyprctl dispatch 'hl.dsp.exit()'",
          keywords: "logout exit signout sign out quit session" },
        { display: "Suspend",  sub: "systemctl suspend", icon: "system-suspend",     command: "systemctl suspend",
          keywords: "suspend sleep hibernate standby" },
        { display: "Reboot",   sub: "systemctl reboot",  icon: "system-reboot",      command: "systemctl reboot",
          keywords: "reboot restart reboot" },
        { display: "Shutdown", sub: "systemctl poweroff",icon: "system-shutdown",    command: "systemctl poweroff",
          keywords: "shutdown poweroff power off halt turnoff turn off stop" },
        { display: BarState.vpnConnected ? "Disconnect VPN" : "Connect VPN",
          sub: BarState.vpnConnecting ? "connecting…" : "Centiro VPN (nmcli)",
          icon: BarState.vpnConnected ? "network-vpn" : "network-vpn-disabled",
          // Plain string, not a function — activate() runs it via `sh -c`,
          // same as the systemctl actions above. State (on/off/connecting)
          // is shared with the bar's VPN module through BarState, which also
          // owns the actual nmcli process and the poll that keeps both in sync.
          command: BarState.vpnConnected
              ? "nmcli connection down \"" + BarState.vpnName + "\""
              : "nmcli connection up \"" + BarState.vpnName + "\"",
          keywords: "vpn centiro connect disconnect l2tp sstp network" }
    ]

    function buildPowerRows(q) {
        const list = [];
        for (const a of powerActions) {
            if (q === "" || Fuzzy.fuzzyScore(q, a.display) >= 0)
                list.push(a);
        }
        return list;
    }

    // ---- actions ----------------------------------------------------
    function open() {
        openMode("drun");
    }

    function openMode(m) {
        query = "";
        mode = m;
        visible = true;
        search.clear();
        focusTimer.start();
    }

    function close() {
        grab.armed = false;
        visible = false;
    }

    function toggle() {
        if (visible) close(); else open();
    }

    function cycleMode() {
        // power is opened directly (SUPER+Esc), not part of Tab cycling
        const i = (modes.indexOf(mode) + 1) % modes.length;
        mode = modes[i];
    }

    // Test hooks (kept minimal; used to verify frecency/model behavior).
    function debugType(text) { search.text = text; }
    function debugKey(key) {
        if (key === "down") results.moveSelection(1);
        else if (key === "up") results.moveSelection(-1);
        else if (key === "tab") cycleMode();
        else if (key === "enter") results.activateCurrent();
        else if (key === "esc") close();
    }
    function debugFirstRow(): string {
        if (rows.length === 0) return "<empty>";
        const r = rows[0];
        return r.display + " | " + (r.sub ?? "") + " | mode=" + mode;
    }

    function activate(row) {
        if (!row)
            return;
        if (row.calc !== undefined) {
            Quickshell.clipboardText = fmtNum(row.calc);
        } else if (row.searchUrl) {
            Quickshell.execDetached(["xdg-open", row.searchUrl]);
        } else if (row.filePath) {
            Quickshell.execDetached(["kitty", "-e", "nvim", row.filePath]);
        } else if (row.entry) {
            recordLaunch(row.entry.id);
            if (row.entry.runInTerminal)
                Quickshell.execDetached(["kitty", "-e"].concat(row.entry.command));
            else
                row.entry.execute();
        } else if (row.toplevel) {
            // hyprctl is used instead of Hyprland.dispatch because the
            // dispatcher syntax differs in Lua mode (Hyprland.usingLua).
            Quickshell.execDetached([
                "hyprctl", "dispatch", "focuswindow",
                "address:" + row.toplevel.address
            ]);
        } else if (row.command) {
            if (Array.isArray(row.command))
                Quickshell.execDetached(row.command);   // power actions: argv list
            else
                Quickshell.execDetached(["sh", "-c", row.command]);   // run mode: string
        }
        close();
    }

    // Focus can only be taken once the window is actually on screen.
    Timer {
        id: focusTimer
        interval: 50
        onTriggered: search.forceFocus()
    }

    // ---- UI ---------------------------------------------------------
    // Dimmed backdrop; click anywhere outside the dialog dismisses.
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()

        Rectangle {
            color: "#80000000"
            anchors.fill: parent
        }

        // The dialog itself — 620x420 like wofi, centered.
        Rectangle {
            width: 1000
            height: 600
            anchors.centerIn: parent

            color: Theme.panelBg
            border.width: 2
            border.color: Theme.line
            radius: 10

            // Clicks inside must not reach the backdrop
            MouseArea {
                anchors.fill: parent
                onClicked: {} // swallow
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                SearchField {
                    id: search
                    width: parent.width
                    onTextChanged: root.query = text
                    onAccepted: results.activateCurrent()
                    onMoveSelection: delta => results.moveSelection(delta)
                    onCycleMode: root.cycleMode()
                    onDismissed: root.close()
                }

                // Mode indicator (visible when not in the default mode)
                Text {
                    visible: root.mode !== "drun" || root.query.startsWith("!")
                    text: root.query.startsWith("!") ? "run" : root.mode
                    color: root.mode === "power" ? Theme.error : Theme.keyword
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    leftPadding: 4
                }

                ResultList {
                    id: results
                    width: parent.width
                    height: parent.height - search.height - 6
                    model: root.rows
                    onActivated: row => root.activate(row)
                }
            }
        }
    }
}
