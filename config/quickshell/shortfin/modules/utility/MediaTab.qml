import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.services

RowLayout {
    id: root

    readonly property var player: Player.active
    readonly property bool has: !!player && !!player.trackTitle

    readonly property int line: Lyrics.indexAt(Player.position)

    readonly property var loopCycle: [MprisLoopState.None, MprisLoopState.Playlist, MprisLoopState.Track]

    function clock(seconds: real): string {
        if (!(seconds > 0))
            return "0:00";

        const total = Math.floor(seconds);
        return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`;
    }

    spacing: Config.spacing + 4

    ColumnLayout {
        Layout.preferredWidth: 300
        Layout.minimumWidth: 300
        Layout.maximumWidth: 300
        Layout.fillHeight: true

        spacing: Config.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacing

            ClippingRectangle {
                Layout.preferredWidth: 78
                Layout.preferredHeight: 78

                radius: Config.radius - 2
                color: Config.surface

                Image {
                    anchors.fill: parent

                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Text {
                    anchors.centerIn: parent

                    visible: !root.player?.trackArtUrl
                    text: "\u{f075a}"
                    color: Config.fgDim

                    font.family: Config.iconFont
                    font.pixelSize: 26
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 300 - 78 - Config.spacing
                spacing: 2

                Text {
                    Layout.fillWidth: true

                    text: root.has ? root.player.trackTitle : "Nothing playing"
                    color: Config.fg
                    elide: Text.ElideRight

                    font.family: Config.font
                    font.pixelSize: Config.fontSize + 2
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true

                    visible: root.has
                    text: root.player?.trackArtist ?? ""
                    color: Config.fgDim
                    elide: Text.ElideRight

                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                }

                Text {
                    Layout.fillWidth: true

                    visible: root.has && !!root.player.trackAlbum
                    text: root.player?.trackAlbum ?? ""
                    color: Qt.alpha(Config.fgDim, 0.7)
                    elide: Text.ElideRight

                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 1
                }

                Text {
                    Layout.fillWidth: true

                    visible: root.has
                    text: root.player?.identity ?? ""
                    color: Qt.alpha(Config.fgDim, 0.55)
                    elide: Text.ElideRight

                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 3
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2

            spacing: 4

            MouseArea {
                id: seek

                Layout.fillWidth: true
                Layout.preferredHeight: 14

                enabled: root.has && (root.player?.canSeek ?? false)
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: event => {
                    if (Player.length > 0)
                        root.player.position = Player.length * (event.x / width);
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6

                    radius: height / 2
                    color: Qt.alpha(Config.fgDim, 0.22)

                    Rectangle {
                        width: parent.width * (Player.length > 0 ? Math.max(0, Math.min(1, Player.position / Player.length)) : 0)
                        height: parent.height

                        radius: height / 2
                        color: seek.containsMouse ? Config.accentAlt : Config.accent
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.clock(Player.position)
                    color: Config.fgDim

                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 2
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.clock(Player.length)
                    color: Config.fgDim

                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 2
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2

            spacing: Config.spacing + 6

            Repeater {
                model: [
                    {
                        key: "shuffle",
                        size: 17
                    },
                    {
                        key: "previous",
                        size: 22
                    },
                    {
                        key: "toggle",
                        size: 34
                    },
                    {
                        key: "next",
                        size: 22
                    },
                    {
                        key: "loop",
                        size: 17
                    }
                ]

                Rectangle {
                    id: button

                    required property var modelData

                    readonly property bool primary: button.modelData.key === "toggle"

                    readonly property bool secondary: ["shuffle", "loop"].includes(button.modelData.key)

                    readonly property bool lit: {
                        if (button.modelData.key === "shuffle")
                            return root.player?.shuffle ?? false;

                        if (button.modelData.key === "loop")
                            return (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None;

                        return false;
                    }

                    readonly property string glyph: {
                        switch (button.modelData.key) {
                        case "shuffle":
                            return button.lit ? "\u{f049d}" : "\u{f049e}";
                        case "loop":
                            return (root.player?.loopState ?? MprisLoopState.None) === MprisLoopState.Track ? "\u{f0458}" : button.lit ? "\u{f0456}" : "\u{f0457}";
                        case "previous":
                            return "\u{f04ae}";
                        case "next":
                            return "\u{f04ad}";
                        default:
                            return root.player?.isPlaying ? "\u{f03e4}" : "\u{f040a}";
                        }
                    }

                    readonly property bool usable: {
                        if (!root.player)
                            return false;

                        switch (button.modelData.key) {
                        case "previous":
                            return root.player.canGoPrevious;
                        case "next":
                            return root.player.canGoNext;
                        case "shuffle":
                            return root.player.shuffleSupported;
                        case "loop":
                            return root.player.loopSupported;
                        default:
                            return root.player.canTogglePlaying;
                        }
                    }

                    implicitWidth: button.primary ? 42 : button.secondary ? 28 : 34
                    implicitHeight: button.primary ? 42 : button.secondary ? 28 : 34

                    radius: width / 2
                    color: button.primary ? Config.surface : press.containsMouse && button.usable ? Qt.alpha(Config.surface, 0.6) : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: button.glyph
                        color: !button.usable ? Qt.alpha(Config.fgDim, 0.4) : button.lit ? Config.accent : button.secondary ? (press.containsMouse ? Config.fg : Config.fgDim) : press.containsMouse || button.primary ? Config.accent : Config.fg

                        font.family: Config.iconFont
                        font.pixelSize: button.modelData.size
                    }

                    MouseArea {
                        id: press

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: button.usable ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: {
                            if (!button.usable)
                                return;

                            switch (button.modelData.key) {
                            case "previous":
                                root.player.previous();
                                break;
                            case "next":
                                root.player.next();
                                break;
                            case "shuffle":
                                root.player.shuffle = !root.player.shuffle;
                                break;
                            case "loop":
                                root.player.loopState = root.loopCycle[(root.loopCycle.indexOf(root.player.loopState) + 1) % root.loopCycle.length];
                                break;
                            default:
                                root.player.togglePlaying();
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true

        color: Qt.alpha(Config.fgDim, 0.25)
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Text {
            anchors.centerIn: parent

            visible: Lyrics.lines.length === 0
            text: !root.has ? "Nothing playing" : Lyrics.state === "loading" ? "Looking for lyrics…" : "No lyrics found"
            color: Qt.alpha(Config.fgDim, 0.7)

            font.family: Config.font
            font.pixelSize: Config.fontSize
        }

        ListView {
            id: view

            anchors.fill: parent

            visible: Lyrics.lines.length > 0
            model: Lyrics.lines
            clip: true
            spacing: 3

            currentIndex: root.line
            highlightRangeMode: Lyrics.synced ? ListView.StrictlyEnforceRange : ListView.NoHighlightRange
            preferredHighlightBegin: height / 2 - 20
            preferredHighlightEnd: height / 2 + 20
            highlightMoveDuration: Config.animDuration * 2

            delegate: Text {
                id: lyric

                required property var modelData
                required property int index

                readonly property bool current: Lyrics.synced && lyric.index === root.line

                width: view.width

                text: lyric.modelData.text
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignLeft

                color: !Lyrics.synced ? Config.fg : lyric.current ? Config.accentAlt : Qt.alpha(Config.fgDim, 0.75)

                font.family: Config.font
                font.pixelSize: Config.fontSize
                font.bold: lyric.current

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration
                    }
                }
            }
        }
    }
}
