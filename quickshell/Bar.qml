import QtQuick
import QtQuick.Shapes
import Quickshell

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }

    // Fenster ist höher als die Leiste, damit der Datumsbereich überstehen kann
    implicitHeight: Theme.barHeight + Theme.dateHeight
    // ... aber nur die Leiste selbst reserviert Platz
    exclusiveZone: Theme.barHeight
    color: "transparent"

    // Klicks nur auf Leiste und Datumsbereich annehmen
    mask: Region {
        item: barBg
        Region { item: dateTab }
    }

    // ===== Hauptleiste =====
    Rectangle {
        id: barBg
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Theme.barHeight

        // Oben deckender, nach unten transparenter
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bgTop }
            GradientStop { position: 1.0; color: Theme.bgBottom }
        }
    }

    // ===== Uhrzeit (Mitte) =====
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        height: Theme.barHeight
        verticalAlignment: Text.AlignVCenter
        text: Time.time
        font.features: { "tnum": 1 }
        color: Theme.fg
        font.pixelSize: 15
        font.bold: true
    }

    // ===== Datumsbereich \____/ =====
    Item {
        id: dateTab
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.barHeight
        width: Theme.dateWidth
        height: Theme.dateHeight

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.bgBottom
                strokeColor: "transparent"

                // Oben links -> oben rechts -> unten rechts -> unten links
                startX: 0; startY: 0
                PathLine { x: dateTab.width;                   y: 0 }
                PathLine { x: dateTab.width - dateTab.height;  y: dateTab.height }
                PathLine { x: dateTab.height;                  y: dateTab.height }
                PathLine { x: 0;                               y: 0 }
            }
        }

        Text {
            anchors.centerIn: parent
            text: Time.date
            font.features: { "tnum": 1 }
            color: Theme.fgDim
            font.pixelSize: 10
        }
    }
}
