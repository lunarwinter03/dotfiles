pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ===== Farben aus matugen (live) =====
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/theme/colors.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: c
            // Standardwerte gelten, solange die Datei fehlt oder unlesbar ist
            property string surface:            "#1a1b1e"
            property string on_surface:         "#d4d4d8"
            property string on_surface_variant: "#7a808c"
            property string primary:            "#61afef"
            property string tertiary:           "#c678dd"
            property string outline_variant:    "#3a3d44"
            property string error:              "#e06c75"
        }
    }

    // ===== Farbnamen für die Leiste =====
    readonly property color bgBase:         c.surface
    readonly property color fg:             c.on_surface
    readonly property color fgDim:          c.on_surface_variant
    readonly property color accent:         c.primary
    readonly property color accentAlt:      c.tertiary
    readonly property color outlineVariant: c.outline_variant
    readonly property color urgent:         c.error

    // Alpha
    readonly property real bgAlphaTop:    0.9
    readonly property real bgAlphaBottom: 0.7
    readonly property color bgTop:    Qt.rgba(bgBase.r, bgBase.g, bgBase.b, bgAlphaTop)
    readonly property color bgBottom: Qt.rgba(bgBase.r, bgBase.g, bgBase.b, bgAlphaBottom)
    
    // --- Tags ---
    readonly property int tagSize:        18   // Kantenlänge der Kästchen
    readonly property int tagRadius:      3
    readonly property int tagBorderWidth: 1

    // --- Maße ---
    readonly property int barHeight:  25
    readonly property int dateHeight: 10
    readonly property int dateWidth:  100
    readonly property int groupGap: 24
}
