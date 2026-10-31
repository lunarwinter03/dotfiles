import QtQuick

Row {
    id: root
    required property var mon      // Monitordaten aus Mango.qml (oder null)
    spacing: 4

    // Misst, wie breit das breitestmögliche Kürzel in dieser Schrift ist
    TextMetrics {
        id: layoutMetrics
        font: layoutText.font
        text: "WW"
    }

    // ===== Aktuelles Layout (feste Breite) =====
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: layoutMetrics.advanceWidth
        height: layoutText.implicitHeight

        Text {
            id: layoutText
            anchors.centerIn: parent
            text: root.mon ? root.mon.layout_symbol : "?"
            color: Theme.fgDim
            font.pixelSize: Theme.fontMedium
            font.bold: true
        }
    }

    // ===== Tags mit Fenstern =====
    Repeater {
        model: root.mon
            ? root.mon.tags.filter(t => t.client_count > 0
                                     || (t.is_active && Config.tagsShowActiveEmpty))
            : []

        delegate: Rectangle {
            id: tag
            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            width: Theme.tagSize
            height: Theme.tagSize
            radius: Theme.tagRadius
            color: "transparent"
            border.width: Theme.tagBorderWidth
            border.color: Theme.outlineVariant

            Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: tag.modelData.index
                color: tag.modelData.is_urgent ? Theme.urgent
                     : tag.modelData.is_active ? Theme.accent
                     : Theme.fg
                font.pixelSize: Theme.fontMedium
                font.bold: tag.modelData.is_active
                font.features: { "tnum": 1 }
            }
        }
    }
}
