import QtQuick

// Background, border and padding of a popup. Children stack in a column.
Rectangle {
    id: root
    default property alias content: inner.data
    property bool framed: true

    implicitHeight: inner.implicitHeight + 2 * inner.y
    radius: Theme.radius
    color: framed ? Theme.popupBg : "transparent"
    border.width: framed ? Theme.borderWidth : 0
    border.color: Theme.borderFocus

    Column {
        id: inner
        x: root.framed ? Theme.pad : 0
        y: root.framed ? Theme.pad : 0
        width: parent.width - 2 * x
        spacing: Theme.gap
    }
}
