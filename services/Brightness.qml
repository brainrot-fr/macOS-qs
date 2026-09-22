import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool available: false
    property int percentage: 0
    property string error: "Brightness unavailable"

    function refresh() { process.running = true }
    function setPercentage(value) { commandProcess.command = ["brightnessctl", "set", String(value) + "%"]; commandProcess.running = true }

    Process {
        id: process
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/,([0-9]+)%?\?/) || text.match(/,([0-9]+)%/)
                root.available = match !== null
                root.percentage = match ? parseInt(match[1]) : 0
                root.error = root.available ? "" : "Brightness unavailable"
            }
        }
    }

    Process { id: commandProcess; command: ["true"] }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
}