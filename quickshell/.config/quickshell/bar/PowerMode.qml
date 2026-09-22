// Power profile (power-profiles-daemon). Hidden on machines without a
// battery or performance profile. Click opens a profile picker; the popover
// also reflects external changes.
import QtQuick
import qs
import Quickshell
import Quickshell.Services.UPower

Segment {
    id: root
    property var barWindow: null
    readonly property bool hasBattery:
        UPower.devices.values.some(d => d.type === UPowerDeviceType.Battery)
    visible: hasBattery || PowerProfiles.hasPerformanceProfile

    color: PowerProfiles.profile === PowerProfile.Performance ? Theme.error
        : PowerProfiles.profile === PowerProfile.PowerSaver ? Theme.plus : Theme.builtin

    text: {
        const p = PowerProfiles.profile;
        const icon = p === PowerProfile.Performance ? "\uf0e7"
            : p === PowerProfile.PowerSaver ? "\uf06c" : "\uf24e";
        const name = p === PowerProfile.Performance ? "performance"
            : p === PowerProfile.PowerSaver ? "power-saver" : "balanced";
        return icon + " " + name;
    }
    underline: pop.visible ? color : "transparent"

    onClicked: pop.visible = !pop.visible
    function show(): void { pop.visible = true; }

    Popover {
        id: pop
        sourceItem: root
        barWindow: root.barWindow
        content: Component {
            Column {
                width: Theme.popoverWidth
                spacing: 4
                Repeater {
                    model: [
                        { prof: PowerProfile.PowerSaver, icon: "\uf06c", name: "Power Saver",
                          desc: "Lowest power, reduced performance", col: Theme.plus },
                        { prof: PowerProfile.Balanced, icon: "\uf24e", name: "Balanced",
                          desc: "Even split of power and speed", col: Theme.builtin },
                        { prof: PowerProfile.Performance, icon: "\uf0e7", name: "Performance",
                          desc: "Maximum speed, more power draw", col: Theme.error }
                    ]
                    delegate: Item {
                        required property var modelData
                        visible: modelData.prof !== PowerProfile.Performance
                            || PowerProfiles.hasPerformanceProfile
                        width: parent.width
                        height: 44
                        readonly property bool active: PowerProfiles.profile === modelData.prof

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: active ? Theme.inactiveBg : (ma.containsMouse ? Theme.line : "transparent")
                        }
                        Rectangle {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            width: 3; height: parent.height - 12; radius: 2
                            color: modelData.col; visible: active
                        }
                        Text {
                            id: ic
                            anchors.left: parent.left; anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            color: modelData.col
                        }
                        Column {
                            anchors.left: ic.right; anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.barFontSize
                                font.bold: active
                                color: active ? Theme.fg : Theme.comment
                            }
                            Text {
                                text: modelData.desc
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.comment
                            }
                        }
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            visible: active
                            text: "\uf00c"
                            font.family: Theme.fontFamily
                            color: modelData.col
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerProfiles.profile = modelData.prof
                        }
                    }
                }
            }
        }
    }
}
