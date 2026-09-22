import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool available: false
    property string owner: ""
    property string error: "No notification delegate"

    function refresh() { process.running = true }
    function openCenter() {
        if (!root.available)
            return
        commandProcess.command = root.owner === "swaync"
            ? ["swaync-client", "-t"]
            : ["makoctl", "restore"]
        commandProcess.running = true
    }

    function dismissAll() {
        if (!root.available)
            return
        commandProcess.command = root.owner === "swaync"
            ? ["swaync-client", "-C"]
            : ["makoctl", "dismiss", "-a"]
        commandProcess.running = true
    }

    Process {
        id: process
        command: ["sh", "-c", "command -v swaync-client >/dev/null && echo swaync || command -v makoctl >/dev/null && echo mako"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.owner = text.trim()
                root.available = root.owner.length > 0
                root.error = root.available ? "" : "No notification delegate"
            }

        }
    }

    Process { id: commandProcess; command: ["true"] }
}