pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    // Notifications shown as popups right now, oldest first
    property var popups: []
    // Arrival time per notification id, the protocol carries none
    property var times: ({})
    // Everything not dismissed yet, oldest first
    readonly property var history: server.trackedNotifications.values

    readonly property bool dnd: settings.dnd
    readonly property string screenChoice: settings.screen     // "" = focused screen
    readonly property string targetScreen:
        screenChoice !== "" && Quickshell.screens.some(s => s.name === screenChoice)
            ? screenChoice : Popups.focusedScreen()

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
	    root.times[n.id] = new Date()
            n.tracked = true
            root.trimHistory()
            n.closed.connect(() => {
                root.hidePopup(n)
                delete root.times[n.id]
            })

            const critical = n.urgency === NotificationUrgency.Critical
            if (root.dnd && !critical)
                return
	    root.popups = root.popups.concat([n]) 
            if (!critical) {
                const secs = n.expireTimeout > 0 ? n.expireTimeout : Config.notificationTimeout
                hideTimer.createObject(root, { notif: n, interval: secs * 1000 })
            }
        }
    }

    Component {
        id: hideTimer
        Timer {
            property var notif
            running: true
            onTriggered: {
                root.hidePopup(notif)
                destroy()
            }
        }
    }

    // Screen choice and do-not-disturb survive restarts
    FileView {
        path: Quickshell.statePath("notifications.json")
        watchChanges: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter()
        }

        JsonAdapter {
            id: settings
            property string screen: ""
            property bool dnd: false
        }
    }

    function hidePopup(n) {
        popups = popups.filter(p => p !== n)
    }

    function dismiss(n) {
        hidePopup(n)
        n.dismiss()
    }

    function clearAll() {
        popups = []
        for (const n of history.slice())
            n.dismiss()
    }

    function trimHistory() {
        const all = history.slice()
        for (let i = 0; i < all.length - Config.notificationHistoryMax; i++)
            all[i].dismiss()
    }

    function setDnd(on) {
        settings.dnd = on
        if (on)
            popups = popups.filter(n => n.urgency === NotificationUrgency.Critical)
    }

    function cycleScreen(delta) {
        const options = [""].concat(Quickshell.screens.map(s => s.name))
        const n = options.length
        const i = Math.max(0, options.indexOf(settings.screen))
        settings.screen = options[(i + delta + n) % n]
    }

    function openCenter() {
        Popups.notifications = root.targetScreen
    }

    // "14:32" today, "31.10. 14:32" for older ones
    function timeText(n) {
        const t = times[n.id]
        if (!t)
            return ""
        const today = t.toDateString() === new Date().toDateString()
        return Qt.formatDateTime(t, today ? "HH:mm" : "dd.MM. HH:mm")
    }
}
