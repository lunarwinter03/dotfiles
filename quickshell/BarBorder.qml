import QtQuick
import QtQuick.Shapes

Item {
    id: root

    // ===== Geometrie =====
    readonly property real bh: Theme.barHeight
    readonly property real dh: Theme.dateHeight
    readonly property real tl: (width - Theme.dateWidth) / 2   // linke Kante Datumsbereich
    readonly property real tr: tl + Theme.dateWidth             // rechte Kante Datumsbereich

    // ===== Stärken =====
    readonly property real w:  Config.borderWidth      // unter der Hauptleiste
    readonly property real t:  Config.borderWidthTab   // um den Datumsbereich
    readonly property real s2: Math.SQRT2              // für die 45°-Ecken

    // ===== Animation: verschiebt das Farbmuster =====
    property real patternShift: 0
    readonly property bool toRight: Config.borderDirection === "right"

    NumberAnimation on patternShift {
        running: Config.borderAnimated && Config.borderMode !== "solid"
        from: root.toRight ? 0 : root.width
        to:   root.toRight ? root.width : 0
        duration: Config.borderSpeed * 1000
        loops: Animation.Infinite
    }

    // ===== Der Rand als gefülltes Band =====
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: Theme.accent                 // für "solid"
            fillGradient: Config.borderMode === "rgb"      ? rgbGradient
                        : Config.borderMode === "gradient" ? themeGradient
                        : null

            // Innenkante = Kontur von Leiste und Datumsbereich (links -> rechts)
            startX: 0;                       startY: root.bh
            PathLine { x: root.tl;           y: root.bh }
            PathLine { x: root.tl + root.dh; y: root.bh + root.dh }
            PathLine { x: root.tr - root.dh; y: root.bh + root.dh }
            PathLine { x: root.tr;           y: root.bh }
            PathLine { x: root.width;        y: root.bh }

            // Außenkante (rechts -> links)
            PathLine { x: root.width;                                    y: root.bh + root.w }
            PathLine { x: root.tr - root.w + root.t * root.s2;           y: root.bh + root.w }
            PathLine { x: root.tr - root.dh - root.t + root.t * root.s2; y: root.bh + root.dh + root.t }
            PathLine { x: root.tl + root.dh + root.t - root.t * root.s2; y: root.bh + root.dh + root.t }
            PathLine { x: root.tl + root.w - root.t * root.s2;           y: root.bh + root.w }
            PathLine { x: 0;                                             y: root.bh + root.w }
            PathLine { x: 0;                                             y: root.bh }
        }
    }

    // ===== Farbmuster =====
    // RepeatSpread wiederholt das Muster endlos, dadurch ist die Animation nahtlos
    LinearGradient {
        id: themeGradient
        x1: root.patternShift;              y1: 0
        x2: root.patternShift + root.width; y2: 0
        spread: ShapeGradient.RepeatSpread
        GradientStop { position: 0.0; color: Config.borderColorA }
        GradientStop { position: 0.5; color: Config.borderColorB }
        GradientStop { position: 1.0; color: Config.borderColorA }
    }

    LinearGradient {
        id: rgbGradient
        x1: root.patternShift;              y1: 0
        x2: root.patternShift + root.width; y2: 0
        spread: ShapeGradient.RepeatSpread
        GradientStop { position: 0/6; color: "#ff0000" }
        GradientStop { position: 1/6; color: "#ffff00" }
        GradientStop { position: 2/6; color: "#00ff00" }
        GradientStop { position: 3/6; color: "#00ffff" }
        GradientStop { position: 4/6; color: "#0000ff" }
        GradientStop { position: 5/6; color: "#ff00ff" }
        GradientStop { position: 6/6; color: "#ff0000" }
    }
}
