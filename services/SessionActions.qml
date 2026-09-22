import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool available: false
    property string error: "loginctl unavailable"

    function action(name) {
        process.command = ["loginctl", name]
        process.running = true
    }

    Process {
        id: process
        command: ["loginctl", "is-system-running"]
        onExited: function(exitCode) {
            root.available = exitCode === 0 || exitCode === 1
            root.error = root.available ? "" : "loginctl unavailable"
        }
    }
}