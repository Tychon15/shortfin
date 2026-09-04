import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "shortfin-wallpaper"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Config.bg

            mask: Region {}

            Image {
                id: outgoing

                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                cache: false
            }

            Image {
                id: incoming

                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false

                source: Wallpapers.shown
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.windowAnimOut
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Config.animCurve
                    }
                }

                onOpacityChanged: if (opacity === 1)
                    outgoing.source = incoming.source;
            }
        }
    }
}
