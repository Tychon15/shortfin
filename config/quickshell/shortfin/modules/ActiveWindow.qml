import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

Item {
    id: root

    readonly property Toplevel active: ToplevelManager.activeToplevel

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    opacity: active ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.Bezier
            easing.bezierCurve: Config.animCurve
        }
    }

    Text {
        id: label

        anchors.fill: parent

        text: root.active?.title ?? ""
        elide: Text.ElideRight

        color: Config.fgDim
        font.family: Config.font
        font.pixelSize: Config.fontSize
        verticalAlignment: Text.AlignVCenter
    }
}
