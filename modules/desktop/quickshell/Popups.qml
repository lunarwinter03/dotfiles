pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Monitor, auf dem das jeweilige Fenster offen ist ("" = geschlossen)
    property string network: ""
    property string wallpaper: ""

    function closeAll() {
        network = ""
        wallpaper = ""
    }

    // Name des fokussierten Monitors (aus Mango), sonst der erste Bildschirm
    function focusedScreen() {
        const mons = Mango.monitors
        const active = Object.keys(mons).find(name => mons[name].active)
        return active ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
    }

    // Von außen aufrufbar: qs ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            if (root.wallpaper !== "") {
                root.wallpaper = ""
            } else {
                root.network = ""
                root.wallpaper = root.focusedScreen()
            }
        }
    }
}
