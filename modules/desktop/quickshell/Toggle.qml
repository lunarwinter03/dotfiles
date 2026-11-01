import QtQuick

Rectangle {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 32
    implicitHeight: 16
    radius: height / 2
    color: checked ? Theme.accent : Theme.outlineVariant

    Rectangle {
        width: 12
        height: 12
        radius: 6
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: Theme.bgBase
        Behavior on x { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
