import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

MouseArea {
    id: root

    required property var screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1

    readonly property var ids: {
        const set = {};
        for (let i = 1; i <= Config.workspaceCount; i++)
            set[i] = true;

        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0 && ws.monitor === monitor)
                set[ws.id] = true;
        }

        return Object.keys(set).map(k => parseInt(k)).sort((a, b) => a - b);
    }

    function occupied(id: int): bool {
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id === id)
                return (ws.lastIpcObject?.windows ?? 0) > 0;
        }
        return false;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Config.barHeight

    acceptedButtons: Qt.NoButton
    onWheel: event => Hypr.focusRelative(event.angleDelta.y > 0 ? -1 : 1)

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.ids

            Rectangle {
                id: pill

                required property int modelData

                readonly property bool active: modelData === root.activeId
                readonly property bool busy: root.occupied(modelData)

                implicitWidth: active ? 26 : 12
                implicitHeight: 12
                radius: height / 2

                color: active ? Config.accent : busy ? Config.surface : Qt.alpha(Config.fgDim, 0.35)

                Behavior on implicitWidth {
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

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hypr.focus(`${pill.modelData}`)
                }
            }
        }
    }
}
