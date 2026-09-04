import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config

MouseArea {
    id: root

    property string device
    property int max: 0
    property int current: 0

    readonly property int percent: max > 0 ? Math.round(current / max * 100) : 0

    function setPercent(value: int): void {
        if (setProc.running || !device)
            return;

        setProc.command = ["brightnessctl", "-q", "-d", device, "set", `${Math.max(1, Math.min(100, value))}%`];
        setProc.running = true;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    cursorShape: Qt.PointingHandCursor
    onWheel: event => root.setPercent(root.percent + (event.angleDelta.y > 0 ? 5 : -5))

    Process {
        running: true
        command: ["sh", "-c", "d=$(ls -d /sys/class/backlight/* 2>/dev/null | head -1); [ -n \"$d\" ] && echo \"$(basename $d) $(cat $d/max_brightness)\""]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                if (parts.length === 2) {
                    root.device = parts[0];
                    root.max = parseInt(parts[1]) || 0;
                    level.path = `/sys/class/backlight/${root.device}/brightness`;
                }
            }
        }
    }

    Process {
        id: setProc

        onExited: level.reload()
    }

    FileView {
        id: level

        onLoaded: root.current = parseInt(text().trim()) || 0
    }

    Timer {
        interval: 1500
        running: root.max > 0
        repeat: true
        onTriggered: level.reload()
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.percent >= 67 ? "\u{f00e0}" : root.percent >= 34 ? "\u{f00df}" : "\u{f00de}"
            color: Config.fg

            font.family: Config.iconFont
            font.pixelSize: Config.fontSize + 2
        }

        Text {
            text: root.percent
            color: Config.fgDim

            font.family: Config.font
            font.pixelSize: Config.fontSize
        }
    }
}
