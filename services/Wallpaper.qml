import QtQuick

Item {
    id: root
    property bool enabled: false
    property bool available: true
    property string imagePath: ""
    property string error: ""

    // Wallpaper surfaces are rendered by the shell so no external daemon owns them.
    function setImage(path) {
        root.imagePath = path
        root.enabled = path.length > 0
    }
}