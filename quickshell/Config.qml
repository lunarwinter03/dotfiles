pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // ===== Unterkante der Leiste =====
    // "none"     = aus
    // "solid"    = einfarbig (Akzentfarbe)
    // "gradient" = Verlauf zwischen zwei Theme-Farben
    // "rgb"      = Regenbogen
    readonly property string borderMode: "rgb"

    readonly property real borderWidth:    1.6     // unter der Hauptleiste, in px
    readonly property real borderWidthTab: 0.6   // um den Datumsbereich, in px
    readonly property bool borderAnimated: true // nur für gradient/rgb
    readonly property real borderSpeed: 5       // Sekunden pro Durchlauf
    readonly property string borderDirection: "right" // Richtung wohin (to) <left|right>

    // Farben für "gradient"
    readonly property color borderColorA: Theme.accent
    readonly property color borderColorB: Theme.accentAlt
}
