import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var targetScreen

    screen: targetScreen
    visible: Notifs.popups.length > 0
             && Notifs.targetScreen === targetScreen.name
             && Popups.notifications !== targetScreen.name

    // Top right below the bar; moves below the network window when it is open here
    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    margins {
        top: Theme.barHeight + (Config.borderMode !== "none" ? Config.borderWidth : 0) + Theme.gap
             + (Popups.network === targetScreen.name ? Popups.networkHeight + Theme.gap : 0)
        right: Theme.pad
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-notifications"

    color: "transparent"
    implicitWidth: Config.notificationWidth
    implicitHeight: Math.max(1, col.implicitHeight)

    Column {
        id: col
        width: parent.width
        spacing: Theme.gap

        Repeater {
            model: {
                const shown = Notifs.popups.slice(-Config.notificationMaxVisible)
                return Config.notificationPopupOrder === "newest" ? shown.reverse() : shown
            }    
	    
	    NotificationCard {
                required property var modelData
                width: col.width
                notif: modelData
            }
        }
    }
}
