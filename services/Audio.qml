import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool available: false
    property int volume: 0
    property bool muted: false
    property string error: "PipeWire unavailable"

    function refresh() { process.running = true }
    function setVolume(value) { commandProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(value) + "%"]; commandProcess.running = true }
    function setMuted(value) { commandProcess.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", value ? "1" : "0"]; commandProcess.running = true }

    Process {
        id: process
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/)
                root.available = match !== null
                if (match)
                    root.volume = Math.round(parseFloat(match[1]) * 100)
                root.muted = text.indexOf("[MUTED]") !== -1
                root.error = root.available ? "" : "PipeWire unavailable"
            }
        }
    }

    Process { id: commandProcess; command: ["true"] }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.refresh() }
}