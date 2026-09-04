pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property int revision: 0

    readonly property var specials: {
        revision;
        return Hyprland.workspaces.values.filter(w => w.name.startsWith("special:") && (w.lastIpcObject?.windows ?? 0) > 0);
    }

    readonly property bool fullscreen: {
        revision;
        return Hyprland.focusedWorkspace?.lastIpcObject?.hasfullscreen ?? false;
    }

    function shownSpecial(monitor: HyprlandMonitor): string {
        revision;
        return monitor?.lastIpcObject?.specialWorkspace?.name ?? "";
    }

    function focus(workspace: string): void {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = "${workspace}" })` : `workspace ${workspace}`);
    }

    function focusRelative(delta: int): void {
        focus(`r${delta > 0 ? "+" : "-"}${Math.abs(delta)}`);
    }

    function toggleSpecial(name: string): void {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.workspace.toggle_special("${name}")` : `togglespecialworkspace ${name}`);
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (["workspace", "moveworkspace", "activespecial", "focusedmon", "fullscreen"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else {
                return;
            }

            root.revision++;
        }

        target: Hyprland
    }
}
