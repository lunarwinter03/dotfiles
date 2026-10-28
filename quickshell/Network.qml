import QtQuick
import Quickshell.Networking

Item {
    id: root
    required property var screenData      // Monitor dieser Leiste

    implicitWidth: row.implicitWidth+8
    implicitHeight: Theme.barHeight

    // ===== Daten =====
    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifiDevice
        ? (wifiDevice.networks.values.find(n => n.connected) ?? null)
        : null

    readonly property bool available: devices.length > 0

    readonly property string kind:
          wired       ? "wired"
        : wifiNetwork ? "wifi"
        : (wifiDevice && !Networking.wifiEnabled) ? "off"
        : "none"

    visible: available

    // ===== Anzeige =====
    Row {
        id: row
	anchors.centerIn: parent
        spacing: 4

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

    // ===== Klick öffnet/schließt das Fenster =====
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Popups.network = (Popups.network === root.screenData.name)
                                    ? "" : root.screenData.name
    }

    NetworkPopup {
        targetScreen: root.screenData
        wifiDevice: root.wifiDevice
        deviceName: root.wired      ? root.wired.name
                  : root.wifiDevice ? root.wifiDevice.name
                  : ""
    }
}
