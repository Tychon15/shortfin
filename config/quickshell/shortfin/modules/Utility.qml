import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.modules.utility

Scope {
    id: root

    property bool open: false
    property int tab: 0

    readonly property var tabs: [
        {
            label: "Media",
            icon: "\u{f075a}"
        },
        {
            label: "Performance",
            icon: "\u{f04c5}"
        },
        {
            label: "Weather",
            icon: "\u{f0595}"
        }
    ]

    Binding {
        target: SysInfo
        property: "active"
        value: root.open && root.tab === 1
    }

    Binding {
        target: Player
        property: "tracking"
        value: root.open && root.tab === 0
    }

    onOpenChanged: if (open)
        Weather.refresh()

    PanelWindow {
        id: win

        visible: true
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: root.open ? null : edgeRegion

        Region {
            id: edgeRegion

            item: hotEdge
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shortfin-utility"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: hotEdge

            height: 2
            width: panel.width
            x: panel.x
            y: parent.height - height

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: if (!Hypr.fullscreen)
                    dwell.restart()
                onExited: dwell.stop()
            }
        }

        Timer {
            id: dwell

            interval: 150
            onTriggered: root.open = true
        }

        MouseArea {
            id: away

            anchors.fill: parent
            enabled: root.open
            hoverEnabled: true

            onClicked: root.open = false
            onContainsMouseChanged: if (containsMouse)
                leave.restart();
            else
                leave.stop()
        }

        Timer {
            id: leave

            interval: 400
            onTriggered: root.open = false
        }

        Rectangle {
            id: panel

            width: 780
            implicitHeight: body.implicitHeight + Config.padding * 2

            x: (parent.width - width) / 2

            y: root.open ? parent.height - height + border.width : parent.height

            Behavior on y {
                NumberAnimation {
                    duration: root.open ? Config.windowAnimIn : Config.windowAnimOut
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Config.animCurve
                }
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Config.windowAnimOut
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Config.animCurve
                }
            }

            color: Config.bg
            border.width: 1
            border.color: Qt.lighter(Config.bg, 1.8)

            topLeftRadius: Config.radius + 4
            topRightRadius: Config.radius + 4
            bottomLeftRadius: 0
            bottomRightRadius: 0

            clip: true

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
            }

            ColumnLayout {
                id: body

                anchors.fill: parent
                anchors.margins: Config.padding
                spacing: Config.spacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: root.tabs

                        Rectangle {
                            id: chip

                            required property var modelData
                            required property int index

                            readonly property bool current: root.tab === chip.index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 30

                            radius: Config.radius - 4
                            color: chip.current ? Config.surface : pick.containsMouse ? Qt.alpha(Config.surface, 0.5) : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: chip.modelData.icon
                                    color: chip.current ? Config.accent : Config.fgDim

                                    font.family: Config.iconFont
                                    font.pixelSize: Config.fontSize + 2
                                }

                                Text {
                                    text: chip.modelData.label
                                    color: chip.current ? Config.fg : Config.fgDim

                                    font.family: Config.font
                                    font.pixelSize: Config.fontSize
                                }
                            }

                            MouseArea {
                                id: pick

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.tab = chip.index
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1

                    color: Qt.alpha(Config.fgDim, 0.3)
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(media.implicitHeight, performance.implicitHeight, weather.implicitHeight)

                    currentIndex: root.tab

                    MediaTab {
                        id: media
                    }

                    PerformanceTab {
                        id: performance
                    }

                    WeatherTab {
                        id: weather
                    }
                }
            }
        }
    }
}
