pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {

    readonly property int barHeight: Options.num("barHeight", 34)
    readonly property int barMargin: Options.num("barMargin", 6)
    readonly property int radius: Options.num("radius", 12)
    readonly property int spacing: Options.num("spacing", 8)
    readonly property int padding: Options.num("padding", 10)

    readonly property string font: Options.str("font", "RobotoMono Nerd Font")

    readonly property string iconFont: Options.str("iconFont", "JetBrainsMono Nerd Font")
    readonly property int fontSize: Options.num("fontSize", 12)

    readonly property color bg: Scheme.colours.bg
    readonly property color bgAlt: Scheme.colours.bgAlt
    readonly property color surface: Scheme.colours.surface
    readonly property color fg: Scheme.colours.fg
    readonly property color fgDim: Scheme.colours.fgDim
    readonly property color accent: Scheme.colours.accent
    readonly property color accentAlt: Scheme.colours.accentAlt

    readonly property color good: Scheme.good
    readonly property color warn: Scheme.warn
    readonly property color bad: Scheme.bad

    readonly property int workspaceCount: Options.num("workspaceCount", 5)
    readonly property int animDuration: Options.num("animDuration", 180)

    readonly property int windowAnimIn: Options.num("windowAnimIn", 500)
    readonly property int windowAnimOut: Options.num("windowAnimOut", 400)

    readonly property int lockAnimIn: Options.num("lockAnimIn", 900)
    readonly property int lockAnimOut: Options.num("lockAnimOut", 800)

    readonly property var animCurve: Options.list("animCurve", [0.05, 0.7, 0.1, 1.0, 1.0, 1.0])
    readonly property bool showDate: Options.flag("showDate", true)

    readonly property var sessionCommands: Options.obj("sessionCommands", {
        "sleep": ["systemctl", "suspend"],
        "logout": ["sh", "-c", "if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then uwsm stop; else hyprctl dispatch exit; fi"],
        "reboot": ["systemctl", "reboot"],
        "shutdown": ["systemctl", "poweroff"]
    })

    readonly property var published: ({
        bg: `${bg}`,
        bgAlt: `${bgAlt}`,
        surface: `${surface}`,
        fg: `${fg}`,
        fgDim: `${fgDim}`,
        accent: `${accent}`,
        accentAlt: `${accentAlt}`,
        good: `${good}`,
        warn: `${warn}`,
        bad: `${bad}`,
        radius: radius,
        padding: padding,
        spacing: spacing,
        barHeight: barHeight,
        barMargin: barMargin,
        font: font,
        iconFont: iconFont,
        fontSize: fontSize
    })

    onPublishedChanged: settle.restart()

    Timer {
        id: settle

        interval: 50
        onTriggered: {
            publish.running = false;
            publish.running = true;
        }
    }

    Process {
        id: publish

        command: ["sh", "-c", 'mkdir -p "$1" && printf %s "$2" > "$1/palette.json" && shortfin-theme-reload', "sh", `${Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`}/shortfin`, JSON.stringify(published)]
    }
}
