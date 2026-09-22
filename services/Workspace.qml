import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property int activeId: 1
    property var ids: [1, 2, 3, 4, 5]
    property var clients: []
    property var activeClient: ({})

    function refresh() {
        activeProcess.running = true
        clientsProcess.running = true
        activeClientProcess.running = true
    }

    function switchTo(id) {
        switchProcess.command = ["hyprctl", "dispatch", "workspace", String(id)]
        switchProcess.running = true
    }

    Process {
        id: activeProcess
        command: ["sh", "-c", "hyprctl activeworkspace -j 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.activeId = JSON.parse(text).id
                } catch (error) {
                    root.activeId = 1
                }
            }
        }
    }

    Process {
        id: clientsProcess
        command: ["sh", "-c", "hyprctl clients -j 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.clients = JSON.parse(text)
                } catch (error) {
                    root.clients = []
                }
            }
        }
    }

    Process {
        id: activeClientProcess
        command: ["sh", "-c", "hyprctl activewindow -j 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.activeClient = JSON.parse(text)
                } catch (error) {
                    root.activeClient = ({})
                }
            }
        }
    }

    Process {
        id: switchProcess
        command: ["hyprctl", "dispatch", "workspace", "1"]
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}