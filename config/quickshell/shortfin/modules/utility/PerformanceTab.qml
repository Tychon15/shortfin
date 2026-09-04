import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

ColumnLayout {
    id: root

    function percent(value: real): string {
        return `${Math.round(value * 100)}%`;
    }

    function celsius(value: real): string {
        return value > 0 ? `${Math.round(value)}°C` : "";
    }

    spacing: 19

    Meter {
        Layout.fillWidth: true

        glyph: "\u{f0ee0}"
        label: "CPU"
        value: SysInfo.cpu
        detail: root.percent(SysInfo.cpu)
        trailing: root.celsius(SysInfo.cpuTemp)
    }

    Meter {
        Layout.fillWidth: true

        glyph: "\u{f08ae}"
        label: "GPU"
        value: SysInfo.gpu
        detail: SysInfo.gpuLabel
        trailing: SysInfo.gpuDetail
    }

    Meter {
        Layout.fillWidth: true

        glyph: "\u{f035b}"
        label: "Memory"
        value: SysInfo.memory
        detail: `${SysInfo.format(SysInfo.memoryUsed)} / ${SysInfo.format(SysInfo.memoryTotal)}`
        trailing: root.percent(SysInfo.memory)
    }

    Meter {
        Layout.fillWidth: true

        glyph: "\u{f02ca}"
        label: "Storage"
        value: SysInfo.disk
        detail: `${SysInfo.format(SysInfo.diskUsed)} / ${SysInfo.format(SysInfo.diskTotal)}`
        trailing: root.percent(SysInfo.disk)
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2

        spacing: Config.spacing

        Text {
            Layout.preferredWidth: 20

            text: "\u{f06f3}"
            color: Config.fgDim

            font.family: Config.iconFont
            font.pixelSize: Config.fontSize + 3
        }

        Text {
            Layout.preferredWidth: 74

            text: "Network"
            color: Config.fg

            font.family: Config.font
            font.pixelSize: Config.fontSize
        }

        Text {
            text: "\u{f01da}"
            color: Config.accent

            font.family: Config.iconFont
            font.pixelSize: Config.fontSize + 2
        }

        Text {
            text: SysInfo.rate(SysInfo.down)
            color: Config.fg

            font.family: Config.font
            font.pixelSize: Config.fontSize - 1
        }

        Text {
            Layout.leftMargin: Config.spacing

            text: "\u{f0552}"
            color: Config.good

            font.family: Config.iconFont
            font.pixelSize: Config.fontSize + 2
        }

        Text {
            text: SysInfo.rate(SysInfo.up)
            color: Config.fg

            font.family: Config.font
            font.pixelSize: Config.fontSize - 1
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
