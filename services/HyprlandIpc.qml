import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool available: false
    property int activeWorkspace: 1
    property var workspaces: []
    property var clients: []
    property string error: "Hyprland IPC unavailable"

    function refresh() {
        activeProcess.running = true
        workspacesProcess.running = true
        clientsProcess.running = true
    }

    function dispatch(command) {
        dispatchProcess.command = ["hyprctl", "dispatch"].concat(command.split(" "))
        dispatchProcess.running = true
    }

    function parse(output, fallback) {
        try { return JSON.parse(output) } catch (error) { return fallback }
    }

    Process {
        id: activeProcess
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                var value = root.parse(text, null)
                root.available = value !== null
                if (value)
                    root.activeWorkspace = value.id
            }
        }
    }

    Process {
        id: workspacesProcess
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector { onStreamFinished: root.workspaces = root.parse(text, []) }
    }

    Process {
        id: clientsProcess
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector { onStreamFinished: root.clients = root.parse(text, []) }
    }

    Process { id: dispatchProcess; command: ["hyprctl", "dispatch"] }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}