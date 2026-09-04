pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var needed: ({
        "curl": "weather and lyrics",
        "wal": "wallpaper colour scheme (install python-pywal16)",
        "grim": "lock screen backdrop",
        "nmcli": "network menu",
        "brightnessctl": "brightness control",
        "busctl": "power profiles and session actions",
        "gdbus": "power profile and sleep monitoring",
        "systemd-inhibit": "locking before suspend",
        "setpriv": "cleaning up the sleep monitor",
        "python3": "integrated GPU usage"
    })

    function check(): void {
        probe.running = true;
    }

    Process {
        id: probe

        command: ["sh", "-c", `for c in ${Object.keys(root.needed).join(" ")}; do command -v "$c" >/dev/null 2>&1 || echo "$c"; done`]

        stdout: StdioCollector {
            onStreamFinished: {
                const missing = text.trim().split("\n").filter(line => line.length > 0);
                if (missing.length === 0)
                    return;

                console.warn(`shortfin: missing ${missing.length === 1 ? "program" : "programs"} — ${missing.map(c => `${c} (${root.needed[c]})`).join(", ")}`);
            }
        }
    }
}
