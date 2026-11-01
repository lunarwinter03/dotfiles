import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking

PanelWindow {
    id: popup
    required property var targetScreen
    required property string deviceName
    required property var wifiDevice

    // Connection state lives here, entries are recreated on every scan
    property var pendingNet: null
    property string pendingKey: ""
    property bool pskSent: false
    property string passwordFor: ""
    property string errorFor: ""
    property string errorText: ""

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

    Connections {
        target: popup.pendingNet
        ignoreUnknownSignals: true
        function onConnectionFailed(reason) {
            if (reason === ConnectionFailReason.NoSecrets) {
                popup.passwordFor = popup.pendingKey
                popup.errorFor    = popup.pskSent ? popup.pendingKey : ""
                popup.errorText   = "Wrong password"
            } else {
                popup.errorFor  = popup.pendingKey
                popup.errorText = "Connection failed"
            }
        }
    }

    Connections {
        target: WifiScan
        function onBssidConnectFinished(ok) {
            if (!ok) {
                popup.errorFor  = popup.pendingKey
                popup.errorText = "Switching access point failed"
            }
        }
    }

    // Pause rescans while a password is typed in this window
    Binding {
        target: WifiScan
        property: "paused"
        value: popup.passwordFor !== ""
        when: popup.visible
    }

    // Notification popups move below this window
    Binding {
        target: Popups
        property: "networkHeight"
        value: box.height
        when: popup.visible
    }

    screen: targetScreen
    visible: Popups.network === targetScreen.name

    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    margins {
        top: Theme.barHeight + (Config.borderMode !== "none" ? Config.borderWidth : 0) + Theme.gap
        right: Theme.pad
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-network"

    // Fixed size, only the box is visible and clickable
    color: "transparent"
    implicitWidth: 370
    implicitHeight: Config.networkPopupMaxHeight + 100
    mask: Region { item: content }

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
            passwordFor = ""
            errorFor = ""
        }
    }

    FocusScope {
        id: content
        width: parent.width
        height: box.height
        focus: true

        Keys.onEscapePressed: Popups.closeAll()
        onActiveFocusChanged: if (!activeFocus && popup.visible) Popups.closeAll()

        PopupBox {
            id: box
            width: parent.width

            PopupHeader {
                title: "Wi-Fi"

                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Networking.wifiEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            SelectableText {
                visible: WifiScan.ipAddress !== ""
                text: popup.deviceName + "  " + WifiScan.ipAddress
                color: Theme.fgDim
                font.pixelSize: Theme.fontSmall
                font.family: Theme.fontMono
            }

            Separator {}

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
                    expanded: popup.expanded[modelData.key] === true
                    askPassword: popup.passwordFor === modelData.key
                    errorText: popup.errorFor === modelData.key ? popup.errorText : ""

                    onToggleExpanded: popup.toggle(modelData.key)
                    onConnectRequested: popup.connectTo(modelData.key, qsNet)
                    onDisconnectRequested: if (qsNet) qsNet.disconnect()
                    onBssidConnectRequested: bssid => popup.connectBssid(modelData.key, modelData.ssid, bssid)
                    onPasswordSubmitted: psk => popup.submitPassword(psk)
                    onPasswordCancelled: popup.passwordFor = ""
                }
            }

            Text {
                visible: list.count === 0
                text: !Networking.wifiEnabled ? "Wi-Fi is off"
                    : WifiScan.scanning ? "Scanning …"
                    : "No networks found"
                color: Theme.fgDim
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
