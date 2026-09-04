import QtQuick
import qs.config

Rectangle {
    id: root

    property string glyph
    property color tint: Config.fgDim
    property color hoverTint: Config.accent

    signal activated

    implicitWidth: 22
    implicitHeight: 22
    radius: 6

    color: area.containsMouse ? Qt.alpha(root.hoverTint, 0.25) : "transparent"

    Text {
        anchors.centerIn: parent

        text: root.glyph
        color: area.containsMouse ? root.hoverTint : root.tint

        font.family: Config.iconFont
        font.pixelSize: Config.fontSize
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
