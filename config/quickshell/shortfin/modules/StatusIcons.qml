import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config

RowLayout {
    id: root

    required property var bar

    spacing: 10

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    MouseArea {
        id: vol

        readonly property PwNode sink: Pipewire.defaultAudioSink
        readonly property real volume: sink?.audio?.volume ?? 0
        readonly property bool muted: sink?.audio?.muted ?? false

        implicitWidth: volRow.implicitWidth
        implicitHeight: volRow.implicitHeight

        cursorShape: Qt.PointingHandCursor
        onClicked: if (sink?.audio) sink.audio.muted = !sink.audio.muted
        onWheel: event => {
            if (!sink?.audio)
                return;
            const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step));
        }

        RowLayout {
            id: volRow

            anchors.centerIn: parent
            spacing: 6

            Text {
                text: vol.muted ? "\u{f0e08}" : vol.volume > 0.5 ? "\u{f057e}" : vol.volume > 0 ? "\u{f0580}" : "\u{f057f}"
                color: vol.muted ? Config.bad : Config.fg
                font.family: Config.iconFont
                font.pixelSize: Config.fontSize + 2
            }

            Text {
                text: Math.round(vol.volume * 100)
                color: Config.fgDim
                font.family: Config.font
                font.pixelSize: Config.fontSize
            }
        }
    }

    BrightnessButton {}

    NetworkButton {
        bar: root.bar
    }

    BatteryButton {
        bar: root.bar
    }
}
