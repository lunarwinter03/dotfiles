import QtQuick
import Quickshell.Services.UPower

Row {
    id: root
    spacing: 3

    // ===== Daten =====
    // displayDevice fasst alle Akkus zusammen (bei mehreren Akkus ein Gesamtwert)
    readonly property var dev: UPower.displayDevice
    readonly property bool available: dev !== null && dev.ready && dev.isLaptopBattery

    readonly property int percent: available && dev.energyCapacity > 0
        ? Math.round(100 * dev.energy / dev.energyCapacity)
        : 0

    // "Lädt" auch bei voll geladenem Akku am Netzteil
    readonly property bool charging: available
        && (dev.state === UPowerDeviceState.Charging
         || dev.state === UPowerDeviceState.FullyCharged)

    readonly property bool low: !charging && percent <= Config.batteryLowAt

    readonly property real seconds: !available ? 0
        : charging ? dev.timeToFull : dev.timeToEmpty

    function formatTime(sec) {
        const h = Math.floor(sec / 3600)
        const m = Math.floor((sec % 3600) / 60)
        return h + ":" + String(m).padStart(2, "0")
    }

    // Kein Akku (z.B. am PC): gar nicht anzeigen
    visible: available


    TextMetrics {
        id: valueMetrics
        font: valueText.font
        text: "100%"
    }

    // ===== Symbol =====
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.charging
            ? Config.iconBatteryCharging
            : Config.iconsBattery[Math.min(10, Math.floor(root.percent / 10))]
        font.family: "Symbols Nerd Font Mono"
        font.pixelSize: 13
        color: root.low      ? Theme.urgent
             : root.charging ? Theme.accent
             : Theme.fgDim
    }

    // ===== Prozent (feste Breite) =====
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: valueMetrics.advanceWidth
        height: valueText.implicitHeight

        Text {
            id: valueText
            anchors.right: parent.right
            text: root.percent + "%"
            color: root.low ? Theme.urgent : Theme.fg
            font.pixelSize: 12
            font.features: { "tnum": 1 }
        }
    }

    // ===== Restzeit (optional) =====
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Config.batteryShowTime && root.seconds > 0
        text: root.formatTime(root.seconds)
        color: Theme.fgDim
        font.pixelSize: 11
        font.features: { "tnum": 1 }
    }
}
