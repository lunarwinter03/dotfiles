import QtQuick

Column {
    id: root
    required property var modelData
    property var qsNet: null            // matching Quickshell network, null if unknown
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

    function bandSuffix(ap) {
        const b = WifiScan.bandLabel(ap.freq)
        return b !== "" ? " · " + b : ""
    }

    // ===== Main row =====
    Rectangle {
        width: root.width
        height: 34
        radius: Theme.radius
        color: hover.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06) : "transparent"

        // Click on free space expands; text on top stays selectable
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.multi ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (root.multi) root.toggleExpanded()
        }

        SignalBars {
            id: bars
            x: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            strength: root.net.signal
            activeColor: root.net.inUse ? Theme.accent : Theme.fg
        }

        Row {
            id: icons
            anchors.right: parent.right
            anchors.rightMargin: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gap

            SmallButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.net.hidden
                enabled: root.qsNet !== null
                busy: root.busy
                label: root.net.inUse ? "Disconnect" : "Connect"
                onClicked: root.net.inUse ? root.disconnectRequested() : root.connectRequested()
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.net.security !== ""
                text: Config.iconLock
                font.family: Theme.fontIcons
                font.pixelSize: Theme.fontIcon
                color: Theme.fgDim
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.multi
                text: root.expanded ? Config.iconCollapse : Config.iconExpand
                font.family: Theme.fontIcons
                font.pixelSize: Theme.fontIcon
                color: Theme.fgDim
            }
        }

        Column {
            anchors.left: bars.right
            anchors.leftMargin: Theme.pad
            anchors.right: icons.left
            anchors.rightMargin: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            SelectableText {
                text: root.net.hidden ? "Hidden network" : root.net.ssid
                font.italic: root.net.hidden
                font.bold: root.net.inUse
                color: root.net.hidden ? Theme.fgDim
                     : root.net.inUse  ? Theme.accent
                     : Theme.fg
            }

            Row {
                SelectableText {
                    text: root.mainAp.bssid
                    font.pixelSize: Theme.fontSmall
                    font.family: Theme.fontMono
                    color: Theme.fgDim
                }
                Text {
                    text: "  " + root.mainAp.signal + "%" + root.bandSuffix(root.mainAp)
                          + (root.multi ? " · " + root.net.aps.length + " APs" : "")
                    font.pixelSize: Theme.fontSmall
                    font.family: Theme.fontMono
                    color: Theme.fgDim
                }
            }
        }
    }

    // ===== Expanded: all access points =====
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
                    anchors.leftMargin: Theme.gap
                    anchors.verticalCenter: parent.verticalCenter

                    SelectableText {
                        text: apRow.modelData.bssid
                        font.pixelSize: Theme.fontSmall
                        font.family: Theme.fontMono
                        color: apRow.modelData.inUse ? Theme.accent : Theme.fgDim
                    }
                    Text {
                        text: "  " + apRow.modelData.signal + "%" + root.bandSuffix(apRow.modelData)
                        font.pixelSize: Theme.fontSmall
                        font.family: Theme.fontMono
                        color: Theme.fgDim
                    }
                }

                SmallButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !apRow.modelData.inUse
                    enabled: root.qsNet !== null && root.qsNet.known
                    busy: WifiScan.connectingBssid === apRow.modelData.bssid
                    label: "Connect"
                    onClicked: root.bssidConnectRequested(apRow.modelData.bssid)
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: apRow.modelData.inUse
                    text: "● connected"
                    font.pixelSize: Theme.fontSmall
                    color: Theme.accent
                }
            }
        }
    }

    // ===== Password =====
    Rectangle {
        visible: root.askPassword
        x: 28
        width: root.width - 34
        height: 22
        radius: Theme.radius
        color: "transparent"
        border.width: Theme.borderWidth
        border.color: Theme.borderFocus

        TextInput {
            id: pw
            anchors.fill: parent
            anchors.leftMargin: Theme.gap
            anchors.rightMargin: Theme.gap
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            color: Theme.fg
            font.pixelSize: Theme.fontSmall
            clip: true

            onAccepted: {
                root.passwordSubmitted(text)
                text = ""
            }
            Keys.onEscapePressed: event => {
                text = ""
                root.passwordCancelled()
                event.accepted = true    // Esc closes the field, not the window
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            visible: pw.text === ""
            text: "Password, Enter to connect"
            color: Theme.fgDim
            font.pixelSize: Theme.fontSmall
        }
    }

    Text {
        visible: root.errorText !== ""
        x: 28
        text: root.errorText
        color: Theme.urgent
        font.pixelSize: Theme.fontSmall
    }
}
