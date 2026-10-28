pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Monitor, auf dem das Netzwerk-Fenster offen ist ("" = geschlossen)
    property string network: ""

    function closeAll() {
        network = ""
    }
}
