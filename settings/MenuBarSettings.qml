import QtQuick

Item {
    id: root
    property var config
    property bool wifi: true
    property bool volume: true
    property bool battery: true
    property bool bluetooth: true
    property bool inputLayout: true
    property bool notifications: true
    property bool controlCenter: true
    property bool userSession: true

    function sync() {
        if (!config)
            return
        wifi = config.moduleEnabled("wifi")
        volume = config.moduleEnabled("volume")
        battery = config.moduleEnabled("battery")
        bluetooth = config.moduleEnabled("bluetooth")
        inputLayout = config.moduleEnabled("inputLayout")
        notifications = config.moduleEnabled("notifications")
        controlCenter = config.moduleEnabled("controlCenter")
        userSession = config.moduleEnabled("userSession")
    }

    onConfigChanged: sync()
    Connections {
        target: root.config
        function onConfigChanged() { root.sync() }
    }
}