pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Screen the window is open on ("" = closed). Only one at a time.
    property string network: ""
    property string wallpaper: ""
    property string notifications: ""

    // Visible height of the open network window, popups move below it
    property real networkHeight: 0

    onNetworkChanged:       if (network !== "")       { wallpaper = ""; notifications = "" }
    onWallpaperChanged:     if (wallpaper !== "")     { network = ""; notifications = "" }
    onNotificationsChanged: if (notifications !== "") { network = ""; wallpaper = "" }

    function closeAll() {
        network = ""
        wallpaper = ""
        notifications = ""
    }

    // Focused screen from mango, otherwise the first one
    function focusedScreen() {
        const mons = Mango.monitors
        const active = Object.keys(mons).find(name => mons[name].active)
        return active ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
    }

    // qs ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.wallpaper = root.wallpaper !== "" ? "" : root.focusedScreen()
        }
    }

    // qs ipc call notifications toggle
    IpcHandler {
        target: "notifications"
        function toggle(): void {
            root.notifications = root.notifications !== "" ? "" : Notifs.targetScreen
        }
    }
}
