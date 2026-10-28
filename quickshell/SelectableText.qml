import QtQuick

// Text, der sich markieren und kopieren lässt, aber nicht bearbeiten
TextEdit {
    readOnly: true
    selectByMouse: true
    selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
    selectedTextColor: Theme.fg
    color: Theme.fg
    font.pixelSize: 12
}
