pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ===== Öffentliche Werte (-1 = nicht verfügbar) =====
    property int cpu: -1
    property int cpuTemp: -1
    property int ram: -1
    property int gpu: -1
    property int gpuTemp: -1
    property int vram: -1

    // ===== Takt für CPU, RAM und CPU-Temperatur =====
    Timer {
        interval: Config.statsInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            procStat.reload()
            procMem.reload()
            if (root.cpuTempPath !== "")
                cpuTempFile.reload()
        }
    }

    // ===== CPU-Auslastung aus /proc/stat =====
    // Die Datei enthält Zeit-Zähler seit dem Systemstart. Die Auslastung ergibt
    // sich aus der Differenz zwischen zwei Messungen.
    property var lastCpu: null

    FileView {
        id: procStat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle  = f[3] + f[4]                         // idle + iowait
            const total = f.slice(0, 8).reduce((a, b) => a + b, 0)

            if (root.lastCpu) {
                const dTotal = total - root.lastCpu.total
                const dIdle  = idle  - root.lastCpu.idle
                if (dTotal > 0)
                    root.cpu = Math.round(100 * (1 - dIdle / dTotal))
            }
            root.lastCpu = { total: total, idle: idle }
        }
    }

    // ===== RAM aus /proc/meminfo =====
    FileView {
        id: procMem
        path: "/proc/meminfo"
        onLoaded: {
            const t = text()
            const total = Number(t.match(/MemTotal:\s+(\d+)/)?.[1] ?? 0)
            const avail = Number(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0)
            if (total > 0)
                root.ram = Math.round(100 * (total - avail) / total)
        }
    }

    // ===== CPU-Temperatur =====
    // Der hwmon-Pfad wechselt zwischen Neustarts (hwmon0, hwmon3, …),
    // deshalb wird der Sensor einmal beim Start anhand seines Namens gesucht.
    property string cpuTempPath: ""

    Process {
        running: true
        command: ["sh", "-c",
            "for d in /sys/class/hwmon/hwmon*; do " +
            "  case \"$(cat \"$d/name\")\" in k10temp|zenpower|coretemp) " +
            "    echo \"$d/temp1_input\"; exit;; esac; " +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuTempPath = text.trim()
        }
    }

    FileView {
        id: cpuTempFile
        path: root.cpuTempPath
        onLoaded: {
            const v = Number(text().trim())
            if (!isNaN(v) && v > 0)
                root.cpuTemp = Math.round(v / 1000)           // Milligrad -> Grad
        }
    }

    // ===== GPU über nvidia-smi (läuft dauerhaft, liefert im Takt eine Zeile) =====
    property bool gpuHadData: false

    Process {
        id: gpuProc
        running: true
        command: ["nvidia-smi",
                  "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total",
                  "--format=csv,noheader,nounits",
                  "-lms", String(Config.statsInterval * 1000)]

        stdout: SplitParser {
            onRead: data => {
                const p = data.split(",").map(s => Number(s.trim()))
                if (p.length < 4 || p.some(isNaN))
                    return
                root.gpu     = p[0]
                root.gpuTemp = p[1]
                root.vram    = p[3] > 0 ? Math.round(100 * p[2] / p[3]) : -1
                root.gpuHadData = true
            }
        }

        onExited: {
            // GPU-Anzeige ausblenden
            root.gpu = -1; root.gpuTemp = -1; root.vram = -1
            // Nur neu starten, wenn es vorher schon funktioniert hat
            if (root.gpuHadData)
                gpuRestart.start()
        }
    }

    Timer {
        id: gpuRestart
        interval: 10000
        onTriggered: gpuProc.running = true
    }
}
