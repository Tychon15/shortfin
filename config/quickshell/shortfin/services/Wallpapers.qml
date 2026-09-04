pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string directory: Options.path("wallpaperDir", `${Quickshell.env("HOME")}/Pictures/Wallpapers`)

    property var files: []

    property string current

    property string preview

    readonly property string shown: preview || current

    onShownChanged: if (shown)
        Scheme.source = shown;

    function indexOf(path: string): int {
        return root.files.indexOf(path);
    }

    function commit(): void {
        if (root.preview) {
            root.current = root.preview;
            root.preview = "";
            save.setText(root.current);
        }
    }

    function revert(): void {
        root.preview = "";
    }

    onDirectoryChanged: scan.running = true

    Process {
        id: scan

        running: true
        command: ["sh", "-c", `find "${root.directory}" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \\) | sort`]

        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.trim().split("\n").filter(line => line.length > 0);
                root.files = found;

                if (found.length > 0 && found.indexOf(root.current) === -1)
                    root.current = found[0];
            }
        }
    }

    FileView {
        id: save

        path: Quickshell.statePath("wallpaper.txt")
        preload: true

        blockLoading: true
        printErrors: false

        onLoaded: {
            const saved = save.text().trim();
            if (saved)
                root.current = saved;
        }
    }
}
