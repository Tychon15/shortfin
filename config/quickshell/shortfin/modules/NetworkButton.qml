import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config

Item {
    id: root

    required property var bar

    property var wired: []

    property var networks: []
    property string radio: "enabled"

    property string passwordFor: ""
    property string passwordError: ""

    property var savedWifi: ({})

    readonly property string kind: wired.some(w => w.active) ? "ethernet" : networks.some(n => n.active) ? "wifi" : "none"

    function fields(line: string): var {
        const out = [];
        let cur = "";

        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length)
                cur += line[++i];
            else if (c === ":") {
                out.push(cur);
                cur = "";
            } else
                cur += c;
        }

        out.push(cur);
        return out;
    }

    function strengthIcon(signal: int): string {
        if (signal >= 75)
            return "\u{f0928}";
        if (signal >= 50)
            return "\u{f0925}";
        if (signal >= 25)
            return "\u{f0922}";
        return "\u{f091f}";
    }

    function refresh(): void {
        if (!connProc.running)
            connProc.running = true;
        if (!radioProc.running)
            radioProc.running = true;
        if (!wifiProc.running)
            wifiProc.running = true;
    }

    function run(argv: var): void {
        if (actionProc.running)
            return;

        actionProc.command = argv;
        actionProc.running = true;
    }

    function toggleWired(entry: var): void {
        run(entry.active ? ["nmcli", "connection", "down", "uuid", entry.uuid] : ["nmcli", "connection", "up", "uuid", entry.uuid]);
    }

    function wifiDisconnect(entry: var): void {
        run(["nmcli", "connection", "down", "uuid", entry.uuid]);
    }

    function wifiForget(entry: var): void {
        run(["nmcli", "connection", "delete", "uuid", entry.uuid]);
    }

    function wifiActivate(entry: var): void {
        if (entry.saved)
            run(["nmcli", "connection", "up", "uuid", entry.uuid]);
        else if (entry.secured)
            passwordFor = entry.ssid;
        else
            run(["nmcli", "device", "wifi", "connect", entry.ssid]);
    }

    function toggleRadio(): void {
        run(["nmcli", "radio", "wifi", radio === "enabled" ? "off" : "on"]);
    }

    function submitPassword(ssid: string, password: string): void {
        passwordError = "";
        run(["nmcli", "device", "wifi", "connect", ssid, "password", password]);
    }

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Process {
        id: connProc

        running: true
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,ACTIVE", "connection", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const saved = {};

                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;

                    const f = root.fields(line);
                    const entry = {
                        name: f[0],
                        uuid: f[1],
                        active: f[3] === "yes"
                    };

                    if (f[2] === "802-3-ethernet")
                        rows.push(entry);
                    else if (f[2] === "802-11-wireless")
                        saved[f[0]] = entry;
                }

                root.wired = rows;
                root.savedWifi = saved;
                wifiProc.running = true;
            }
        }
    }

    Process {
        id: radioProc

        running: true
        command: ["nmcli", "-t", "radio", "wifi"]

        stdout: StdioCollector {
            onStreamFinished: root.radio = text.trim()
        }
    }

    Process {
        id: wifiProc

        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]

        stdout: StdioCollector {
            onStreamFinished: {
                const best = {};

                for (const line of text.trim().split("\n")) {
                    if (!line)
                        continue;

                    const f = root.fields(line);
                    const ssid = f[1];
                    if (!ssid)
                        continue;

                    const profile = root.savedWifi[ssid];
                    const entry = {
                        ssid: ssid,
                        signal: parseInt(f[2]) || 0,
                        secured: (f[3] ?? "").trim() !== "",
                        active: f[0] === "*",
                        saved: profile !== undefined,
                        uuid: profile?.uuid ?? ""
                    };

                    if (!best[ssid] || entry.active || entry.signal > best[ssid].signal)
                        best[ssid] = entry;
                }

                root.networks = Object.values(best).sort((a, b) => (b.active - a.active) || (b.signal - a.signal)).slice(0, 8);
            }
        }
    }

    Process {
        id: actionProc

        stderr: StdioCollector {}

        onExited: code => {
            if (code !== 0 && root.passwordFor)
                root.passwordError = stderr.text.trim().split("\n").pop() || "Connection failed";
            else
                root.passwordFor = "";

            refreshDelay.restart();
        }
    }

    Timer {
        id: refreshDelay

        interval: 900
        onTriggered: root.refresh()
    }

    Timer {
        interval: 5000
        running: menu.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Text {
        id: icon

        anchors.centerIn: parent

        text: root.kind === "wifi" ? "\u{f05a9}" : root.kind === "ethernet" ? "\u{f0200}" : "\u{f05aa}"
        color: menu.visible ? Config.accent : root.kind === "none" ? Config.fgDim : Config.fg

        font.family: Config.iconFont
        font.pixelSize: Config.fontSize + 2
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (menu.visible)
                root.passwordFor = "";
            menu.visible = !menu.visible;
        }
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
                root.passwordFor = "";
            }
        }
    }

    HyprlandFocusGrab {
        active: menu.visible && root.grabArmed && !root.passwordFor
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

        implicitWidth: 300
        implicitHeight: column.implicitHeight + Config.spacing
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shortfin-network"
        WlrLayershell.keyboardFocus: root.passwordFor ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
                    Layout.bottomMargin: 2

                    text: "Wired"
                    color: Config.fgDim

                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 1
                }

                Text {
                    Layout.leftMargin: Config.padding
                    Layout.preferredHeight: 26

                    visible: root.wired.length === 0
                    text: "No wired profiles"
                    color: Qt.alpha(Config.fgDim, 0.6)

                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                    verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    model: root.wired

                    Rectangle {
                        id: wiredRow

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 30

                        radius: Config.radius - 4
                        color: modelData.active ? Config.surface : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Config.padding
                            anchors.rightMargin: Config.spacing / 2
                            spacing: Config.spacing

                            Text {
                                text: "\u{f0200}"
                                color: wiredRow.modelData.active ? Config.good : Config.fgDim

                                font.family: Config.iconFont
                                font.pixelSize: Config.fontSize + 2
                            }

                            Text {
                                Layout.fillWidth: true

                                text: wiredRow.modelData.name
                                color: wiredRow.modelData.active ? Config.fg : Config.fgDim
                                elide: Text.ElideRight

                                font.family: Config.font
                                font.pixelSize: Config.fontSize
                            }

                            IconButton {
                                glyph: wiredRow.modelData.active ? "\u{f0337}" : "\u{f0338}"
                                tint: wiredRow.modelData.active ? Config.accent : Config.fgDim
                                onActivated: root.toggleWired(wiredRow.modelData)
                            }
                        }
                    }
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

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Config.padding
                    Layout.rightMargin: Config.spacing / 2
                    Layout.bottomMargin: 2

                    Text {
                        Layout.fillWidth: true

                        text: "Wi-Fi"
                        color: Config.fgDim

                        font.family: Config.font
                        font.pixelSize: Config.fontSize - 1
                    }

                    IconButton {
                        glyph: root.radio === "enabled" ? "\u{f05a9}" : "\u{f05aa}"
                        tint: root.radio === "enabled" ? Config.accent : Config.fgDim
                        onActivated: root.toggleRadio()
                    }
                }

                Text {
                    Layout.leftMargin: Config.padding
                    Layout.preferredHeight: 26

                    visible: root.radio !== "enabled" || root.networks.length === 0
                    text: root.radio !== "enabled" ? "Wi-Fi is off" : "No networks found"
                    color: Qt.alpha(Config.fgDim, 0.6)

                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                    verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    model: root.radio === "enabled" ? root.networks : []

                    ColumnLayout {
                        id: wifiEntry

                        required property var modelData

                        readonly property bool prompting: root.passwordFor === modelData.ssid

                        Layout.fillWidth: true
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30

                            radius: Config.radius - 4
                            color: wifiEntry.modelData.active ? Config.surface : join.containsMouse ? Qt.alpha(Config.surface, 0.5) : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Config.padding
                                anchors.rightMargin: Config.spacing / 2
                                spacing: Config.spacing

                                Text {
                                    text: root.strengthIcon(wifiEntry.modelData.signal)
                                    color: wifiEntry.modelData.active ? Config.accent : Config.fgDim

                                    font.family: Config.iconFont
                                    font.pixelSize: Config.fontSize + 2
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: wifiEntry.modelData.ssid
                                    color: wifiEntry.modelData.active ? Config.fg : Config.fgDim
                                    elide: Text.ElideRight

                                    font.family: Config.font
                                    font.pixelSize: Config.fontSize
                                }

                                Text {
                                    Layout.preferredWidth: 22

                                    text: "\u{f033e}"
                                    visible: wifiEntry.modelData.secured && !wifiEntry.modelData.saved
                                    color: Qt.alpha(Config.fgDim, 0.7)
                                    horizontalAlignment: Text.AlignHCenter

                                    font.family: Config.iconFont
                                    font.pixelSize: Config.fontSize - 1
                                }

                                IconButton {
                                    glyph: "\u{f0337}"
                                    tint: Config.accent
                                    visible: wifiEntry.modelData.active
                                    onActivated: root.wifiDisconnect(wifiEntry.modelData)
                                }

                                IconButton {
                                    glyph: "\u{f0a7a}"
                                    tint: Config.fgDim
                                    hoverTint: Config.bad
                                    visible: wifiEntry.modelData.saved
                                    onActivated: root.wifiForget(wifiEntry.modelData)
                                }
                            }

                            MouseArea {
                                id: join

                                anchors.fill: parent
                                anchors.rightMargin: 56
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (!wifiEntry.modelData.active) root.wifiActivate(wifiEntry.modelData)
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: wifiEntry.prompting ? (root.passwordError ? 56 : 36) : 0
                            Layout.leftMargin: Config.padding
                            Layout.rightMargin: Config.spacing / 2

                            visible: wifiEntry.prompting
                            color: "transparent"

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Config.spacing

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 26

                                        radius: 6
                                        color: Config.bg
                                        border.width: 1
                                        border.color: field.activeFocus ? Config.accent : Qt.alpha(Config.fgDim, 0.4)

                                        TextInput {
                                            id: field

                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8

                                            focus: true
                                            echoMode: TextInput.Password
                                            color: Config.fg
                                            selectionColor: Config.accent
                                            selectByMouse: true
                                            clip: true

                                            font.family: Config.font
                                            font.pixelSize: Config.fontSize
                                            verticalAlignment: TextInput.AlignVCenter

                                            onAccepted: root.submitPassword(wifiEntry.modelData.ssid, text)

                                            Keys.onEscapePressed: root.passwordFor = ""

                                            Timer {
                                                id: claimFocus

                                                interval: 120
                                                onTriggered: field.forceActiveFocus()
                                            }

                                            Connections {
                                                target: wifiEntry

                                                function onPromptingChanged(): void {
                                                    if (wifiEntry.prompting) {
                                                        field.text = "";
                                                        claimFocus.restart();
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter

                                                visible: !field.text
                                                text: "Password"
                                                color: Qt.alpha(Config.fgDim, 0.5)

                                                font.family: Config.font
                                                font.pixelSize: Config.fontSize
                                            }
                                        }
                                    }

                                    IconButton {
                                        glyph: "\u{f0338}"
                                        tint: Config.accent
                                        onActivated: root.submitPassword(wifiEntry.modelData.ssid, field.text)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true

                                    visible: root.passwordError
                                    text: root.passwordError
                                    color: Config.bad
                                    elide: Text.ElideRight

                                    font.family: Config.font
                                    font.pixelSize: Config.fontSize - 2
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
