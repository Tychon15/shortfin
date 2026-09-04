import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

Item {
    id: root

    required property var bar

    readonly property var actions: [
        {
            key: "logout",
            label: "Log out",
            icon: "\u{f0343}",
            probe: ""
        },
        {
            key: "shutdown",
            label: "Shut down",
            icon: "\u{f0425}",
            probe: "CanPowerOff"
        },
        {
            key: "reboot",
            label: "Restart",
            icon: "\u{f0709}",
            probe: "CanReboot"
        },
        {
            key: "sleep",
            label: "Sleep",
            icon: "\u{f0594}",
            probe: "CanSuspend"
        }
    ]

    property var capabilities: ({})

    function enabled(probe: string): bool {
        return probe === "" || capabilities[probe] === "yes" || capabilities[probe] === "challenge";
    }

    function run(key: string): void {
        session.command = Config.sessionCommands[key];
        session.running = true;
        menu.visible = false;
    }

    implicitWidth: 20
    implicitHeight: 20

    Process {
        id: session
    }

    Process {
        running: true
        command: ["sh", "-c", "for m in CanSuspend CanPowerOff CanReboot; do printf %s= $m; busctl --system call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager $m 2>/dev/null; done"]

        stdout: StdioCollector {
            onStreamFinished: {
                const caps = {};
                for (const line of text.trim().split("\n")) {
                    const [name, value] = line.split("=");

                    if (name)
                        caps[name] = (value ?? "").replace(/^s\s*/, "").replace(/"/g, "").trim();
                }
                root.capabilities = caps;
            }
        }
    }

    Text {
        id: icon

        anchors.centerIn: parent

        text: "\u{f0425}"
        color: menu.visible || tap.containsMouse ? Config.accent : Config.fg

        font.family: Config.iconFont
        font.pixelSize: Config.fontSize + 3

        Behavior on color {
            ColorAnimation {
                duration: Config.animDuration
            }
        }
    }

    MouseArea {
        id: tap

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: menu.visible = !menu.visible
    }

    property bool grabArmed: false

    Timer {
        id: armGrab

        interval: 150
        onTriggered: root.grabArmed = true
    }

    Connections {
        target: menu

        function onVisibleChanged(): void {
            if (menu.visible) {
                armGrab.restart();
            } else {
                armGrab.stop();
                root.grabArmed = false;
            }
        }
    }

    Connections {
        target: Session

        function onToggle(): void {
            if (Hyprland.focusedMonitor?.name === root.bar.screen?.name)
                menu.visible = !menu.visible;
        }
    }

    HyprlandFocusGrab {
        active: menu.visible && root.grabArmed
        windows: [root.bar, menu]
        onCleared: menu.visible = false
    }

    PanelWindow {
        id: menu

        visible: false
        screen: root.bar.screen

        anchors {
            top: true
            right: true
        }

        margins.top: root.bar.height
        margins.right: root.bar.width - (root.mapToItem(null, 0, 0).x + root.width)

        implicitWidth: 176
        implicitHeight: column.implicitHeight + Config.spacing
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shortfin-power"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent

            color: Config.bgAlt
            radius: Config.radius
            border.width: 1
            border.color: Qt.lighter(Config.bgAlt, 1.6)

            ColumnLayout {
                id: column

                anchors.fill: parent
                anchors.margins: Config.spacing / 2
                spacing: 0

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: entry

                        required property var modelData

                        readonly property bool usable: root.enabled(modelData.probe)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 30

                        radius: Config.radius - 4
                        color: hover.containsMouse && usable ? Config.surface : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Config.padding
                            anchors.rightMargin: Config.padding
                            spacing: Config.spacing

                            Text {
                                text: entry.modelData.icon
                                color: entry.usable ? Config.fg : Qt.alpha(Config.fgDim, 0.5)

                                font.family: Config.iconFont
                                font.pixelSize: Config.fontSize + 2
                            }

                            Text {
                                Layout.fillWidth: true

                                text: entry.modelData.label
                                color: entry.usable ? Config.fg : Qt.alpha(Config.fgDim, 0.5)

                                font.family: Config.font
                                font.pixelSize: Config.fontSize
                            }
                        }

                        MouseArea {
                            id: hover

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: entry.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (entry.usable) root.run(entry.modelData.key)
                        }
                    }
                }
            }
        }
    }
}
