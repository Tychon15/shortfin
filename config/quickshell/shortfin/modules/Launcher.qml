import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    id: root

    property bool open: false

    GlobalShortcut {
        appid: "shortfin"
        name: "launcher"
        description: "Toggle the application launcher"

        onReleased: root.open = !root.open
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

        mask: root.open ? null : panelRegion

        Region {
            id: panelRegion

            item: panel
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shortfin-launcher"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        property var usage: ({})

        readonly property var results: {
            const q = search.text.trim().toLowerCase();
            const usage = win.usage;
            const uses = a => usage[a.id] ?? 0;
            const all = DesktopEntries.applications.values.filter(a => !a.noDisplay);

            if (!q)
                return [...all].sort((a, b) => (uses(b) - uses(a)) || a.name.localeCompare(b.name)).slice(0, 50);

            const scored = [];
            for (const a of all) {
                const name = a.name.toLowerCase();
                let score = -1;

                if (name.startsWith(q))
                    score = 3;
                else if (name.includes(q))
                    score = 2;
                else if ((a.comment ?? "").toLowerCase().includes(q) || (a.id ?? "").toLowerCase().includes(q))
                    score = 1;

                if (score >= 0)
                    scored.push({
                        entry: a,
                        score: score
                    });
            }

            return scored.sort((x, y) => (y.score - x.score) || (uses(y.entry) - uses(x.entry)) || x.entry.name.localeCompare(y.entry.name)).map(x => x.entry).slice(0, 50);
        }

        function launch(entry: var): void {
            if (!entry)
                return;

            AppUsage.record(entry.id);
            entry.execute();
            root.open = false;
        }

        Connections {
            target: AppUsage

            function onCountsChanged(): void {
                if (!root.open)
                    win.usage = AppUsage.counts;
            }
        }

        Connections {
            target: root

            function onOpenChanged(): void {
                if (root.open) {
                    win.usage = AppUsage.counts;
                    search.text = "";
                    list.currentIndex = 0;
                    claimFocus.restart();
                }
            }
        }

        Timer {
            id: claimFocus

            interval: 120
            onTriggered: search.forceActiveFocus()
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.open
            onClicked: root.open = false
        }

        Rectangle {
            id: panel

            width: 560
            implicitHeight: body.implicitHeight + Config.padding * 2

            anchors.horizontalCenter: parent.horizontalCenter

            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.open ? -border.width : -height

            Behavior on anchors.bottomMargin {
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

            MouseArea {
                anchors.fill: parent
            }

            topLeftRadius: Config.radius + 4
            topRightRadius: Config.radius + 4
            bottomLeftRadius: 0
            bottomRightRadius: 0
            border.width: 1
            border.color: Qt.lighter(Config.bg, 1.8)

            clip: true

            ColumnLayout {
                id: body

                anchors.fill: parent
                anchors.margins: Config.padding
                spacing: Config.spacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Config.spacing

                    Text {
                        text: "\u{f0349}"
                        color: Config.accent

                        font.family: Config.iconFont
                        font.pixelSize: Config.fontSize + 6
                    }

                    TextInput {
                        id: search

                        Layout.fillWidth: true

                        focus: true
                        color: Config.fg
                        selectionColor: Config.accent
                        selectByMouse: true
                        clip: true

                        font.family: Config.font
                        font.pixelSize: Config.fontSize + 6

                        onTextChanged: list.currentIndex = 0

                        Keys.onEscapePressed: root.open = false
                        Keys.onReturnPressed: win.launch(win.results[list.currentIndex])
                        Keys.onEnterPressed: win.launch(win.results[list.currentIndex])

                        Keys.onUpPressed: if (list.currentIndex > 0)
                            list.currentIndex--

                        Keys.onDownPressed: if (list.currentIndex < win.results.length - 1)
                            list.currentIndex++

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            visible: !search.text
                            text: "Search applications"
                            color: Qt.alpha(Config.fgDim, 0.5)

                            font.family: Config.font
                            font.pixelSize: Config.fontSize + 6
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1

                    visible: win.results.length > 0
                    color: Qt.alpha(Config.fgDim, 0.3)
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34

                    visible: win.results.length === 0
                    text: "No matches"
                    color: Qt.alpha(Config.fgDim, 0.6)

                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                    verticalAlignment: Text.AlignVCenter
                }

                ListView {
                    id: list

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 7 * 44)

                    visible: win.results.length > 0
                    model: win.results
                    clip: true
                    currentIndex: 0
                    highlightMoveDuration: Config.animDuration
                    keyNavigationEnabled: false

                    delegate: Rectangle {
                        id: row

                        required property var modelData
                        required property int index

                        width: list.width
                        height: 44

                        radius: Config.radius - 2
                        color: list.currentIndex === index ? Config.surface : hover.containsMouse ? Qt.alpha(Config.surface, 0.5) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Config.spacing
                            anchors.rightMargin: Config.spacing
                            spacing: Config.spacing

                            IconImage {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28

                                source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                                asynchronous: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true

                                    text: row.modelData.name
                                    color: Config.fg
                                    elide: Text.ElideRight

                                    font.family: Config.font
                                    font.pixelSize: Config.fontSize
                                }

                                Text {
                                    Layout.fillWidth: true

                                    visible: row.modelData.comment
                                    text: row.modelData.comment ?? ""
                                    color: Config.fgDim
                                    elide: Text.ElideRight

                                    font.family: Config.font
                                    font.pixelSize: Config.fontSize - 2
                                }
                            }
                        }

                        MouseArea {
                            id: hover

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: list.currentIndex = row.index
                            onClicked: win.launch(row.modelData)
                        }
                    }
                }
            }
        }
    }
}
