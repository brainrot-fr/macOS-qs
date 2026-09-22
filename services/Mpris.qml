import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool available: false
    property string player: ""
    property string title: ""
    property string artist: ""
    property string status: "Stopped"
    property string error: "No MPRIS player"

    function refresh() { process.running = true }
    function command(action) { actionProcess.command = ["playerctl", action]; actionProcess.running = true }

    Process {
        id: process
        command: ["playerctl", "metadata", "--format", "{{playerName}}\t{{status}}\t{{artist}}\t{{title}}"]
        stdout: StdioCollector {
            onStreamFinished: {
                var fields = text.trim().split("\t")
                root.available = fields.length >= 4 && fields[0].length > 0
                root.player = root.available ? fields[0] : ""
                root.status = root.available ? fields[1] : "Stopped"
                root.artist = root.available ? fields[2] : ""
                root.title = root.available ? fields[3] : ""
                root.error = root.available ? "" : "No MPRIS player"
            }
        }
    }

    Process { id: actionProcess; command: ["playerctl", "play-pause"] }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: root.refresh() }
}