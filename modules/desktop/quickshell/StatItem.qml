import QtQuick

Row {
    id: root
    property string icon
    property int value: -1      // Prozent, -1 = nicht verfügbar
    property int temp: -1       // °C, -1 = keine Temperatur

    spacing: 3
    visible: value >= 0

    TextMetrics {
        id: valueMetrics
        font: valueText.font
        text: "100%"
    }

    // Symbol
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        font.family: Theme.fontIcons
        font.pixelSize: Theme.fontIcon
        color: Theme.fgDim
    }

    // Prozentwert mit fester Breite
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: valueMetrics.advanceWidth
        height: valueText.implicitHeight

        Text {
            id: valueText
            anchors.right: parent.right
            text: root.value + "%"
            color: Theme.fg
            font.pixelSize: Theme.fontMedium
            font.features: { "tnum": 1 }
        }
    }

    // Temperatur (optional)
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Config.statsShowTemp && root.temp >= 0
        text: root.temp + "°"
        color: Theme.fgDim
        font.pixelSize: Theme.fontSmall
        font.features: { "tnum": 1 }
    }
}
