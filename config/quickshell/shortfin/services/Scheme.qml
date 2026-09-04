pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var fallback: ({
        bg: "#0a1626",
        bgAlt: "#101f33",
        surface: "#1b3049",
        fg: "#dce8f6",
        fgDim: "#7c96b4",
        accent: "#3ea8e0",
        accentAlt: "#6fd4f2",
        good: "#3fc7a4",
        warn: "#e6b455",
        bad: "#e8687e"
    })

    readonly property color good: Options.str("good", "#3fc7a4")
    readonly property color warn: Options.str("warn", "#e6b455")
    readonly property color bad: Options.str("bad", "#e8687e")

    property var colours: fallback

    property string source

    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`}/wal`

    onSourceChanged: if (source)
        settle.restart()

    Timer {
        id: settle

        interval: 16
        onTriggered: {

            derive.command = ["sh", "-c", `wal -i "${root.source}" -n -t -e -q --cols16 lighten >/dev/null 2>&1; cat "${root.cache}/colors.json"`];
            derive.running = true;
        }
    }

    function shade(base: color, saturation: real, value: real): color {
        return Qt.hsva(base.hsvHue < 0 ? 0 : base.hsvHue, Math.max(0, Math.min(1, saturation)), Math.max(0, Math.min(1, value)), 1);
    }

    function adopt(data: var): var {
        const c = data.colors;
        const ground = Qt.color(data.special.background);
        const text = Qt.color(data.special.foreground);

        const bg = root.shade(ground, Math.min(ground.hsvSaturation, 0.55), Math.min(ground.hsvValue, 0.11));
        const fg = root.shade(text, Math.min(text.hsvSaturation, 0.16), Math.max(text.hsvValue, 0.90));

        let pick = 1;
        for (let i = 2; i <= 6; i++) {
            if (Qt.color(c[`color${i}`]).hsvSaturation > Qt.color(c[`color${pick}`]).hsvSaturation)
                pick = i;
        }

        const accent = Qt.color(c[`color${pick}`]);

        return {
            bg: bg,
            bgAlt: root.shade(bg, bg.hsvSaturation, bg.hsvValue + 0.045),
            surface: root.shade(bg, bg.hsvSaturation * 0.9, bg.hsvValue + 0.15),
            fg: fg,
            fgDim: root.shade(fg, Math.max(fg.hsvSaturation, 0.08) * 2.2, fg.hsvValue * 0.72),
            accent: root.shade(accent, Math.max(accent.hsvSaturation, 0.45), Math.max(accent.hsvValue, 0.72)),
            accentAlt: root.shade(accent, Math.max(accent.hsvSaturation, 0.35) * 0.8, Math.max(accent.hsvValue, 0.9)),
            good: root.good,
            warn: root.warn,
            bad: root.bad
        };
    }

    Process {
        id: derive

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data && data.colors && data.special)
                        root.colours = root.adopt(data);
                } catch (e) {

                }
            }
        }
    }
}
