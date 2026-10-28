pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Monitorname -> Monitordaten aus mmsg, z.B. monitors["DP-1"].tags
    property var monitors: ({})

    Process {
        id: proc
        command: ["mmsg", "watch", "all-monitors"]
        running: true

        // Jede Ausgabezeile einzeln verarbeiten
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data)
                    const map = {}
                    for (const m of parsed.monitors)
                        map[m.name] = m
                    root.monitors = map
                } catch (e) {
                    console.warn("Mango: mmsg-Ausgabe nicht lesbar:", e)
                }
            }
        }

        // Endet mmsg (z.B. Mango neu gestartet), nach einer Sekunde neu starten
        onExited: restartTimer.start()
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: proc.running = true
    }
}
