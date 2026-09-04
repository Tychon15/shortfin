import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.modules
import qs.services

Scope {

    Component.onCompleted: Deps.check()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "shortfin-bar"
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Config.barHeight + Config.barMargin * 2
            exclusiveZone: Config.barHeight + Config.barMargin

            Rectangle {
                anchors.fill: parent
                anchors.margins: Config.barMargin
                anchors.bottomMargin: 0

                color: Config.bg
                radius: Config.radius
                border.width: 1
                border.color: Qt.lighter(Config.bg, 1.6)

                RowLayout {
                    id: left

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Config.padding
                    spacing: Config.spacing

                    SpecialWorkspaces {
                        screen: win.modelData
                    }

                    Workspaces {
                        screen: win.modelData
                    }

                    ActiveWindow {
                        Layout.maximumWidth: 360
                    }
                }

                Clock {
                    id: clock

                    anchors.centerIn: parent
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Config.padding
                    spacing: Config.spacing

                    SysTray {
                        bar: win
                    }

                    StatusIcons {
                        bar: win
                    }

                    PowerButton {
                        bar: win
                    }
                }
            }
        }
    }
}
