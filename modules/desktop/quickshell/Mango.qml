pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Monitor name -> monitor data from mmsg, e.g. monitors["DP-1"].tags
    property var monitors: ({})

    // App that last had focus on the active monitor
    property string lastFocusApp: ""

    // Switch to the "remote" keymode while a remote desktop window has focus.
    // Only acts when the focus changes, so Ctrl+Alt+Esc can still leave the mode.
    function updateKeymode(parsed) {
        const active = parsed.monitors.find(m => m.active)
        if (!active)
            return
        const app = (active.active_client && active.active_client.appid) || ""
        if (app === lastFocusApp)
            return
        lastFocusApp = app

        const lower = app.toLowerCase()
        const remote = Config.remoteApps.some(r => lower.includes(r))
        const wanted = remote ? "remote" : "default"
        if (active.keymode !== wanted)
            Quickshell.execDetached(["mmsg", "dispatch", "setkeymode," + wanted])
    }

    Process {
        id: proc
        command: ["mmsg", "watch", "all-monitors"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data)
                    const map = {}
                    for (const m of parsed.monitors)
                        map[m.name] = m
                    root.monitors = map
                    root.updateKeymode(parsed)
                } catch (e) {
                    console.warn("Mango: cannot parse mmsg output:", e)
                }
            }
        }

        // mmsg ends when mango restarts, try again after a second
        onExited: restartTimer.start()
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: proc.running = true
    }
}
