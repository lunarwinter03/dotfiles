import QtQuick

Column {
    id: root
    required property var modelData
    property var qsNet: null               // passendes Quickshell-Netz (null = unbekannt)
    property bool expanded: false
    property bool askPassword: false
    property string errorText: ""

    signal toggleExpanded()
    signal connectRequested()
    signal disconnectRequested()
    signal bssidConnectRequested(string bssid)
    signal passwordSubmitted(string psk)
    signal passwordCancelled()

    readonly property var net: modelData
    readonly property var mainAp: net.aps.find(a => a.inUse) ?? net.aps[0]
    readonly property bool multi: net.aps.length > 1
    readonly property bool busy: (qsNet !== null && qsNet.stateChanging)
                              || net.aps.some(a => a.bssid === WifiScan.connectingBssid)

    spacing: 2

    onAskPasswordChanged: if (askPassword) pw.forceActiveFocus()

    // " · 5 GHz" oder "", je nachdem ob die Frequenz bekannt ist
    function bandSuffix(ap) {
        const b = WifiScan.bandLabel(ap.freq)
        return b !== "" ? "  · " + b : ""
    }

    // ===== Hauptzeile =====
    Rectangle {
        width: root.width
        height: 34
        radius: 4
        color: hover.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06) : "transparent"

        // Klick auf freie Fläche klappt auf (Text darüber bleibt markierbar)
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.multi ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (root.multi) root.toggleExpanded()
        }

        SignalBars {
            id: bars
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            strength: root.net.signal
            activeColor: root.net.inUse ? Theme.accent : Theme.fg
        }

        // Rechts: Knopf, Schloss, Pfeil
        Row {
            id: icons
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            SmallButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.net.hidden
                enabled: root.qsNet !== null
                busy: root.busy
                label: root.net.inUse ? "Trennen" : "Verbinden"
                onClicked: root.net.inUse ? root.disconnectRequested() : root.connectRequested()
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.net.security !== ""
                text: Config.iconLock
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 11
                color: Theme.fgDim
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.multi
                text: root.expanded ? Config.iconCollapse : Config.iconExpand
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 13
                color: Theme.fgDim
            }
        }

        // Mitte: Name und darunter die BSSID
        Column {
            anchors.left: bars.right
            anchors.leftMargin: 8
            anchors.right: icons.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            SelectableText {
                text: root.net.hidden ? "Verstecktes Netz" : root.net.ssid
                font.italic: root.net.hidden
                font.bold: root.net.inUse
                color: root.net.hidden ? Theme.fgDim
                     : root.net.inUse  ? Theme.accent
                     : Theme.fg
            }

            Row {
                SelectableText {
                    text: root.mainAp.bssid
                    font.pixelSize: 9
                    font.family: "monospace"
                    color: Theme.fgDim
                }
		Text {
                    text: "   " + root.mainAp.signal + "%" + root.bandSuffix(root.mainAp)
                        + (root.multi ? "   · " + root.net.aps.length + " APs" : "")
                    font.pixelSize: 9
                    font.family: "monospace"
                    color: Theme.fgDim
                }
            }
        }
    }

    // ===== Ausgeklappt: alle Access Points =====
    Column {
        visible: root.expanded && root.multi
        x: 28
        width: root.width - 34
        spacing: 2

        Repeater {
            model: root.net.aps

            Item {
                id: apRow
                required property var modelData
                width: parent.width
                height: 20

                SignalBars {
                    id: apBars
                    anchors.verticalCenter: parent.verticalCenter
                    strength: apRow.modelData.signal
                    activeColor: apRow.modelData.inUse ? Theme.accent : Theme.fgDim
                    scale: 0.75
                }

                Row {
                    anchors.left: apBars.right
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter

                    SelectableText {
                        text: apRow.modelData.bssid
                        font.pixelSize: 9
                        font.family: "monospace"
                        color: apRow.modelData.inUse ? Theme.accent : Theme.fgDim
                    }
		    Text {
                        text: "   " + apRow.modelData.signal + "%" + root.bandSuffix(apRow.modelData)
                        font.pixelSize: 9
                        font.family: "monospace"
                        color: Theme.fgDim
                    }
                }

                SmallButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !apRow.modelData.inUse
                    enabled: root.qsNet !== null && root.qsNet.known
                    busy: WifiScan.connectingBssid === apRow.modelData.bssid
                    label: "Verbinden"
                    onClicked: root.bssidConnectRequested(apRow.modelData.bssid)
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: apRow.modelData.inUse
                    text: "● verbunden"
                    font.pixelSize: 9
                    color: Theme.accent
                }
            }
        }
    }

    // ===== Passwortfeld =====
    Rectangle {
        visible: root.askPassword
        x: 28
        width: root.width - 34
        height: 22
        radius: 4
        color: "transparent"
        border.width: 1
        border.color: Theme.accent

        TextInput {
            id: pw
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            color: Theme.fg
            font.pixelSize: 11
            clip: true

            onAccepted: {
                root.passwordSubmitted(text)
                text = ""
            }
            Keys.onEscapePressed: event => {
                text = ""
                root.passwordCancelled()
                event.accepted = true      // Esc schließt nur das Feld, nicht das Fenster
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: pw.text === ""
            text: "Passwort, Enter zum Verbinden"
            color: Theme.fgDim
            font.pixelSize: 10
        }
    }

    // ===== Fehlermeldung =====
    Text {
        visible: root.errorText !== ""
        x: 28
        text: root.errorText
        color: Theme.urgent
        font.pixelSize: 10
    }
}
