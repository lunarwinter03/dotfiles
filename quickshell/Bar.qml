import QtQuick
import QtQuick.Shapes
import Quickshell

PanelWindow {
    id: bar
    required property var modelData 
    screen: modelData
    readonly property real borderMain: Config.borderMode !== "none" ? Config.borderWidth : 0
    readonly property real borderTab:  Config.borderMode !== "none" ? Config.borderWidthTab : 0

    // Daten dieses Monitors aus Mango (null, solange noch nichts da ist)
    readonly property var mon: Mango.monitors[modelData.name] ?? null

    anchors { top: true; left: true; right: true }

    // Fenster ist höher als die Leiste, damit der Datumsbereich überstehen kann
        implicitHeight: Math.ceil(Theme.barHeight + Math.max(Theme.dateHeight + borderTab, borderMain))
	exclusiveZone:  Math.ceil(Theme.barHeight + borderMain)
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

    // ===== Layout und Tags (links) =====
    Tags {
        mon: bar.mon
        anchors { left: parent.left; leftMargin: 8 }
        height: Theme.barHeight
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

        // ===== Rechte Seite =====
    Row {
        anchors { right: parent.right; rightMargin: 8 }
        height: Theme.barHeight
        spacing: Theme.groupGap

        // ----- Gruppe 1: Systemwerte -----
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            StatItem {
                anchors.verticalCenter: parent.verticalCenter
                icon: Config.iconCpu
                value: Stats.cpu
                temp: Stats.cpuTemp
            }
            StatItem {
                anchors.verticalCenter: parent.verticalCenter
                icon: Config.iconGpu
                value: Stats.gpu
                temp: Stats.gpuTemp
            }
            StatItem {
                anchors.verticalCenter: parent.verticalCenter
                icon: Config.iconVram
                value: Config.statsShowVram ? Stats.vram : -1
            }
            StatItem {
                anchors.verticalCenter: parent.verticalCenter
                icon: Config.iconRam
                value: Stats.ram
            }
        }

        // ----- Gruppe 2: Verbindung und Strom -----
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            // Ohne sichtbaren Inhalt (PC ohne Akku) auch keinen Abstand erzeugen
            visible: battery.visible

            Battery {
                id: battery
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ===== Optionale Unterkante =====
    Loader {
        anchors.fill: parent
        active: Config.borderMode !== "none"
        sourceComponent: Component { BarBorder {} }
    }
}
