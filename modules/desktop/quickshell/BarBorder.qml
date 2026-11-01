import QtQuick
import QtQuick.Shapes

Item {
    id: root

    // ===== Geometry (positions on whole pixels, thickness may be fractional) =====
    readonly property real bh: Theme.barHeight
    readonly property real dh: Theme.dateHeight
    readonly property real tl: Math.round((width - Theme.dateWidth) / 2)   // left edge of the date tab
    readonly property real tr: tl + Theme.dateWidth                         // right edge of the date tab

    // Media tab at the left edge, 0 when hidden (also guards against NaN)
    property real mediaWidth: 0
    readonly property real mw: mediaWidth > 0 ? Math.round(mediaWidth) : 0
    readonly property bool mv: mw > 0

    // ===== Thickness =====
    readonly property real w: Config.borderWidth       // below the bar
    readonly property real t: Config.borderWidthTab    // around the tabs
    readonly property real s2: Math.SQRT2              // for the 45° corners

    readonly property real wJoin: Config.borderTaper ? w * (s2 - 1) : t * s2 - w

    readonly property color colorA: Theme.boost(Config.borderColorA, Config.borderSaturation, Config.borderLightness)
    readonly property color colorB: Theme.boost(Config.borderColorB, Config.borderSaturation, Config.borderLightness)

    // ===== Animation: moves the colour pattern =====
    property real patternShift: 0
    readonly property bool toRight: Config.borderDirection === "right"

    NumberAnimation on patternShift {
        running: Config.borderAnimated && Config.borderMode !== "solid"
        from: root.toRight ? 0 : root.width
        to:   root.toRight ? root.width : 0
        duration: Config.borderSpeed * 1000
        loops: Animation.Infinite
    }

    // ===== The border as a filled band =====
    // Slants taper from the bar's thickness (top) to the tab's thickness (bottom)
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: Theme.accent
            fillGradient: Config.borderMode === "rgb"      ? rgbGradient
                        : Config.borderMode === "gradient" ? themeGradient
                        : null

            // Inner edge, left to right: media tab, bar, date tab, bar
            startX: 0; startY: root.mv ? root.bh + root.dh : root.bh
            PathLine { x: root.mv ? root.mw - root.dh : 0; y: root.mv ? root.bh + root.dh : root.bh }
            PathLine { x: root.mw;               y: root.bh }
            PathLine { x: root.tl;               y: root.bh }
            PathLine { x: root.tl + root.dh;     y: root.bh + root.dh }
            PathLine { x: root.tr - root.dh;     y: root.bh + root.dh }
            PathLine { x: root.tr;               y: root.bh }
            PathLine { x: root.width;            y: root.bh }

            // Outer edge, right to left: bar, date tab, bar, media tab
            PathLine { x: root.width;                                     y: root.bh + root.w }
            PathLine { x: root.tr + root.wJoin;                           y: root.bh + root.w }
            PathLine { x: root.tr - root.dh - root.t + root.t * root.s2;  y: root.bh + root.dh + root.t }
            PathLine { x: root.tl + root.dh + root.t - root.t * root.s2;  y: root.bh + root.dh + root.t }
            PathLine { x: root.tl - root.wJoin;                           y: root.bh + root.w }
            PathLine { x: root.mv ? root.mw + root.wJoin : 0;             y: root.bh + root.w }
            PathLine { x: root.mv ? root.mw - root.dh - root.t + root.t * root.s2 : 0
                       y: root.mv ? root.bh + root.dh + root.t : root.bh + root.w }
            PathLine { x: 0; y: root.mv ? root.bh + root.dh + root.t : root.bh + root.w }
            PathLine { x: 0; y: root.mv ? root.bh + root.dh : root.bh }
        }
    }

    // ===== Colour patterns =====
    // RepeatSpread repeats the pattern endlessly, so the animation is seamless
    LinearGradient {
        id: themeGradient
        x1: root.patternShift; y1: 0
        x2: root.patternShift + root.width; y2: 0
        spread: ShapeGradient.RepeatSpread
        GradientStop { position: 0.0; color: root.colorA }
        GradientStop { position: 0.5; color: root.colorB }
        GradientStop { position: 1.0; color: root.colorA }
    }

    LinearGradient {
        id: rgbGradient
        x1: root.patternShift; y1: 0
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
