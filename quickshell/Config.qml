pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // ===== Unterkante der Leiste =====
    // "none"     = aus
    // "solid"    = einfarbig (Akzentfarbe)
    // "gradient" = Verlauf zwischen zwei Theme-Farben
    // "rgb"      = Regenbogen
    readonly property string borderMode: "gradient"

    readonly property real borderWidth:    1.6     // unter der Hauptleiste, in px
    readonly property real borderWidthTab: 0.6   // um den Datumsbereich, in px
    readonly property bool borderAnimated: true // nur für gradient/rgb
    readonly property real borderSpeed: 5       // Sekunden pro Durchlauf
    readonly property string borderDirection: "right" // Richtung wohin (to) <left|right>

    // Farben für "gradient"
    readonly property color borderColorA: Theme.accent
    readonly property color borderColorB: Theme.accentAlt

    // ===== Tags =====
    // Aktiven Tag auch anzeigen, wenn er keine Fenster hat
    readonly property bool tagsShowActiveEmpty: true

    // ===== Systemanzeige (rechts) =====
    readonly property real statsInterval: 2       // Aktualisierung in Sekunden
    readonly property bool statsShowTemp: false   // Temperaturen von CPU/GPU
    readonly property bool statsShowVram: true    // Grafikspeicher anzeigen

    // ===== Akku =====
    readonly property int  batteryLowAt:    15     // ab hier rot (Prozent)
    readonly property bool batteryShowTime: false  // Restzeit anzeigen

    // Symbole: leer, 10 %, 20 % … 90 %, voll
    readonly property var iconsBattery: [
        0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E,
        0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079
    ].map(c => String.fromCodePoint(c))
    readonly property string iconBatteryCharging: String.fromCodePoint(0xF0084)

    // Symbole (Nerd Font) – andere Symbole: https://www.nerdfonts.com/cheat-sheet
    readonly property string iconCpu:  String.fromCodePoint(0xF4BC)
    readonly property string iconGpu:  String.fromCodePoint(0xF08AE)
    readonly property string iconVram: String.fromCodePoint(0xF02F0)
    readonly property string iconRam:  String.fromCodePoint(0xF035B)
}
