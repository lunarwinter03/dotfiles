import QtQuick

Row {
    id: root
    property int strength: 0            // 0–100
    property color activeColor: Theme.fg
    spacing: 1

    Repeater {
        model: 4
        Rectangle {
            required property int index
            anchors.bottom: parent.bottom
            width: 3
            height: 4 + index * 3
            radius: 1
            color: root.strength > index * 25 ? root.activeColor : Theme.outlineVariant
        }
    }
}
