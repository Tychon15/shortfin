pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

    readonly property int interval: Options.num("pollInterval", 2000)

    readonly property string diskMount: Options.str("diskMount", "/")

    readonly property string cpuTempSensor: Options.str("cpuTempSensor", "coretemp|k10temp|zenpower|cpu_thermal")

    property real cpu: 0
    property real cpuTemp: 0

    property real dgpu: 0
    property real dgpuTemp: 0
    property real dgpuMemory: 0
    property real igpu: 0
    property real igpuClock: 0

    readonly property bool discrete: dgpu > 0.05

    readonly property real gpu: discrete ? dgpu : igpu

    property string igpuDriver: ""
    readonly property var driverNames: ({
        "i915": "Intel",
        "xe": "Intel",
        "amdgpu": "AMD",
        "radeon": "AMD",
        "nouveau": "NVIDIA",
        "msm": "Adreno",
        "panfrost": "Mali",
        "panthor": "Mali",
        "v3d": "VideoCore",
        "vc4": "VideoCore",
        "virtio_gpu": "VirtIO",
        "lima": "Mali"
    })
    readonly property string gpuVendor: discrete ? "NVIDIA" : (driverNames[igpuDriver] ?? (igpuDriver || "GPU"))
    readonly property string gpuLabel: `${gpuVendor} · ${Math.round(gpu * 100)}%`

    readonly property string gpuDetail: discrete ? `${Math.round(dgpuTemp)}°C` : igpuClock > 0 ? `${Math.round(igpuClock)} MHz` : ""
    property real memory: 0
    property real memoryUsed: 0
    property real memoryTotal: 0
    property real disk: 0
    property real diskUsed: 0
    property real diskTotal: 0
    property real down: 0
    property real up: 0

    property var lastCpu: null
    property var lastNet: null
    property real lastNetAt: 0
    property var lastGpu: null
    property real lastGpuAt: 0

    function format(bytes: real): string {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = bytes;
        let i = 0;

        while (value >= 1024 && i < units.length - 1) {
            value /= 1024;
            i++;
        }

        return `${value < 10 && i > 0 ? value.toFixed(1) : Math.round(value)} ${units[i]}`;
    }

    function rate(bytes: real): string {
        return `${format(bytes)}/s`;
    }

    function parse(text: string): void {
        const now = Date.now();

        for (const line of text.trim().split("\n")) {
            const f = line.trim().split(/\s+/);

            switch (f[0]) {
            case "CPU": {

                const v = f.slice(1, 9).map(Number);
                const idle = v[3] + v[4];
                const total = v.reduce((a, b) => a + b, 0);

                if (root.lastCpu) {
                    const dTotal = total - root.lastCpu.total;
                    const dIdle = idle - root.lastCpu.idle;
                    if (dTotal > 0)
                        root.cpu = Math.max(0, Math.min(1, (dTotal - dIdle) / dTotal));
                }

                root.lastCpu = {
                    idle: idle,
                    total: total
                };
                break;
            }
            case "MEM": {

                root.memoryTotal = Number(f[1]) * 1024;
                root.memoryUsed = root.memoryTotal - Number(f[2]) * 1024;
                root.memory = root.memoryTotal > 0 ? root.memoryUsed / root.memoryTotal : 0;
                break;
            }
            case "NET": {
                const rx = Number(f[1]);
                const tx = Number(f[2]);

                if (root.lastNet) {
                    const dt = (now - root.lastNetAt) / 1000;
                    if (dt > 0) {
                        root.down = Math.max(0, (rx - root.lastNet.rx) / dt);
                        root.up = Math.max(0, (tx - root.lastNet.tx) / dt);
                    }
                }

                root.lastNet = {
                    rx: rx,
                    tx: tx
                };
                root.lastNetAt = now;
                break;
            }
            case "CTEMP":
                root.cpuTemp = Number(f[1]) / 1000;
                break;
            case "DISK":
                root.diskUsed = Number(f[1]);
                root.diskTotal = Number(f[2]);
                root.disk = root.diskTotal > 0 ? root.diskUsed / root.diskTotal : 0;
                break;
            case "GPU":
                root.dgpu = Number(f[1]) / 100;
                root.dgpuTemp = Number(f[2]);
                root.dgpuMemory = Number(f[4]) > 0 ? Number(f[3]) / Number(f[4]) : 0;
                break;
            case "IGPU": {

                const busy = Number(f[1]);
                root.igpuClock = Number(f[2]);
                if (f[3] && f[3] !== "-")
                    root.igpuDriver = f[3];

                if (root.lastGpu !== null) {
                    const dt = (now - root.lastGpuAt) / 1000;
                    if (dt > 0)
                        root.igpu = Math.max(0, Math.min(1, (busy - root.lastGpu) / (dt * 1e9)));
                }

                root.lastGpu = busy;
                root.lastGpuAt = now;
                break;
            }
            }
        }
    }

    onActiveChanged: if (active) {
        lastCpu = null;
        lastNet = null;
        lastGpu = null;
        poll.running = true;
        probe.running = true;
    } else {
        poll.running = false;
    }

    Timer {
        id: poll

        interval: root.interval
        repeat: true
        onTriggered: probe.running = true
    }

    Process {
        id: probe

        command: ["sh", "-c", `
awk '/^cpu /{print "CPU", $2, $3, $4, $5, $6, $7, $8, $9; exit}' /proc/stat
awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print "MEM", t, a}' /proc/meminfo
IF=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
[ -n "$IF" ] && sed 's/:/ /' /proc/net/dev | awk -v i="$IF" '$1==i{print "NET", $2, $10}'
for h in /sys/class/hwmon/hwmon*; do
  case "$(cat "$h/name" 2>/dev/null)" in
    ${root.cpuTempSensor}) echo "CTEMP $(cat "$h/temp1_input" 2>/dev/null)"; break ;;
  esac
done
df -B1 --output=used,size "${root.diskMount}" 2>/dev/null | tail -1 | awk '{print "DISK", $1, $2}'
nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | awk -F', *' '{print "GPU", $1, $2, $3, $4}'
python3 "${Quickshell.shellPath("scripts/gpu.py")}" 2>/dev/null
`]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
}
