pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Fertig formatierte Texte, die die Leisten nur anzeigen
    readonly property string time: Qt.formatDateTime(clock.date, "hh:mm:ss")
    readonly property string date: Qt.formatDateTime(clock.date, "dd-MM-yyyy")

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
