import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    id: root

    property bool open: false

    readonly property int thumbWidth: 196
    readonly property int thumbHeight: 110
    readonly property int barHeight: 168

    function step(delta: int): void {
        const next = strip.currentIndex + delta;
        if (next >= 0 && next < Wallpapers.files.length)
            strip.currentIndex = next;
    }

    function preview(): void {
        Wallpapers.preview = Wallpapers.files[strip.currentIndex] ?? "";
    }

    function choose(): void {

        settle.stop();
        root.preview();

        Wallpapers.commit();
        root.open = false;
    }

    function dismiss(): void {

        settle.stop();

        Wallpapers.revert();
        root.open = false;
    }

    Timer {
        id: settle

        interval: 200
        onTriggered: root.preview()
    }

    GlobalShortcut {
        appid: "shortfin"
        name: "wallpaper"
        description: "Toggle the wallpaper picker"

        onReleased: {
            if (root.open)
                root.dismiss();
            else
                root.open = true;
        }
    }

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

        mask: root.open ? null : shut

        Region {
            id: shut

            width: 0
            height: 0
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shortfin-wallpaper-picker"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Connections {
            target: root

            function onOpenChanged(): void {
                if (!root.open)
                    return;

                strip.currentIndex = Math.max(0, Wallpapers.indexOf(Wallpapers.current));
                strip.positionViewAtIndex(strip.currentIndex, ListView.Center);
                claimFocus.restart();
            }
        }

        Timer {
            id: claimFocus

            interval: 120
            onTriggered: keys.forceActiveFocus()
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.open
            onClicked: root.dismiss()
        }

        Item {
            id: bar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            height: root.open ? root.barHeight : 0
            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: root.open ? Config.windowAnimIn : Config.windowAnimOut
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Config.animCurve
                }
            }

            Rectangle {
                anchors.fill: parent

                color: Qt.alpha(Config.bg, 0.92)

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Qt.lighter(Config.bg, 1.8)
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Qt.lighter(Config.bg, 1.8)
                }

                MouseArea {
                    anchors.fill: parent
                    onWheel: event => root.step(event.angleDelta.y > 0 ? -1 : 1)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: Config.spacing
                    anchors.bottomMargin: Config.spacing

                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignHCenter

                        text: {
                            const path = Wallpapers.files[strip.currentIndex] ?? "";
                            return path.slice(path.lastIndexOf("/") + 1);
                        }

                        color: Config.fgDim
                        elide: Text.ElideMiddle

                        font.family: Config.font
                        font.pixelSize: Config.fontSize - 1
                    }

                    ListView {
                        id: strip

                        Layout.fillWidth: true
                        Layout.preferredHeight: root.thumbHeight + 8

                        orientation: ListView.Horizontal
                        model: Wallpapers.files
                        spacing: 10
                        clip: true

                        highlightRangeMode: ListView.StrictlyEnforceRange
                        preferredHighlightBegin: (width - root.thumbWidth) / 2
                        preferredHighlightEnd: (width + root.thumbWidth) / 2
                        highlightMoveDuration: Config.animDuration * 2

                        leftMargin: (width - root.thumbWidth) / 2
                        rightMargin: (width - root.thumbWidth) / 2

                        onCurrentIndexChanged: if (root.open)
                            settle.restart();

                        delegate: Rectangle {
                            id: card

                            required property string modelData
                            required property int index

                            readonly property bool selected: strip.currentIndex === card.index

                            width: root.thumbWidth
                            height: root.thumbHeight
                            anchors.verticalCenter: parent?.verticalCenter ?? undefined

                            radius: Config.radius - 4
                            color: Config.surface

                            border.width: card.selected ? 2 : 1
                            border.color: card.selected ? Config.accent : Qt.alpha(Config.fgDim, 0.3)

                            opacity: card.selected ? 1 : 0.55

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Config.animDuration
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: Config.animDuration
                                }
                            }

                            Image {
                                anchors.fill: parent
                                anchors.margins: card.border.width

                                source: card.modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                clip: true

                                sourceSize.height: root.thumbHeight * 2
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    strip.currentIndex = card.index;
                                    root.choose();
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: keys

            focus: true

            Keys.onLeftPressed: root.step(-1)
            Keys.onRightPressed: root.step(1)
            Keys.onUpPressed: root.step(-1)
            Keys.onDownPressed: root.step(1)

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Home) {
                    strip.currentIndex = 0;
                    event.accepted = true;
                } else if (event.key === Qt.Key_End) {
                    strip.currentIndex = Wallpapers.files.length - 1;
                    event.accepted = true;
                }
            }

            Keys.onEscapePressed: root.dismiss()
            Keys.onReturnPressed: root.choose()
            Keys.onEnterPressed: root.choose()
        }
    }
}
