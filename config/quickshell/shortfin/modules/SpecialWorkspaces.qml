import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

Item {
    id: root

    required property var screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property string shown: Hypr.shownSpecial(monitor)
    readonly property bool active: shown.startsWith("special:")

    property string lastShown
    onShownChanged: if (shown.startsWith("special:")) lastShown = shown

    readonly property string shortName: lastShown.slice(8)

    readonly property var icons: Options.obj("specialIcons", {
        "music": "\u{f0387}",
        "communication": "\u{f0b79}",
        "sysmon": "\u{f035b}",
        "todo": "\u{f0c18}",
        "special": "\u{f0328}"
    })

    implicitWidth: active ? row.implicitWidth : 0
    implicitHeight: Config.barHeight
    clip: true

    visible: implicitWidth > 0

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.Bezier
            easing.bezierCurve: Config.animCurve
        }
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Rectangle {
            implicitWidth: 22
            implicitHeight: 18
            radius: 6

            color: Config.accent

            Text {
                anchors.centerIn: parent

                text: root.icons[root.shortName] ?? "\u{f0614}"
                color: Config.bg

                font.family: Config.iconFont
                font.pixelSize: Config.fontSize
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.toggleSpecial(root.shortName)
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: Config.fontSize
            color: Qt.alpha(Config.fgDim, 0.4)
        }
    }
}
