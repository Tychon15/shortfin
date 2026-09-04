pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    signal toggle

    GlobalShortcut {
        appid: "shortfin"
        name: "session"
        description: "Toggle the session menu"

        onReleased: root.toggle()
    }
}
