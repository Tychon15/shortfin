import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

RowLayout {
    id: root

    spacing: 8

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Text {
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
        visible: Config.showDate

        color: Config.fgDim
        font.family: Config.font
        font.pixelSize: Config.fontSize
    }

    Rectangle {
        visible: Config.showDate

        Layout.preferredWidth: 1
        Layout.preferredHeight: Config.fontSize
        color: Qt.alpha(Config.fgDim, 0.4)
    }

    Text {
        text: Qt.formatDateTime(clock.date, "HH:mm")

        color: Config.fg
        font.family: Config.font
        font.pixelSize: Config.fontSize
        font.bold: true
    }
}
