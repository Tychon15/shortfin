pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.config

Scope {
    id: root

    property string buffer
    property string message
    property bool failed

    property bool settled

    property int stamp: 0
    property bool captured: false
    property int primed: 0

    function shotFor(name: string): string {
        return `${Quickshell.env("XDG_RUNTIME_DIR")}/shortfin-lock-${name}-${root.stamp}.png`;
    }

    function engage(): void {
        if (session.locked)
            return;

        root.buffer = "";
        root.message = "";
        root.failed = false;

        root.stamp++;
        root.captured = false;
        root.primed = 0;

        capture.command = ["sh", "-c", Quickshell.screens.map(screen => `grim -l 0 -o '${screen.name}' '${root.shotFor(screen.name)}'`).join("; ") + "; true"];
        capture.running = true;

        patience.restart();
    }

    Process {
        id: capture

        onExited: root.captured = true
    }

    Item {
        Repeater {
            model: Quickshell.screens

            Image {
                required property var modelData

                source: root.captured ? root.shotFor(modelData.name) : ""
                asynchronous: true
                cache: true
                visible: false

                onStatusChanged: {
                    if (status !== Image.Ready)
                        return;

                    root.primed++;
                    if (root.primed >= Quickshell.screens.length) {
                        patience.stop();
                        session.locked = true;
                    }
                }
            }
        }
    }

    Timer {
        id: patience

        interval: 500
        onTriggered: session.locked = true
    }

    Timer {
        id: begin

        interval: 16
        onTriggered: root.settled = true
    }

    function dismiss(): void {
        root.settled = false;

        release.restart();
    }

    Timer {
        id: release

        interval: Config.lockAnimOut
        onTriggered: {
            session.locked = false;
            root.buffer = "";
            root.message = "";
            root.failed = false;

            sweep.running = true;
        }
    }

    function key(event: var): void {

        if (pam.active)
            return;

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            pam.start();
        } else if (event.key === Qt.Key_Backspace) {
            root.buffer = event.modifiers & Qt.ControlModifier ? "" : root.buffer.slice(0, -1);
        } else if (event.key === Qt.Key_Escape) {
            root.buffer = "";
        } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {

            root.buffer += event.text;
            root.failed = false;
        }
    }

    GlobalShortcut {
        appid: "shortfin"
        name: "lock"
        description: "Lock the session"

        onReleased: root.engage()
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.engage();
        }

        function unlock(): void {
            root.dismiss();
        }

        function status(): string {
            return session.locked ? "locked" : "unlocked";
        }
    }

    Process {
        id: sentry

        running: true

        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=shortfin", "--why=Lock the screen before sleeping", "setpriv", "--pdeathsig=TERM", "gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]

        stdout: SplitParser {
            onRead: line => {
                if (!/PrepareForSleep|Session\.Lock/.test(line))
                    return;

                root.engage();

                recycle.restart();
            }
        }

        onExited: rearm.restart()
    }

    Timer {
        id: recycle

        interval: 200
        onTriggered: sentry.running = false
    }

    Timer {
        id: rearm

        interval: 400
        onTriggered: sentry.running = true
    }

    Process {
        id: sweep

        command: ["sh", "-c", `rm -f "$XDG_RUNTIME_DIR"/shortfin-lock-*.png`]
    }

    Component.onCompleted: sweep.running = true

    PamContext {
        id: pam

        config: "passwd"
        configDirectory: Quickshell.shellPath("assets/pam.d")

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;

            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.dismiss();
                return;
            }

            root.failed = true;
            root.buffer = "";
            root.message = result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password";
            forget.restart();
        }

        onError: () => {
            root.failed = true;
            root.buffer = "";
            root.message = "Authentication unavailable";
            forget.restart();
        }
    }

    Timer {
        id: forget

        interval: 4000
        onTriggered: root.message = ""
    }

    WlSessionLock {
        id: session

        WlSessionLockSurface {
            id: surface

            color: Config.bg

            Item {
                id: content

                anchors.fill: parent
                focus: true

                Keys.onPressed: event => root.key(event)

                Component.onCompleted: begin.restart()

                property real intro: root.settled ? 1 : 0

                Behavior on intro {
                    NumberAnimation {
                        duration: root.settled ? Config.lockAnimIn : Config.lockAnimOut
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Config.animCurve
                    }
                }

                readonly property real early: Math.min(1, content.intro * 1.25)
                readonly property real late: Math.max(0, Math.min(1, content.intro * 1.6 - 0.45))

                property real veil: root.settled ? 1 : 0

                Behavior on veil {
                    NumberAnimation {
                        duration: root.settled ? Config.lockAnimIn : Config.lockAnimOut
                        easing.type: Easing.InOutQuad
                    }
                }

                Image {
                    id: backdrop

                    anchors.fill: parent

                    source: surface.screen ? root.shotFor(surface.screen.name) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: false
                    cache: true

                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent

                    source: backdrop
                    autoPaddingEnabled: false

                    blurEnabled: true

                    blurMax: 48
                    blur: content.veil
                }

                Rectangle {
                    anchors.fill: parent

                    color: Config.bg
                    opacity: content.veil * 0.72
                }

                SystemClock {
                    id: clock

                    precision: SystemClock.Seconds
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter

                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Config.fg
                        opacity: content.early

                        font.family: Config.font
                        font.pixelSize: 96
                        font.bold: true

                        transform: Translate {
                            y: (1 - content.early) * 22
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 56

                        text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                        color: Config.fgDim
                        opacity: content.early

                        font.family: Config.font
                        font.pixelSize: Config.fontSize + 4

                        transform: Translate {
                            y: (1 - content.early) * 22
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 10

                        text: Quickshell.env("USER") ?? ""
                        color: Config.fgDim
                        opacity: content.late

                        font.family: Config.font
                        font.pixelSize: Config.fontSize + 1

                        transform: Translate {
                            y: (1 - content.late) * 14
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter

                        implicitWidth: 300
                        implicitHeight: 46

                        radius: height / 2
                        color: Qt.alpha(Config.surface, 0.7)
                        opacity: content.late

                        border.width: 1
                        border.color: root.failed ? Config.bad : pam.active ? Config.accent : Qt.alpha(Config.fgDim, 0.4)

                        transform: Translate {
                            y: (1 - content.late) * 14
                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Config.animDuration
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            visible: !pam.active && root.buffer.length === 0
                            text: "\u{f0341}"
                            color: Qt.alpha(Config.fgDim, 0.6)

                            font.family: Config.iconFont
                            font.pixelSize: Config.fontSize + 6
                        }

                        Text {
                            anchors.centerIn: parent

                            visible: pam.active
                            text: "Checking…"
                            color: Config.accent

                            font.family: Config.font
                            font.pixelSize: Config.fontSize
                        }

                        Item {
                            id: dots

                            anchors.fill: parent

                            readonly property int limit: 16
                            readonly property int shown: Math.min(root.buffer.length, dots.limit)
                            readonly property int size: 8
                            readonly property int gap: 7
                            readonly property real span: dots.shown * dots.size + Math.max(0, dots.shown - 1) * dots.gap

                            opacity: pam.active ? 0 : 1

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Config.animDuration
                                }
                            }

                            Repeater {
                                model: dots.limit

                                Rectangle {
                                    id: dot

                                    required property int index

                                    readonly property bool present: dot.index < dots.shown

                                    width: dots.size
                                    height: dots.size
                                    radius: dots.size / 2
                                    color: Config.fg

                                    x: (dots.width - dots.span) / 2 + dot.index * (dots.size + dots.gap)
                                    y: (dots.height - dots.size) / 2

                                    opacity: dot.present ? 1 : 0
                                    scale: dot.present ? 1 : 0

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.Bezier
                                            easing.bezierCurve: Config.animCurve
                                        }
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 180

                                            easing.type: dot.present ? Easing.OutBack : Easing.InQuad
                                        }
                                    }

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 140
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 12

                        text: root.message
                        color: Config.bad
                        opacity: root.message ? content.late : 0

                        font.family: Config.font
                        font.pixelSize: Config.fontSize

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Config.animDuration
                            }
                        }
                    }
                }
            }
        }
    }
}
