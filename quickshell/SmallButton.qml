import QtQuick

Rectangle {
    id: root
    property string label
    property bool busy: false
    signal clicked()

    implicitWidth: txt.implicitWidth + 12
    implicitHeight: 18
    radius: 4
    color: area.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                              : "transparent"
    border.width: 1
    border.color: enabled ? Theme.accent : Theme.outlineVariant
    opacity: enabled ? 1 : 0.5

    Text {
        id: txt
        anchors.centerIn: parent
        text: root.busy ? "…" : root.label
        color: root.enabled ? Theme.accent : Theme.fgDim
        font.pixelSize: Theme.fontSmall
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.busy
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
