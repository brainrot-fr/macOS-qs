import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool available: false
    property bool onBattery: false
    property int percentage: 0
    property string state: "unknown"
    property string error: "UPower unavailable"

    function refresh() { process.running = true }

    Process {
        id: process
        command: ["upower", "-i", "/org/freedesktop/UPower/devices/DisplayDevice"]
        stdout: StdioCollector {
            onStreamFinished: {
                var percentage = text.match(/percentage:\s+([0-9]+)/i)
                var state = text.match(/state:\s+(\S+)/i)
                root.available = percentage !== null
                root.percentage = percentage ? parseInt(percentage[1]) : 0
                root.state = state ? state[1] : "unknown"
                root.onBattery = root.state === "discharging"
                root.error = root.available ? "" : "UPower unavailable"
            }
        }
    }

    Timer { interval: 10000; running: true; repeat: true; onTriggered: root.refresh() }
}