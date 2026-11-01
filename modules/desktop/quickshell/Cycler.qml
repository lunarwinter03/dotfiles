import QtQuick

// "◂ value ▸". Keys are handled by the popup; the mouse is a convenience.
Text {
    id: root
    property string value
    signal step(int delta)

    text: "◂ " + value + " ▸"
    color: Theme.fgDim
    font.pixelSize: Theme.fontSmall

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.step(mouse.button === Qt.RightButton ? -1 : 1)
    }
}
