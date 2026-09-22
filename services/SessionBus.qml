import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool available: false
    property string error: "Session bus unavailable"
    signal reply(string output)

    function check() {
        checkProcess.running = true
    }

    function call(service, objectPath, interfaceName, member, signature, args) {
        var command = ["busctl", "--user", "--quiet", "call", service, objectPath,
            interfaceName, member]
        if (signature && signature.length > 0)
            command.push(signature)
        if (args) {
            for (var i = 0; i < args.length; i++)
                command.push(String(args[i]))
        }
        callProcess.command = command
        callProcess.running = true
    }

    Process {
        id: checkProcess
        command: ["busctl", "--user", "--no-pager", "list"]
        onExited: function(exitCode) {
            root.available = exitCode === 0
            root.error = root.available ? "" : "Session bus unavailable"
        }
    }

    Process {
        id: callProcess
        stdout: StdioCollector {
            onStreamFinished: root.reply(text)
        }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.available = false
                root.error = "DBus call failed"
            }
        }
    }
}