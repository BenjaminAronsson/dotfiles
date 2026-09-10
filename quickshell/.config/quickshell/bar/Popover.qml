// Reusable drop-down panel anchored beneath a bar segment.
//
// Implemented as a full-screen Overlay PanelWindow (like the launcher): a
// transparent backdrop swallows any click outside the card and closes it,
// while the card itself is positioned under `sourceItem`. A PopupWindow was
// tried first but under Hyprland it isn't a layer-shell surface and stacks
// *behind* normal windows. Reuses the "waybar" namespace to inherit blur.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    // The item (usually the Segment) this panel hangs beneath.
    required property Item sourceItem
    // The owning bar PanelWindow — used to map sourceItem's position and to
    // inherit the correct screen (items inside a PanelWindow report a null
    // `.window`, so we pass the window explicitly like Tray does).
    required property var barWindow
    // The panel body, mounted only while open.
    property Component content: null
    property int pad: Theme.popoverPad
    property int gap: 6

    screen: barWindow ? barWindow.screen : Quickshell.screens[0]

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "waybar"
    // Unconditional exclusive focus (like the launcher) so the HyprlandFocusGrab
    // reliably engages when the panel maps — a conditional binding can miss the
    // grab, leaving outside clicks (esp. on other monitors) unable to close it.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    readonly property int cardW: loader.implicitWidth > 0 ? loader.implicitWidth + pad * 2 : 0
    readonly property int cardH: loader.implicitHeight > 0 ? loader.implicitHeight + pad * 2 : 0
    property int cardX: 0

    // "Keep-alive" region: the union of the trigger and the card, from the top
    // of the screen down to just below the card. While the pointer is inside it
    // the panel stays open; leaving it (left/right/below, or off this monitor)
    // closes the panel instantly.
    property int keepLeft: 0
    property int keepRight: 0
    property int keepBottom: 0

    // Center the card horizontally under its source module (clamped to the screen).
    function reposition() {
        const content = barWindow && barWindow.contentItem;
        if (!content)
            return;
        const p = sourceItem.mapToItem(content, 0, 0);
        const x = p.x + sourceItem.width / 2 - cardW / 2;
        cardX = Math.max(4, Math.min(x, width - cardW - 4));
        const m = 10;
        keepLeft = Math.min(cardX, p.x) - m;
        keepRight = Math.max(cardX + cardW, p.x + sourceItem.width) + m;
        keepBottom = Theme.barHeight + gap + cardH + m;
    }

    onVisibleChanged: {
        if (visible) {
            // Only one popover open at a time across all bars.
            if (BarState.openPopover && BarState.openPopover !== root)
                BarState.openPopover.visible = false;
            BarState.openPopover = root;
            focusAtOpen = Hyprland.activeToplevel;
            reposition();
        } else if (BarState.openPopover === root) {
            BarState.openPopover = null;
        }
    }
    onWidthChanged: if (visible) reposition();
    onCardWChanged: if (visible) reposition();
    onCardHChanged: if (visible) reposition();

    // Backdrop: closes on a click outside the card, and — the main behaviour —
    // instantly when the pointer leaves the keep-alive region (moving off to the
    // left/right/below, or onto another monitor, which fires onExited).
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.visible = false
        onExited: root.visible = false
        onPositionChanged: me => {
            if (!root.visible)
                return;
            if (me.x < root.keepLeft || me.x > root.keepRight || me.y > root.keepBottom)
                root.visible = false;
        }
    }

    // Cross-monitor dismissal: the backdrop only covers this screen, so also
    // watch for keyboard focus leaving the panel (a click on any other monitor's
    // window steals it) and close. `armed` avoids the spurious clear at open.
    HyprlandFocusGrab {
        id: grab
        active: root.visible
        windows: [root]
        property bool armed: false
        onActiveChanged: if (active) armed = true
        onCleared: {
            if (armed) root.visible = false;
            armed = false;
        }
    }

    // Cross-monitor dismissal: HyprlandFocusGrab doesn't fire when focus moves
    // to a window on another output, so also close when the focused toplevel
    // changes to a different window than when the panel opened.
    property var focusAtOpen: null
    Connections {
        target: Hyprland
        enabled: root.visible
        function onActiveToplevelChanged() {
            if (root.visible && Hyprland.activeToplevel !== root.focusAtOpen)
                root.visible = false;
        }
        // Hotkey-jumping to a workspace on another monitor: close, since the
        // panel is no longer under the focused output.
        function onFocusedMonitorChanged() {
            if (!root.visible)
                return;
            const fm = Hyprland.focusedMonitor;
            if (fm && root.screen && fm.name !== root.screen.name)
                root.visible = false;
        }
    }

    Rectangle {
        id: card
        x: root.cardX
        y: Theme.barHeight + root.gap
        width: cardW
        height: cardH
        radius: Theme.popoverRadius
        color: Theme.popoverBg
        border.width: 1
        border.color: Theme.popoverBorder

        // Swallow clicks on the card so they don't reach the backdrop.
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Loader {
            id: loader
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: root.pad
            anchors.topMargin: root.pad
            active: root.visible
            sourceComponent: root.content
        }
    }

    // Escape dismisses while the panel holds keyboard focus.
    Item {
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: root.visible = false
    }
}
