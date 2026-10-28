pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ key, ssid, hidden, signal, security, inUse, aps: [{ bssid, signal, inUse }] }]
    property var networks: []
    property string ipAddress: ""
    property string device: ""                  // Gerät für die IP, z.B. "wlp5s0"
    readonly property bool scanning: scanProc.running

    // Wie viele Fenster gerade offen sind (eines pro Monitor möglich)
    property int openCount: 0
    function open()  { openCount++; refresh() }
    function close() { openCount = Math.max(0, openCount - 1) }

    function refresh() {
        if (!scanProc.running) {
            scanProc.command = ["nmcli", "-t", "-f", "IN-USE,BSSID,SSID,SIGNAL,SECURITY,FREQ",
                                "device", "wifi", "list", "--rescan", "auto"]
            scanProc.running = true
        }
        if (root.device !== "" && !ipProc.running) {
            ipProc.command = ["nmcli", "-g", "IP4.ADDRESS", "device", "show", root.device]
            ipProc.running = true
        }
    }

    // Eine Terse-Zeile zerlegen: ":" trennt, "\:" und "\\" sind maskiert
    function splitTerse(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) {
                cur += line[++i]
            } else if (c === ":") {
                out.push(cur)
                cur = ""
            } else {
                cur += c
            }
        }
        out.push(cur)
        return out
    }

    function parse(text) {
        const groups = {}
        const hidden = []

        for (const line of text.split("\n")) {
            if (line === "")
                continue
            const f = splitTerse(line)
            if (f.length < 6)
                continue

            const ap = {
                bssid:  f[1],
                signal: Number(f[3]) || 0,
                inUse:  f[0] === "*",
                freq:   parseInt(f[5]) || 0      // "5180 MHz" -> 5180
	    }
	    const ssid = f[2]
            const security = f[4]

            if (ssid === "") {
                // Verstecktes Netz: ohne Namen nicht gruppierbar, jeder AP ein Eintrag
                hidden.push({ key: ap.bssid, ssid: "", hidden: true, signal: ap.signal,
                              security: security, inUse: ap.inUse, aps: [ap] })
                continue
            }

            if (!groups[ssid])
                groups[ssid] = { key: ssid, ssid: ssid, hidden: false, signal: 0,
                                 security: security, inUse: false, aps: [] }
            const g = groups[ssid]
            g.aps.push(ap)
            g.signal = Math.max(g.signal, ap.signal)
            g.inUse = g.inUse || ap.inUse
        }

        const byStrength = (a, b) => b.signal - a.signal
        const list = Object.values(groups)
        for (const g of list)
            g.aps.sort(byStrength)

        list.sort((a, b) => (Config.networkPinConnected && (b.inUse - a.inUse)) || byStrength(a, b))
        hidden.sort(byStrength)

        return list.concat(hidden)       // versteckte Netze immer ganz unten
    }

    // Frequenz in MHz -> Band
    function bandLabel(mhz) {
        if (mhz <= 0)    return ""
        if (mhz < 3000)  return "2.4 GHz"
        if (mhz < 5925)  return "5 GHz"
        return "6 GHz"                     // Wi-Fi 6E / 7
    }

    Process {
        id: scanProc
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                // Leere Antwort (z.B. Fehler) nicht als "keine Netze" übernehmen
                if (text.trim() !== "")
                    root.networks = root.parse(text)
            }
        }
    }

    Process {
        id: ipProc
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.ipAddress = text.trim().split(" | ")[0] ?? ""
        }
    }

    // ===== Aktualisierung pausieren, z.B. während ein Passwort getippt wird =====
    property bool paused: false

    Timer {
        interval: Config.networkRefreshSeconds * 1000
        repeat: true
        running: root.openCount > 0 && !root.paused
        onTriggered: root.refresh()
    }

    // ===== Bestimmten Access Point eines gespeicherten Netzes aktivieren =====
    property string connectingBssid: ""
    signal bssidConnectFinished(bool ok)

    function connectBssid(ssid, bssid) {
        if (connectProc.running)
            return
        connectingBssid = bssid
        connectProc.command = ["nmcli", "-w", "20", "connection", "up", "id", ssid, "ap", bssid]
        connectProc.running = true
    }

    Process {
        id: connectProc
        environment: ({ LC_ALL: "C" })
        onExited: (exitCode, exitStatus) => {
            root.connectingBssid = ""
            root.bssidConnectFinished(exitCode === 0)
            root.refresh()
        }
    }
}
