// Battery. Hidden automatically when the machine has no battery (desktop).
// Click opens a per-device details popover (state, time remaining, wattage).
import QtQuick
import qs
import Quickshell
import Quickshell.Services.UPower

Segment {
    id: root
    property var barWindow: null
    readonly property var dev: UPower.displayDevice
    readonly property var batteries: UPower.devices.values.filter(d => d.type === UPowerDeviceType.Battery)
    visible: batteries.length > 0
    // UPower exposes percentage on a 0..1 scale.
    readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0

    color: !dev ? Theme.fg
        : dev.state === UPowerDeviceState.Charging ? Theme.plus
        : pct <= 15 ? Theme.error
        : pct <= 30 ? Theme.warning : Theme.fg

    text: {
        if (!dev)
            return "";
        if (dev.state === UPowerDeviceState.Charging)
            return "\uf0e7 " + pct + "%";
        if (dev.state === UPowerDeviceState.FullyCharged)
            return "\uf1e6 " + pct + "%";
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"];
        return icons[Math.min(4, Math.floor(pct / 20))] + " " + pct + "%";
    }
    underline: pop.visible ? color : "transparent"

    onClicked: pop.visible = !pop.visible
    function show(): void { pop.visible = true; }

    function fmtTime(s) {
        s = Math.max(0, Math.round(s || 0));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component {
            Column {
                width: Theme.popoverWidth
                spacing: Theme.popoverSpacing

                Text {
                    text: (root.dev && root.dev.state === UPowerDeviceState.Charging)
                        ? "Charging — " + root.fmtTime(root.dev.timeToFull)
                        : (root.dev && root.dev.state === UPowerDeviceState.Discharging)
                            ? root.fmtTime(root.dev.timeToEmpty) + " remaining"
                            : "Fully charged"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    color: root.color
                }

                Repeater {
                    model: root.batteries
                    delegate: Column {
                        required property var modelData
                        width: parent.width
                        spacing: 4
                        Rectangle { width: parent.width; height: 1; color: Theme.line }
                        Row {
                            width: parent.width
                            Text {
                                width: parent.width * 0.6
                                text: modelData.model || "Battery"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.barFontSize
                                color: Theme.fg
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width * 0.4
                                horizontalAlignment: Text.AlignRight
                                text: Math.round(modelData.percentage * 100) + "%"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.barFontSize
                                color: root.color
                            }
                        }
                        Row {
                            width: parent.width
                            Text {
                                width: parent.width * 0.6
                                text: modelData.state === UPowerDeviceState.Charging ? "charging"
                                    : modelData.state === UPowerDeviceState.Discharging ? "discharging" : "idle"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.comment
                            }
                            Text {
                                width: parent.width * 0.4
                                horizontalAlignment: Text.AlignRight
                                text: (modelData.changeRate > 0.05 ? modelData.changeRate.toFixed(1) + " W · " : "")
                                    + modelData.energy.toFixed(1) + "/" + modelData.energyCapacity.toFixed(1) + " Wh"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.comment
                            }
                        }
                    }
                }
            }
        }
    }
}
