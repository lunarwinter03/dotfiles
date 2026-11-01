import QtQuick
import Quickshell
import Quickshell.Services.Notifications

PopupBox {
    id: card
    required property var notif

    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    readonly property string iconSource: {
        if (notif.image !== "")
            return notif.image
        const icon = notif.appIcon
        if (icon === "")
            return ""
        if (icon.startsWith("/") || icon.includes("://"))
            return icon
        return Quickshell.iconPath(icon, true)
    }

    border.color: critical ? Theme.urgent : Theme.borderFocus

    PopupHeader {
        title: card.notif.summary
        icon: card.iconSource
        titleClickable: true
        onTitleClicked: Notifs.openCenter()

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            text: [card.notif.appName, Notifs.timeText(card.notif)]
                .filter(s => s !== "")
                .join("  ·  ")
            color: Theme.fgDim
            font.pixelSize: Theme.fontSmall
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            color: Theme.fgDim
            font.pixelSize: Theme.fontSmall

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.dismiss(card.notif)
            }
        }
    }

    Text {
        visible: text !== ""
        width: parent.width
        text: card.notif.body
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: 4
        elide: Text.ElideRight
        color: Theme.fg
        font.pixelSize: Theme.fontSmall
    }

    Flow {
        visible: card.notif.actions.length > 0
        width: parent.width
        spacing: Theme.gap

        Repeater {
            model: card.notif.actions

            SmallButton {
                required property var modelData
                label: modelData.text
                onClicked: modelData.invoke()
            }
        }
    }
}
