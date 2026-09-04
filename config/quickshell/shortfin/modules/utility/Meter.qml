import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string glyph
    property string label
    property real value: 0
    property string detail
    property string trailing

    readonly property color fill: value > 0.9 ? Config.bad : value > 0.75 ? Config.warn : Config.accent

    spacing: Config.spacing

    Text {
        Layout.preferredWidth: 20

        text: root.glyph
        color: Config.fgDim

        font.family: Config.iconFont
        font.pixelSize: Config.fontSize + 3
    }

    Text {
        Layout.preferredWidth: 74

        text: root.label
        color: Config.fg

        font.family: Config.font
        font.pixelSize: Config.fontSize
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 8

        radius: height / 2
        color: Qt.alpha(Config.fgDim, 0.22)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height

            radius: height / 2
            color: root.fill

            Behavior on width {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Config.animCurve
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Config.animDuration
                }
            }
        }
    }

    Text {
        Layout.preferredWidth: 116
        horizontalAlignment: Text.AlignRight

        text: root.detail
        color: Config.fgDim

        font.family: Config.font
        font.pixelSize: Config.fontSize - 1
    }

    Text {
        Layout.preferredWidth: 54
        horizontalAlignment: Text.AlignRight

        text: root.trailing
        color: Config.fgDim

        font.family: Config.font
        font.pixelSize: Config.fontSize - 1
    }
}
