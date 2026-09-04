pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/shortfin/config.json`

    property var data: ({})

    function lookup(key: string): var {
        let node = root.data;
        for (const part of key.split(".")) {
            if (node === null || typeof node !== "object" || !(part in node))
                return undefined;
            node = node[part];
        }
        return node;
    }

    function str(key: string, fallback: string): string {
        const v = root.lookup(key);
        return typeof v === "string" && v.length > 0 ? v : fallback;
    }

    function num(key: string, fallback: real): real {
        const v = root.lookup(key);
        return typeof v === "number" && isFinite(v) ? v : fallback;
    }

    function flag(key: string, fallback: bool): bool {
        const v = root.lookup(key);
        return typeof v === "boolean" ? v : fallback;
    }

    function path(key: string, fallback: string): string {
        const v = root.str(key, fallback);
        return v.startsWith("~/") ? `${Quickshell.env("HOME")}/${v.slice(2)}` : v;
    }

    function obj(key: string, fallback: var): var {
        const v = root.lookup(key);
        return v !== null && typeof v === "object" && !Array.isArray(v) ? v : fallback;
    }

    function list(key: string, fallback: var): var {
        const v = root.lookup(key);
        return Array.isArray(v) ? v : fallback;
    }

    FileView {
        id: file

        path: root.configPath
        preload: true

        blockLoading: true

        printErrors: false

        watchChanges: true
        onFileChanged: file.reload()

        onLoaded: {
            try {
                const parsed = JSON.parse(file.text());
                root.data = parsed !== null && typeof parsed === "object" ? parsed : {};
            } catch (e) {

                console.warn(`Options: ${root.configPath} is not valid JSON, ignoring it (${e.message})`);
                root.data = {};
            }
        }

        onLoadFailed: root.data = ({})
    }
}
