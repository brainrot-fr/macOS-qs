import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool available: false
    property bool connected: false
    property string connection: ""
    property string error: "NetworkManager unavailable"

    function refresh() { process.running = true }
    function toggleWifi() {
        commandProcess.command = ["nmcli", "radio", "wifi", root.connected ? "off" : "on"]
        commandProcess.running = true
    }

    Process {
        id: process
        command: ["nmcli", "-t", "-f", "GENERAL.STATE,GENERAL.CONNECTION", "device", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                root.available = text.trim().length > 0
                root.connected = lines.length > 0 && lines[0].indexOf("connected") !== -1
                root.connection = root.connected && lines.length > 1 ? lines[1] : ""
                root.error = root.available ? "" : "NetworkManager unavailable"
            }

        }
    }

    Process { id: commandProcess; command: ["true"] }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
}