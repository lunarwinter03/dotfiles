pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // --- Farben (Platzhalter, werden später aus matugen gelesen) ---
    // Achtung: In QML ist das Format #AARRGGBB, Alpha steht VORNE!
        // --- Hintergrund ---
    // Grundfarbe ohne Deckkraft (wird später von matugen geliefert)
    readonly property color bgBase: "#1a1b1e"
    // Deckkraft oben und unten (0.0 = unsichtbar, 1.0 = voll deckend)
    readonly property real bgAlphaTop:    0.9
    readonly property real bgAlphaBottom: 0.7

    readonly property color bgTop:    Qt.rgba(bgBase.r, bgBase.g, bgBase.b, bgAlphaTop)
    readonly property color bgBottom: Qt.rgba(bgBase.r, bgBase.g, bgBase.b, bgAlphaBottom)
    readonly property color fg:     "#d4d4d8"
    readonly property color fgDim:  "#7a808c"
    readonly property color accent: "#61afef"

    // --- Maße ---
    readonly property int barHeight:  25
    readonly property int dateHeight: 10
    readonly property int dateWidth:  100
}
