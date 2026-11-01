import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: center
    required property var targetScreen
    readonly property bool newestFirst: Config.notificationHistoryOrder === "newest"

    function scrollToNewest() {
        if (newestFirst)
            list.positionViewAtBeginning()
        else
            list.positionViewAtEnd()
    }

    screen: targetScreen
    visible: Popups.notifications === targetScreen.name

    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    margins {
        top: Theme.barHeight + (Config.borderMode !== "none" ? Config.borderWidth : 0) + Theme.gap
        right: Theme.pad
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-notification-center"

    color: "transparent"
    implicitWidth: Config.notificationWidth
    implicitHeight: Config.notificationCenterMaxHeight + 100
    mask: Region { item: content }

    onVisibleChanged: {
        if (visible) {
            content.forceActiveFocus()
            list.positionViewAtEnd()
        }
    }

    FocusScope {
        id: content
        width: parent.width
        height: box.height
        focus: true

        onActiveFocusChanged: if (!activeFocus && center.visible) Popups.closeAll()

        // a/d, left/right: screen. Space: do not disturb. x: clear. Esc: close.
        Keys.onPressed: event => {
            const k = event.key
            if (k === Qt.Key_A || k === Qt.Key_Left)        Notifs.cycleScreen(-1)
            else if (k === Qt.Key_D || k === Qt.Key_Right)  Notifs.cycleScreen(1)
            else if (k === Qt.Key_Space)                    Notifs.setDnd(!Notifs.dnd)
            else if (k === Qt.Key_X)                        Notifs.clearAll()
            else if (k === Qt.Key_Escape)                   Popups.closeAll()
            else return
            event.accepted = true
        }

        PopupBox {
            id: box
            width: parent.width

            PopupHeader {
                title: "Notifications"

                SmallButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Notifs.history.length > 0
                    label: "Clear"
                    onClicked: Notifs.clearAll()
                }
            }

            Item {
                width: parent.width
                height: 18

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.gap

                    Text {
                        text: "Screen"
                        color: Theme.fgDim
                        font.pixelSize: Theme.fontSmall
                    }

                    Cycler {
                        value: Notifs.screenChoice === "" ? "Auto" : Notifs.screenChoice
                        onStep: delta => Notifs.cycleScreen(delta)
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.gap

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Do not disturb"
                        color: Theme.fgDim
                        font.pixelSize: Theme.fontSmall
                    }

                    Toggle {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: Notifs.dnd
                        onToggled: Notifs.setDnd(!Notifs.dnd)
                    }
                }
            }

            Separator {}

            ListView {
                id: list
                width: parent.width
                height: Math.min(contentHeight, Config.notificationCenterMaxHeight)
                clip: true
                spacing: Theme.gap
                model: Notifs.history
                onCountChanged: positionViewAtEnd()
		Component.onCompleted: positionViewAtEnd()

                delegate: NotificationCard {
                    required property var modelData
                    width: list.width
                    notif: modelData
                }
            }

            Text {
                visible: list.count === 0
                text: "No notifications"
                color: Theme.fgDim
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
