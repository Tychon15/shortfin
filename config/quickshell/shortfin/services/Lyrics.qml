pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string state: "idle"

    property var lines: []

    readonly property bool synced: lines.length > 0 && lines[0].time >= 0

    property var cache: ({})

    property string pending: ""

    function indexAt(position: real): int {
        if (!synced)
            return -1;

        let lo = 0;
        let hi = lines.length - 1;
        let found = -1;

        while (lo <= hi) {
            const mid = (lo + hi) >> 1;
            if (lines[mid].time <= position) {
                found = mid;
                lo = mid + 1;
            } else {
                hi = mid - 1;
            }
        }

        return found;
    }

    function parseLrc(text: string): var {
        const out = [];

        for (const raw of text.split("\n")) {
            const stamps = [];
            const re = /\[(\d+):(\d+(?:[.:]\d+)?)\]/g;
            let m;

            while ((m = re.exec(raw)))
                stamps.push(Number(m[1]) * 60 + Number(m[2].replace(":", ".")));

            if (stamps.length === 0)
                continue;

            const body = raw.replace(/\[[^\]]*\]/g, "").trim();

            for (const time of stamps)
                out.push({
                    time: time,
                    text: body
                });
        }

        return out.sort((a, b) => a.time - b.time);
    }

    function accept(payload: var): var {
        const synced = payload?.syncedLyrics ?? "";
        const plain = payload?.plainLyrics ?? "";

        let parsed = [];

        if (synced)
            parsed = parseLrc(synced);

        if (parsed.length === 0 && plain)
            parsed = plain.split("\n").map(l => ({
                time: -1,
                text: l.trim()
            }));

        return parsed;
    }

    function fetchFor(key: string): void {
        const player = Player.active;

        if (!player || !player.trackTitle) {
            state = "idle";
            lines = [];
            return;
        }

        if (cache[key] !== undefined) {
            lines = cache[key];
            state = lines.length > 0 ? "ok" : "none";
            return;
        }

        state = "loading";
        lines = [];
        pending = key;

        const enc = encodeURIComponent;
        const artist = enc(player.trackArtist ?? "");
        const title = enc(player.trackTitle ?? "");
        const album = enc(player.trackAlbum ?? "");

        const duration = Math.round(player.length ?? 0);

        const base = "https://lrclib.net/api/";
        const get = `${base}get?artist_name=${artist}&track_name=${title}&album_name=${album}&duration=${duration}`;
        const search = `${base}search?artist_name=${artist}&track_name=${title}`;

        query.command = ["sh", "-c", `r=$(curl -sfL -A shortfin/0.1 --max-time 8 "${get}"); [ -n "$r" ] || r=$(curl -sfL -A shortfin/0.1 --max-time 8 "${search}"); printf '%s' "$r"`];
        query.running = true;
    }

    Connections {
        target: Player

        function onTrackKeyChanged(): void {
            debounce.restart();
        }
    }

    Timer {
        id: debounce

        interval: 400
        onTriggered: root.fetchFor(Player.trackKey)
    }

    Process {
        id: query

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = [];

                try {
                    const data = JSON.parse(text);
                    parsed = root.accept(Array.isArray(data) ? data[0] : data);
                } catch (e) {

                }

                const next = Object.assign({}, root.cache);
                next[root.pending] = parsed;
                root.cache = next;

                if (root.pending === Player.trackKey) {
                    root.lines = parsed;
                    root.state = parsed.length > 0 ? "ok" : "none";
                }
            }
        }
    }
}
