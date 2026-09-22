import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string label: "Network unavailable"
    property bool connected: false

    function refresh() {
        process.running = true
    }

    Process {
        id: process
        command: ["sh", "-c", "nmcli -t -f GENERAL.STATE,GENERAL.CONNECTION device show 2>/dev/null | head -n 2"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\\n")
                root.connected = lines.length > 0 && lines[0].indexOf("connected") !== -1
                root.label = root.connected && lines.length > 1 && lines[1].length > 0
                    ? lines[1]
                    : "Network unavailable"
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}