import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool available: false
    property string layout: "--"
    property string error: "Input layout unavailable"

    function refresh() { process.running = true }

    Process {
        id: process
        command: ["sh", "-c", "setxkbmap -query 2>/dev/null | awk '/^[[:space:]]*layout:/{print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var value = text.trim()
                root.available = value.length > 0
                root.layout = root.available ? value.toUpperCase() : "--"
                root.error = root.available ? "" : "Input layout unavailable"
            }
        }
    }

    Timer { interval: 10000; running: true; repeat: true; onTriggered: root.refresh() }
}