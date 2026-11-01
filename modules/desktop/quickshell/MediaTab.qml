import QtQuick
import QtQuick.Shapes
import Quickshell.Services.Mpris

// Tab below the bar at the left screen edge: |____/
// As wide as its text, up to Config.mediaMaxWidth; longer titles scroll.
Item {
    id: root

    // Playing player first, otherwise the first one; ignored players are skipped
    readonly property var player: {
        const ignore = Config.mediaIgnore.map(s => s.toLowerCase())
        const ignored = p => [p.identity, p.desktopEntry, p.dbusName]
            .some(v => v && ignore.some(i => v.toLowerCase().includes(i)))
        const all = Mpris.players.values.filter(p => !ignored(p))
        return all.find(p => p.isPlaying) ?? all[0] ?? null
    }

    readonly property bool active: Config.mediaShow && player !== null
    readonly property string title: !player ? ""
        : [player.trackArtist, player.trackTitle].filter(s => s).join(" – ")

    // Space for the title: padding, icon and the slanted right side are taken
    readonly property real textRoom: Config.mediaMaxWidth - Theme.pad - icon.width - Theme.gap - height
    readonly property bool scrolling: measure.implicitWidth > textRoom

    // Width 0 when inactive, so the bar mask and border skip it
    width: active
        ? Math.round(Theme.pad + icon.width + Theme.gap + Math.min(measure.implicitWidth, textRoom) + height)
        : 0
    height: Theme.dateHeight
    visible: active

    onTitleChanged: restartTicker()
    onScrollingChanged: restartTicker()

    function restartTicker() {
        tickerAnim.stop()
        ticker.x = 0
        if (scrolling)
            tickerAnim.start()
    }

    Text {
        id: measure
        visible: false
        text: root.title
        font.pixelSize: Theme.fontSmall
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Theme.bgBottom
            strokeColor: "transparent"
            startX: 0; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width - root.height; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    // Shows what a click does: pause while playing, play while paused
    Text {
        id: icon
        x: Theme.pad
        height: root.height
        verticalAlignment: Text.AlignVCenter
        text: root.player && root.player.isPlaying ? Config.iconPause : Config.iconPlay
        font.family: Theme.fontIcons
        font.pixelSize: Theme.fontSmall * 0.75
        color: Theme.fgDim
    }

    Item {
        x: icon.x + icon.width + Theme.gap
        width: root.width - x - root.height
        height: root.height
        clip: true

        // Two copies side by side; moving by one copy's width loops seamlessly
        Row {
            id: ticker
            height: parent.height
            spacing: 32

            Text {
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: root.title
                color: Theme.fgDim
                font.pixelSize: Theme.fontSmall
            }

            Text {
                visible: root.scrolling
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: root.title
                color: Theme.fgDim
                font.pixelSize: Theme.fontSmall
            }

            NumberAnimation on x {
                id: tickerAnim
                running: false
                from: 0
                to: -(measure.implicitWidth + ticker.spacing)
                duration: (measure.implicitWidth + ticker.spacing) * 1000 / Config.mediaScrollSpeed
                loops: Animation.Infinite
            }
        }
    }

    // Left: play/pause. Right: next track.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (!root.player)
                return
            if (mouse.button === Qt.RightButton) {
                if (root.player.canGoNext)
                    root.player.next()
            } else if (root.player.canTogglePlaying) {
                root.player.togglePlaying()
            }
        }
    }
}
