import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.config

Item {
    id: root

    required property var bar

    readonly property var dev: UPower.displayDevice
    readonly property real pct: (dev?.percentage ?? 0) * 100
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging || dev?.state === UPowerDeviceState.FullyCharged

    property string profile: ""

    readonly property var profiles: [
        {
            key: "power-saver",
            label: "Power saver",
            icon: "\u{f032a}"
        },
        {
            key: "balanced",
            label: "Balanced",
            icon: "\u{f05d1}"
        },
        {
            key: "performance",
            label: "Performance",
            icon: "\u{f04c5}"
        }
    ]

    function duration(seconds: int): string {
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        return h > 0 ? `${h} h ${m} min` : `${m} min`;
    }

    readonly property string statusLine: {
        if (!dev)
            return "No battery";

        switch (dev.state) {
        case UPowerDeviceState.Charging:
            return dev.timeToFull > 0 ? `${duration(dev.timeToFull)} until full` : "Charging";
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.Discharging:
            return dev.timeToEmpty > 0 ? `${duration(dev.timeToEmpty)} remaining` : "Estimating…";
        case UPowerDeviceState.PendingCharge:
            return "Plugged in, not charging";
        default:
            return "Estimating…";
        }
    }

    function apply(key: string): void {
        if (setProc.running)
            return;

        profile = key;
        setProc.command = ["busctl", "--system", "set-property", "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile", "s", key];
        setProc.running = true;
    }

    visible: dev?.isLaptopBattery ?? false

    implicitWidth: readout.implicitWidth
    implicitHeight: readout.implicitHeight

    Process {
        id: readProc

        running: true
        command: ["busctl", "--system", "get-property", "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile"]

        stdout: StdioCollector {
            onStreamFinished: root.profile = text.replace(/^s\s*/, "").replace(/"/g, "").trim()
        }
    }

    Process {
        id: setProc
    }

    Process {
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "net.hadess.PowerProfiles", "--object-path", "/net/hadess/PowerProfiles"]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                const match = data.match(/'ActiveProfile':\s*<'([^']+)'>/);
                if (match)
                    root.profile = match[1];
            }
        }
    }

    RowLayout {
        id: readout

        anchors.centerIn: parent
        spacing: 6

        Text {
            readonly property var levels: ["\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}", "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]

            text: root.charging ? "\u{f0084}" : levels[Math.min(9, Math.max(0, Math.floor(root.pct / 10)))]
            color: root.charging ? Config.good : root.pct <= 15 ? Config.bad : root.pct <= 30 ? Config.warn : Config.fg

            font.family: Config.iconFont
            font.pixelSize: Config.fontSize + 2
        }

        Text {
            text: `${Math.round(root.pct)}%`
            color: menu.visible ? Config.accent : Config.fgDim

            font.family: Config.font
            font.pixelSize: Config.fontSize
        }
    }

    MouseArea {
        anchors.fill: parent
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

        implicitWidth: 208
        implicitHeight: column.implicitHeight + Config.spacing
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shortfin-battery"
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

                Text {
                    Layout.leftMargin: Config.padding
                    Layout.topMargin: Config.spacing / 2

                    text: `${Math.round(root.pct)}%`
                    color: Config.fg

                    font.family: Config.font
                    font.pixelSize: Config.fontSize + 6
                    font.bold: true
                }

                Text {
                    Layout.leftMargin: Config.padding
                    Layout.bottomMargin: Config.spacing / 2

                    text: root.statusLine
                    color: Config.fgDim

                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: Config.padding
                    Layout.rightMargin: Config.padding
                    Layout.topMargin: Config.spacing / 2
                    Layout.bottomMargin: Config.spacing / 2
                    Layout.preferredHeight: 1

                    color: Qt.alpha(Config.fgDim, 0.3)
                }

                Repeater {
                    model: root.profiles

                    Rectangle {
                        id: entry

                        required property var modelData

                        readonly property bool current: modelData.key === root.profile

                        Layout.fillWidth: true
                        Layout.preferredHeight: 30

                        radius: Config.radius - 4
                        color: current ? Config.surface : hover.containsMouse ? Qt.alpha(Config.surface, 0.5) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Config.padding
                            anchors.rightMargin: Config.padding
                            spacing: Config.spacing

                            Text {
                                text: entry.modelData.icon
                                color: entry.current ? Config.accent : Config.fgDim

                                font.family: Config.iconFont
                                font.pixelSize: Config.fontSize + 2
                            }

                            Text {
                                Layout.fillWidth: true

                                text: entry.modelData.label
                                color: entry.current ? Config.fg : Config.fgDim

                                font.family: Config.font
                                font.pixelSize: Config.fontSize
                            }

                            Text {
                                text: "\u{f012c}"
                                visible: entry.current
                                color: Config.accent

                                font.family: Config.iconFont
                                font.pixelSize: Config.fontSize
                            }
                        }

                        MouseArea {
                            id: hover

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.apply(entry.modelData.key)
                        }
                    }
                }
            }
        }
    }
}
