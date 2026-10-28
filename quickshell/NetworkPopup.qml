import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking

PanelWindow {
    id: popup
    required property var targetScreen
    required property string deviceName
    required property var wifiDevice

    // ===== Verbindungs-Zustand (im Fenster, da Einträge neu erzeugt werden) =====
    property var pendingNet: null
    property string pendingKey: ""
    property bool pskSent: false
    property string passwordFor: ""
    property string errorFor: ""
    property string errorText: ""

    // Passendes Quickshell-Netz zu einem Namen finden
    function findNet(ssid) {
        if (!wifiDevice || ssid === "")
            return null
        return wifiDevice.networks.values.find(n => n.name === ssid) ?? null
    }

    function connectTo(key, net) {
        errorFor = ""
        passwordFor = ""
        if (!net)
            return
        pendingNet = net
        pendingKey = key
        pskSent = false
        net.connect()
    }

    function submitPassword(psk) {
        passwordFor = ""
        if (!pendingNet)
            return
        pskSent = true
        pendingNet.connectWithPsk(psk)
    }

    function connectBssid(key, ssid, bssid) {
        errorFor = ""
        pendingKey = key
        WifiScan.connectBssid(ssid, bssid)
    }

    // Fehlschlag beim Verbinden auswerten
    Connections {
        target: popup.pendingNet
        ignoreUnknownSignals: true
        function onConnectionFailed(reason) {
            if (reason === ConnectionFailReason.NoSecrets) {
                popup.passwordFor = popup.pendingKey
                popup.errorFor    = popup.pskSent ? popup.pendingKey : ""
                popup.errorText   = "Passwort falsch"
            } else {
                popup.errorFor  = popup.pendingKey
                popup.errorText = "Verbindung fehlgeschlagen"
            }
        }
    }

    Connections {
        target: WifiScan
        function onBssidConnectFinished(ok) {
            if (!ok) {
                popup.errorFor  = popup.pendingKey
                popup.errorText = "Wechsel zum Access Point fehlgeschlagen"
            }
        }
    }

    // Aktualisierung pausieren, solange in DIESEM Fenster ein Passwort getippt wird
    Binding {
        target: WifiScan
        property: "paused"
        value: popup.passwordFor !== ""
        when: popup.visible
    }

    screen: targetScreen
    visible: Popups.network === targetScreen.name

    // ===== Position: oben rechts, direkt unter der Leiste =====
    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    margins {
        top: Theme.barHeight + (Config.borderMode !== "none" ? Config.borderWidth : 0) + 6
        right: 8
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-network"

    // ===== Feste Fenstergröße, sichtbar ist nur der Kasten =====
    color: "transparent"
    implicitWidth: 320
    implicitHeight: Config.networkPopupMaxHeight + 100
    mask: Region { item: content }

    // ===== Aufgeklappte Netze =====
    property var expanded: ({})
    function toggle(key) {
        const e = Object.assign({}, expanded)
        e[key] = !e[key]
        expanded = e
    }

    onVisibleChanged: {
        if (visible) {
            WifiScan.device = deviceName
            WifiScan.open()
            content.forceActiveFocus()
        } else {
            WifiScan.close()
	    passwordFor= ""
	    errorFor= ""
        }
    }

        FocusScope {
        id: content
        width: parent.width
        height: box.height

        focus: true
        Keys.onEscapePressed: Popups.closeAll()
        // Fokus verloren = in ein anderes Fenster geklickt
        onActiveFocusChanged: if (!activeFocus && popup.visible) Popups.closeAll()

        Rectangle {
            id: box
            width: parent.width
            height: col.implicitHeight + 16
            radius: Theme.popupRadius
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.outlineVariant

            Column {
                id: col
                x: 8
                y: 8
                width: parent.width - 16
                spacing: 6

                // ===== Kopfzeile mit WLAN-Schalter =====
                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "WLAN"
                        color: Theme.fg
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 16
                        radius: 8
                        color: Networking.wifiEnabled ? Theme.accent : Theme.outlineVariant

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            y: 2
                            x: Networking.wifiEnabled ? parent.width - width - 2 : 2
                            color: Theme.bgBase
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                        }
                    }
                }

                // ===== Eigene IP =====
                SelectableText {
                    visible: WifiScan.ipAddress !== ""
                    text: popup.deviceName + "   " + WifiScan.ipAddress
                    color: Theme.fgDim
                    font.pixelSize: 11
                    font.family: "monospace"
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }

                // ===== Liste =====
                ListView {
                    id: list
                    width: parent.width
                    height: Math.min(contentHeight, Config.networkPopupMaxHeight)
                    clip: true
                    spacing: 2
                    model: Networking.wifiEnabled ? WifiScan.networks : []

                    delegate: NetworkEntry {
                        width: list.width
                        qsNet: popup.findNet(modelData.ssid)
                        expanded:    popup.expanded[modelData.key] === true
                        askPassword: popup.passwordFor === modelData.key
                        errorText:   popup.errorFor === modelData.key ? popup.errorText : ""

                        onToggleExpanded:      popup.toggle(modelData.key)
                        onConnectRequested:    popup.connectTo(modelData.key, qsNet)
                        onDisconnectRequested: if (qsNet) qsNet.disconnect()
                        onBssidConnectRequested: bssid => popup.connectBssid(modelData.key, modelData.ssid, bssid)
                        onPasswordSubmitted:     psk => popup.submitPassword(psk)
                        onPasswordCancelled:     popup.passwordFor = ""
                    }
                }

                Text {
                    visible: list.count === 0
                    text: !Networking.wifiEnabled ? "WLAN ist ausgeschaltet"
                        : WifiScan.scanning       ? "Suche …"
                        : "Keine Netze gefunden"
                    color: Theme.fgDim
                    font.pixelSize: 11
                }
            }   // Column
        }       // Rectangle box
    }           // FocusScope
}               // PanelWindow
