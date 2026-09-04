pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string state: "loading"

    property string place: Options.str("weather.place", "")
    property real latitude: Options.num("weather.latitude", 0)
    property real longitude: Options.num("weather.longitude", 0)

    readonly property bool imperial: Options.str("weather.units", "metric") === "imperial"
    readonly property string windUnit: imperial ? "mph" : "km/h"

    property real temperature: 0
    property real feelsLike: 0
    property real humidity: 0
    property real wind: 0
    property int code: 0

    property string sunrise: ""
    property string sunset: ""

    property var forecast: []

    property real fetchedAt: 0

    readonly property int staleAfter: 15 * 60 * 1000

    function refresh(): void {
        if (Date.now() - fetchedAt < staleAfter && state === "ok")
            return;

        if (latitude === 0 && longitude === 0)
            locate.running = true;
        else
            report.running = true;
    }

    function describe(code: int): var {
        const table = {
            0: ["Clear", "sunny"],
            1: ["Mainly clear", "sunny"],
            2: ["Partly cloudy", "partly"],
            3: ["Overcast", "cloudy"],
            45: ["Fog", "fog"],
            48: ["Rime fog", "fog"],
            51: ["Light drizzle", "rain"],
            53: ["Drizzle", "rain"],
            55: ["Heavy drizzle", "rain"],
            56: ["Freezing drizzle", "rain"],
            57: ["Freezing drizzle", "rain"],
            61: ["Light rain", "rain"],
            63: ["Rain", "rain"],
            65: ["Heavy rain", "pouring"],
            66: ["Freezing rain", "rain"],
            67: ["Freezing rain", "pouring"],
            71: ["Light snow", "snow"],
            73: ["Snow", "snow"],
            75: ["Heavy snow", "snow"],
            77: ["Snow grains", "snow"],
            80: ["Light showers", "rain"],
            81: ["Showers", "rain"],
            82: ["Heavy showers", "pouring"],
            85: ["Snow showers", "snow"],
            86: ["Snow showers", "snow"],
            95: ["Thunderstorm", "storm"],
            96: ["Thunderstorm, hail", "hail"],
            99: ["Thunderstorm, hail", "hail"]
        };

        const glyphs = {
            sunny: "\u{f0599}",
            partly: "\u{f0595}",
            cloudy: "\u{f0590}",
            fog: "\u{f0591}",
            rain: "\u{f0597}",
            pouring: "\u{f0596}",
            snow: "\u{f0598}",
            storm: "\u{f0593}",
            hail: "\u{f0592}"
        };

        const entry = table[code] ?? ["Unknown", "cloudy"];

        return {
            label: entry[0],
            glyph: glyphs[entry[1]]
        };
    }

    function clock(iso: string): string {

        const t = iso.split("T")[1] ?? "";
        return t.slice(0, 5);
    }

    Process {
        id: locate

        command: ["curl", "-sfL", "--max-time", "8", "http://ip-api.com/json/?fields=status,city,regionName,country,lat,lon"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);

                    if (data.status !== "success")
                        throw new Error("lookup failed");

                    root.latitude = data.lat;
                    root.longitude = data.lon;
                    if (!root.place)
                        root.place = data.city && data.city !== data.regionName ? `${data.city}, ${data.regionName}` : (data.regionName || data.country);
                    report.running = true;
                } catch (e) {
                    root.state = "error";
                }
            }
        }
    }

    Process {
        id: report

        command: ["curl", "-sfL", "--max-time", "10", `https://api.open-meteo.com/v1/forecast?latitude=${root.latitude}&longitude=${root.longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=auto&forecast_days=7${root.imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : ""}`]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const now = data.current;
                    const days = data.daily;

                    root.temperature = now.temperature_2m;
                    root.feelsLike = now.apparent_temperature;
                    root.humidity = now.relative_humidity_2m;
                    root.wind = now.wind_speed_10m;
                    root.code = now.weather_code;

                    root.sunrise = root.clock(days.sunrise[0]);
                    root.sunset = root.clock(days.sunset[0]);

                    const out = [];
                    for (let i = 0; i < days.time.length; i++)
                        out.push({
                            date: days.time[i],
                            code: days.weather_code[i],
                            max: days.temperature_2m_max[i],
                            min: days.temperature_2m_min[i]
                        });

                    root.forecast = out;
                    root.fetchedAt = Date.now();
                    root.state = "ok";
                } catch (e) {
                    root.state = "error";
                }
            }
        }
    }

    Component.onCompleted: refresh()
}
