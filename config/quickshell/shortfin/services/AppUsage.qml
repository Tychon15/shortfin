pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var counts: ({})

    function launches(id: string): int {
        return root.counts[id] ?? 0;
    }

    function record(id: string): void {
        if (!id)
            return;

        const next = Object.assign({}, root.counts);
        next[id] = (next[id] ?? 0) + 1;
        root.counts = next;
        save.restart();
    }

    FileView {
        id: file

        path: Quickshell.statePath("launcher-usage.json")
        preload: true

        printErrors: false

        onLoaded: {
            try {
                const parsed = JSON.parse(file.text());
                if (parsed && typeof parsed === "object")
                    root.counts = parsed;
            } catch (e) {

            }
        }
    }

    Timer {
        id: save

        interval: 500
        onTriggered: file.setText(JSON.stringify(root.counts))
    }
}
