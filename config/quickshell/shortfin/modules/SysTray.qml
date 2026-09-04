import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config

RowLayout {
    id: root

    required property var bar

    spacing: 6

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: entry

            required property SystemTrayItem modelData

            implicitWidth: 18
            implicitHeight: 18

            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: event => {
                if (event.button === Qt.LeftButton)
                    modelData.activate();
                else if (event.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else if (modelData.hasMenu)
                    menu.open();
            }

            onWheel: event => modelData.scroll(event.angleDelta.x, event.angleDelta.y)

            QsMenuAnchor {
                id: menu

                menu: entry.modelData.menu
                anchor.item: entry
                anchor.edges: Edges.Bottom
            }

            IconImage {
                anchors.fill: parent
                source: entry.modelData.icon
                asynchronous: true
                opacity: entry.containsMouse ? 1 : 0.85
            }

            hoverEnabled: true
        }
    }

    Rectangle {
        visible: SystemTray.items.values.length > 0

        Layout.preferredWidth: 1
        Layout.preferredHeight: Config.fontSize
        color: Qt.alpha(Config.fgDim, 0.4)
    }
}
