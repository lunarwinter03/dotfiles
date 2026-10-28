import QtQuick
import Quickshell.Networking

Row {
    id: root
    spacing: 4

    // ===== Daten =====
    readonly property var devices: Networking.devices.values

    // Verbundener LAN-Anschluss (hat Vorrang vor WLAN)
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null

    // WLAN-Karte und das Netz, mit dem sie verbunden ist
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifiDevice
        ? (wifiDevice.networks.values.find(n => n.connected) ?? null)
        : null

    // Gibt es überhaupt ein Netzwerkgerät? (z.B. NetworkManager läuft nicht)
    readonly property bool available: devices.length > 0

    // Aktueller Zustand als ein Wort
    readonly property string kind:
          wired       ? "wired"
        : wifiNetwork ? "wifi"
        : (wifiDevice && !Networking.wifiEnabled) ? "off"
        : "none"

    visible: available

    // ===== Symbol =====
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.kind === "wired" ? Config.iconEthernet
            : root.kind === "wifi"  ? Config.iconsWifi[Math.min(4, Math.floor(root.wifiNetwork.signalStrength * 5))]
            : root.kind === "off"   ? Config.iconWifiOff
            : Config.iconDisconnected
        font.family: "Symbols Nerd Font Mono"
        font.pixelSize: 13
        color: root.kind === "none" ? Theme.urgent : Theme.fgDim
    }

    // ===== WLAN-Name =====
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Config.networkShowName && root.kind === "wifi"
        text: root.wifiNetwork ? root.wifiNetwork.name : ""
        color: Theme.fg
        font.pixelSize: 12
        elide: Text.ElideRight
        width: Math.min(implicitWidth, Config.networkNameMaxWidth)
    }
}
