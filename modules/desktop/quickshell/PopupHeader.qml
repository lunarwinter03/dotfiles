import QtQuick
import Quickshell.Widgets

// Title (optionally with icon) on the left, controls on the right
Item {
    id: root
    property string title
    property string icon: ""
    property bool titleClickable: false
    default property alias controls: right.data
    signal titleClicked()

    width: parent ? parent.width : 0
    implicitHeight: 18

    IconImage {
        id: iconItem
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.icon !== ""
        source: root.icon
        implicitSize: 16
    }

    Text {
        anchors.left: iconItem.visible ? iconItem.right : parent.left
        anchors.leftMargin: iconItem.visible ? Theme.gap : 0
        anchors.right: right.left
        anchors.rightMargin: Theme.gap
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        elide: Text.ElideRight
        color: Theme.fg
        font.pixelSize: Theme.fontLarge
        font.bold: true

        MouseArea {
            anchors.fill: parent
            enabled: root.titleClickable
            cursorShape: Qt.PointingHandCursor
            onClicked: root.titleClicked()
        }
    }

    Row {
        id: right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.gap
    }
}
