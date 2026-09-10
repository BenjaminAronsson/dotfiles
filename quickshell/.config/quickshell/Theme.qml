// Theme singleton — vague.nvim palette, shared by the launcher and the
// future bar/notifications. Mirrors dotfiles/waybar/style.css.
// https://github.com/vague2k/vague.nvim
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Palette
    readonly property color bg: "#141415"
    readonly property color inactiveBg: "#1c1c24"
    readonly property color fg: "#cdcdcd"
    readonly property color line: "#252530"
    readonly property color comment: "#606079"
    readonly property color builtin: "#b4d4cf"   // teal
    readonly property color keyword: "#6e94b2"   // steel
    readonly property color hint: "#7e98e8"      // periwinkle
    readonly property color error: "#d8647e"
    readonly property color warning: "#f3be7c"
    readonly property color plus: "#7fa563"
    readonly property color orange: "#e0a363"
    readonly property color mpris: "#aeaed1"

    // Translucent panel background — alpha lets the Hyprland blur layer
    // rule show through, same as waybar's rgba(20, 20, 21, 0.85).
    readonly property color panelBg: Qt.rgba(20 / 255, 20 / 255, 21 / 255, 0.85)

    // Typography
    readonly property string fontFamily: "CaskaydiaCove Nerd Font"
    readonly property int fontSize: 14

    // Bar (mirrors waybar config: height 32, font 13, module padding 10)
    readonly property int barHeight: 32
    readonly property int barFontSize: 13
    readonly property int barPad: 10

    // Popovers / notification cards. Translucent so the Hyprland blur layer
    // rules (both use a blurred namespace) show the frosted desktop through.
    readonly property color popoverBg: Qt.rgba(18 / 255, 18 / 255, 22 / 255, 0.72)
    readonly property color popoverBorder: "#2f2f3d"
    readonly property int popoverRadius: 12
    readonly property int popoverPad: 14
    readonly property int popoverWidth: 340
    readonly property int popoverSpacing: 8
}











































































































































