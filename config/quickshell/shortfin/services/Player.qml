pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property var lastPlaying: null

    readonly property var active: {
        const list = Mpris.players.values;
        const playing = list.find(p => p.isPlaying);

        if (playing)
            return playing;

        if (lastPlaying && list.includes(lastPlaying))
            return lastPlaying;

        return list[0] ?? null;
    }

    onActiveChanged: if (active?.isPlaying)
        lastPlaying = active;

    property bool tracking: false

    readonly property real position: active?.position ?? 0
    readonly property real length: active?.length ?? 0

    readonly property string trackKey: active ? `${active.trackArtist} :: ${active.trackTitle} :: ${active.trackAlbum}` : ""

    Timer {
        running: root.tracking && (root.active?.isPlaying ?? false)
        interval: 500
        repeat: true

        onTriggered: root.active.positionChanged()
    }
}
