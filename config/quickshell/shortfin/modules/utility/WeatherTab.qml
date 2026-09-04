import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

ColumnLayout {
    id: root

    readonly property var today: Weather.describe(Weather.code)

    function day(date: string, index: int): string {
        if (index === 0)
            return "Today";

        const parts = date.split("-").map(Number);
        return Qt.formatDate(new Date(parts[0], parts[1] - 1, parts[2]), "ddd");
    }

    spacing: Config.spacing

    RowLayout {
        Layout.fillWidth: true
        spacing: Config.spacing + 4

        Text {
            text: root.today.glyph
            color: Config.accentAlt
            visible: Weather.state === "ok"

            font.family: Config.iconFont
            font.pixelSize: 52
        }

        ColumnLayout {
            spacing: 0

            RowLayout {
                spacing: 6

                Text {
                    text: Weather.state === "ok" ? `${Math.round(Weather.temperature)}°` : "--"
                    color: Config.fg

                    font.family: Config.font
                    font.pixelSize: 34
                }

                Text {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 6

                    text: Weather.state === "ok" ? root.today.label : Weather.state === "error" ? "Unavailable" : "Loading…"
                    color: Config.fgDim

                    font.family: Config.font
                    font.pixelSize: Config.fontSize + 1
                }
            }

            Text {
                text: Weather.place
                color: Qt.alpha(Config.fgDim, 0.8)

                font.family: Config.font
                font.pixelSize: Config.fontSize - 1
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Repeater {
            model: [
                {
                    icon: "\u{f050f}",
                    caption: "Feels like",
                    value: `${Math.round(Weather.feelsLike)}°`
                },
                {
                    icon: "\u{f058e}",
                    caption: "Humidity",
                    value: `${Math.round(Weather.humidity)}%`
                },
                {
                    icon: "\u{f059d}",
                    caption: "Wind",
                    value: `${Math.round(Weather.wind)} ${Weather.windUnit}`
                },
                {
                    icon: "\u{f059c}",
                    caption: "Sunrise",
                    value: Weather.sunrise
                },
                {
                    icon: "\u{f059b}",
                    caption: "Sunset",
                    value: Weather.sunset
                }
            ]

            ColumnLayout {
                id: cell

                required property var modelData

                Layout.preferredWidth: 78
                Layout.alignment: Qt.AlignVCenter

                spacing: 1
                visible: Weather.state === "ok"

                Text {
                    Layout.alignment: Qt.AlignHCenter

                    text: cell.modelData.icon
                    color: Config.fgDim

                    font.family: Config.iconFont
                    font.pixelSize: Config.fontSize + 3
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter

                    text: cell.modelData.value
                    color: Config.fg

                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter

                    text: cell.modelData.caption
                    color: Qt.alpha(Config.fgDim, 0.75)

                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 3
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.preferredHeight: 1

        color: Qt.alpha(Config.fgDim, 0.25)
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2

        spacing: 4

        Repeater {
            model: Weather.forecast

            Rectangle {
                id: column

                required property var modelData
                required property int index

                readonly property var conditions: Weather.describe(column.modelData.code)

                Layout.fillWidth: true
                Layout.preferredHeight: 90

                radius: Config.radius - 4
                color: column.index === 0 ? Qt.alpha(Config.surface, 0.6) : "transparent"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        Layout.alignment: Qt.AlignHCenter

                        text: root.day(column.modelData.date, column.index)
                        color: column.index === 0 ? Config.fg : Config.fgDim

                        font.family: Config.font
                        font.pixelSize: Config.fontSize - 1
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter

                        text: column.conditions.glyph
                        color: Config.accent

                        font.family: Config.iconFont
                        font.pixelSize: Config.fontSize + 8
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 5

                        Text {
                            text: `${Math.round(column.modelData.max)}°`
                            color: Config.fg

                            font.family: Config.font
                            font.pixelSize: Config.fontSize
                        }

                        Text {
                            text: `${Math.round(column.modelData.min)}°`
                            color: Qt.alpha(Config.fgDim, 0.8)

                            font.family: Config.font
                            font.pixelSize: Config.fontSize
                        }
                    }
                }
            }
        }
    }
}
