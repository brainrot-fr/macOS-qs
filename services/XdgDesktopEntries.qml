import QtQuick
import Quickshell

Item {
    id: root
    property bool available: true
    property var entries: Quickshell.DesktopEntries.applications

    function search(query) {
        var result = []
        var needle = query.toLowerCase()
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i]
            if (!entry.noDisplay && (needle.length === 0
                    || entry.name.toLowerCase().indexOf(needle) !== -1
                    || entry.id.toLowerCase().indexOf(needle) !== -1))
                result.push(entry)
        }
        return result
    }
}