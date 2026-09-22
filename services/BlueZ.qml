import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool available: false
    property bool powered: false
    property bool connected: false
    property var devices: []
    property string error: "BlueZ unavailable"

    function refresh() { process.running = true }
    function togglePower() {
        commandProcess.command = ["bluetoothctl", "power", root.powered ? "off" : "on"]
        commandProcess.running = true
    }

    Process {
        id: process
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.indexOf("Controller") !== -1
                root.powered = text.indexOf("Powered: yes") !== -1
                root.connected = text.indexOf("Connected: yes") !== -1
                root.error = root.available ? "" : "BlueZ unavailable"
            }

        }
    }

    Process { id: commandProcess; command: ["true"] }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
}