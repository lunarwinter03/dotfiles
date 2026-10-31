import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: picker
    required property var targetScreen

    screen: targetScreen
    visible: Popups.wallpaper === targetScreen.name

    readonly property bool vertical: Config.pickerOrientation === "vertical"
    readonly property int thumbW: Config.pickerThumbWidth
    readonly property int thumbH: Math.round(thumbW * 9 / 16)
    readonly property int cellW: thumbW + 12
    readonly property int cellH: thumbH + 12
    readonly property int visibleCount: Math.max(1, Math.min(Config.pickerMaxVisible,
        vertical ? Math.floor(targetScreen.height * 0.9 / cellH)
                 : Math.floor(targetScreen.width  * 0.9 / cellW)))

    // Horizontal: bottom centre. Vertical: right centre.
    anchors.bottom: !vertical
    anchors.right:  vertical
    margins.bottom: vertical ? 0 : 24
    margins.right:  vertical ? 24 : 0
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-wallpaper"

    color: "transparent"
    implicitWidth: box.width
    implicitHeight: box.height

    // ===== Scheme =====
    property int schemeIndex: Math.max(0, Config.pickerSchemes.indexOf(Config.pickerDefaultScheme))
    readonly property string scheme: Config.pickerSchemes[schemeIndex]

    function cycleScheme(delta) {
        const n = Config.pickerSchemes.length
        schemeIndex = (schemeIndex + delta + n) % n
    }

    // ===== Source colours =====
    property var sourceColors: []
    property int sourceIndex: 0
    property var colorCache: ({})          // path -> colours
    property string currentWallpaper: ""   // image currently shown on this screen

    // On the current wallpaper, preselect the source colour of the active theme
    function preferredSourceIndex(path, colors) {
        if (path !== currentWallpaper || Theme.sourceColor === "")
            return 0
        const i = colors.findIndex(c => c.toLowerCase() === Theme.sourceColor.toLowerCase())
        return i >= 0 ? i : 0
    }

    function loadSourceColors() {
        const path = currentPath()
        sourceIndex = 0
        if (path === "") {
            sourceColors = []
        } else if (colorCache[path]) {
            sourceColors = colorCache[path]
            sourceIndex = preferredSourceIndex(path, sourceColors)
        } else {
            sourceColors = []
            colorProc.path = path
            colorProc.exec(["matugen", "image", path, "-m", "dark", "--show-source-colors"])
        }
    }

    function cycleSource(delta) {
        const n = sourceColors.length
        if (n > 0)
            sourceIndex = (sourceIndex + delta + n) % n
    }

    // Only query once the selection rests for a moment
    Timer {
        id: colorDelay
        interval: 150
        onTriggered: picker.loadSourceColors()
    }

    Process {
        id: colorProc
        property string path: ""
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const colors = text.split("\n")
                    .map(s => s.trim())
                    .filter(s => /^#[0-9a-fA-F]{6}$/.test(s))
                picker.colorCache[colorProc.path] = colors
                // Ignore the result if the selection moved on meanwhile
                if (colorProc.path === picker.currentPath()) {
                    picker.sourceColors = colors
                    picker.sourceIndex = picker.preferredSourceIndex(colorProc.path, colors)
                }
            }
        }
    }

    // ===== Images =====
    ListModel {
        id: folder
    }

    function pathAt(i) {
        return (i >= 0 && i < folder.count) ? folder.get(i).filePath : ""
    }

    function nameAt(i) {
        return (i >= 0 && i < folder.count) ? folder.get(i).fileName : ""
    }

    function currentPath() {
        return pathAt(list.currentIndex)
    }

    // -H: picker folders may be symlinks, e.g. into the dotfiles repo
    Process {
        id: scanProc
        command: ["find", "-H"]
            .concat(Config.pickerFolders.map(d => Quickshell.env("HOME") + "/" + d))
            .concat(["-maxdepth", "1", "-type", "f",
                     "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg",
                     "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"])
        stdout: StdioCollector {
            onStreamFinished: picker.fillModel(text)
        }
    }

    function fillModel(output) {
        const items = output.split("\n")
            .filter(p => p !== "")
            .map(p => ({ fileName: p.substring(p.lastIndexOf("/") + 1), filePath: p }))
        items.sort((a, b) => {
            const x = a.fileName.toLowerCase()
            const y = b.fileName.toLowerCase()
            return x < y ? -1 : (x > y ? 1 : 0)
        })
        folder.clear()
        for (const item of items)
            folder.append(item)
        loadSourceColors()
        currentProc.running = true
    }

    // Line format: ": DP-1: 1920x1080, ..., currently displaying: image: /path"
    Process {
        id: currentProc
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const m = line.match(/^\s*:?\s*([^:\s]+):.*image:\s*(.+)$/)
                    if (m && m[1] === picker.targetScreen.name) {
                        picker.currentWallpaper = m[2].trim()
                        picker.selectPath(picker.currentWallpaper)
                        picker.loadSourceColors()
                        return
                    }
                }
            }
        }
    }

    function selectPath(path) {
        for (let i = 0; i < folder.count; i++) {
            if (pathAt(i) === path) {
                list.currentIndex = i
                list.positionViewAtIndex(i, ListView.Center)
                return
            }
        }
    }

    // ===== Navigation and apply =====
    function step(delta) {
        const n = list.count
        if (n > 0)
            list.currentIndex = (list.currentIndex + delta + n) % n
    }

    function apply(index) {
        const path = pathAt(index)
        if (!path)
            return
        // The source colour belongs to the selected image only
        const src = (index === list.currentIndex) ? picker.sourceIndex : 0
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme-apply",
                                 "image", path,
                                 "-m", "dark",
                                 "-t", picker.scheme,
                                 "--source-color-index", String(src)])
        if (Config.pickerCloseOnApply)
            Popups.closeAll()
    }

    onVisibleChanged: {
        if (visible) {
            list.forceActiveFocus()
            scanProc.running = true
        }
    }

    // ===== Box =====
    Rectangle {
        id: box
        width:  (picker.vertical ? picker.cellW : picker.cellW * picker.visibleCount) + 20
        height: (picker.vertical ? picker.cellH * picker.visibleCount : picker.cellH) + 20 + 24 + 22
        radius: Theme.popupRadius
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.outlineVariant

        ListView {
            id: list
            x: 10
            y: 10
            width:  picker.vertical ? picker.cellW : picker.cellW * picker.visibleCount
            height: picker.vertical ? picker.cellH * picker.visibleCount : picker.cellH
            orientation: picker.vertical ? ListView.Vertical : ListView.Horizontal
            model: folder
            clip: true
            focus: true
            keyNavigationEnabled: false

            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: picker.vertical ? (height - picker.cellH) / 2 : (width - picker.cellW) / 2
            preferredHighlightEnd:   preferredHighlightBegin + (picker.vertical ? picker.cellH : picker.cellW)
            highlightMoveDuration: 150

            onCurrentIndexChanged: colorDelay.restart()

            delegate: Item {
                id: entry
                required property int index
                required property string filePath
                readonly property bool current: ListView.isCurrentItem

                width: picker.cellW
                height: picker.cellH

                ClippingRectangle {
                    anchors.centerIn: parent
                    width: picker.thumbW
                    height: picker.thumbH
                    radius: 6
                    scale: entry.current ? 1.0 : 0.85
                    opacity: entry.current ? 1.0 : 0.55
                    Behavior on scale   { NumberAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    Image {
                        anchors.fill: parent
                        // Encode each segment so names with spaces, # or % still load
                        source: "file://" + entry.filePath.split("/").map(encodeURIComponent).join("/")
                        sourceSize.width: picker.thumbW * 2
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: picker.thumbW + 4
                    height: picker.thumbH + 4
                    radius: 8
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.accent
                    visible: entry.current
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.apply(entry.index)
                }
            }

            // Horizontal: a/d image, w/s scheme. Vertical: swapped. q/e source colour.
            Keys.onPressed: event => {
                const k = event.key
                const prev    = picker.vertical ? [Qt.Key_W, Qt.Key_Up]    : [Qt.Key_A, Qt.Key_Left]
                const next    = picker.vertical ? [Qt.Key_S, Qt.Key_Down]  : [Qt.Key_D, Qt.Key_Right]
                const schPrev = picker.vertical ? [Qt.Key_A, Qt.Key_Left]  : [Qt.Key_W, Qt.Key_Up]
                const schNext = picker.vertical ? [Qt.Key_D, Qt.Key_Right] : [Qt.Key_S, Qt.Key_Down]

                if (prev.includes(k))            picker.step(-1)
                else if (next.includes(k))       picker.step(1)
                else if (schPrev.includes(k))    picker.cycleScheme(-1)
                else if (schNext.includes(k))    picker.cycleScheme(1)
                else if (k === Qt.Key_Q)         picker.cycleSource(-1)
                else if (k === Qt.Key_E)         picker.cycleSource(1)
                else if (k === Qt.Key_Space || k === Qt.Key_Return || k === Qt.Key_Enter)
                                                 picker.apply(list.currentIndex)
                else if (k === Qt.Key_Escape)    Popups.closeAll()
                else return

                event.accepted = true
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: label.top
            anchors.bottomMargin: 8
            height: 14
            spacing: 8

            Repeater {
                model: picker.sourceColors

                Rectangle {
                    id: swatch
                    required property string modelData
                    required property int index
                    readonly property bool selected: index === picker.sourceIndex

                    width: 14
                    height: 14
                    radius: 7
                    color: modelData
                    scale: selected ? 1.25 : 1.0
                    border.width: selected ? 2 : 1
                    border.color: selected ? Theme.fg : Theme.outlineVariant
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: picker.sourceIndex = swatch.index
                    }
                }
            }
        }

        Text {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            width: parent.width - 20
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            text: "   ◂ " + picker.scheme.replace("scheme-", "") + " ▸"
            color: Theme.fgDim
            font.pixelSize: Theme.fontSmall
        }
    }
}
