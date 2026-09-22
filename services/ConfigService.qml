import QtQuick
import QtCore
import Quickshell.Io

Item {
    id: root

    readonly property string configPath:
        StandardPaths.writableLocation(StandardPaths.ConfigLocation)
        + "/macos-qs/config.json"
    property bool loaded: false
    property bool valid: true
    property bool directoryReady: false
    property var pinnedIds: ["firefox", "org.kde.dolphin", "foot"]
    property var moduleVisibility: ({
        wifi: true,
        volume: true,
        battery: true,
        bluetooth: true,
        inputLayout: true,
        notifications: true,
        controlCenter: true,
        userSession: true
    })
    signal configChanged()

    function moduleEnabled(name) {
        return moduleVisibility[name] === true
    }

    function defaults() {
        return {
            schemaVersion: 1,
            autostart: true,
            modules: {
                wifi: true, volume: true, battery: true, bluetooth: true,
                inputLayout: true, notifications: true, controlCenter: true,
                userSession: true
            },
            dock: { pinnedIds: ["firefox", "org.kde.dolphin", "foot"] },
            logging: { level: "info" }
        }
    }

    function validConfig(value) {
        if (!value || value.schemaVersion !== 1 || typeof value.autostart !== "boolean")
            return false
        if (!value.modules || typeof value.modules !== "object")
            return false
        var names = ["wifi", "volume", "battery", "bluetooth", "inputLayout",
            "notifications", "controlCenter", "userSession"]
        for (var i = 0; i < names.length; i++) {
            if (value.modules[names[i]] !== undefined
                    && typeof value.modules[names[i]] !== "boolean")
                return false
        }
        if (value.dock !== undefined
                && (!value.dock.pinnedIds || !Array.isArray(value.dock.pinnedIds)
                    || !value.dock.pinnedIds.every(function(id) {
                        return typeof id === "string"
                    })))
            return false
        return !value.logging || !value.logging.level
            || ["debug", "info", "warning", "error"].indexOf(value.logging.level) !== -1
    }

    function apply(value) {
        var defaultsValue = defaults()
        var modules = value.modules || defaultsValue.modules
        var pins = value.dock && value.dock.pinnedIds
            ? value.dock.pinnedIds : defaultsValue.dock.pinnedIds
        var nextModules = {}
        Object.keys(defaultsValue.modules).forEach(function(name) {
            nextModules[name] = modules[name] === undefined
                ? defaultsValue.modules[name] : modules[name]
        })
        moduleVisibility = nextModules
        pinnedIds = pins
        configChanged()
    }

    function save() {
        var value = defaults()
        value.modules = moduleVisibility
        value.dock.pinnedIds = pinnedIds
        configFile.setText(JSON.stringify(value, null, 2) + "\n")
        configFile.writeAdapter()
    }

    function load() {
        if (!configFile.loaded)
            return
        var text = configFile.text()
        if (!text || text.trim().length === 0) {
            valid = true
            apply(defaults())
            save()
            loaded = true
            return
        }
        try {
            var value = JSON.parse(text)
            valid = validConfig(value)
            apply(valid ? value : defaults())
        } catch (error) {
            valid = false
            apply(defaults())
        }
        loaded = true
    }

    Process {
        id: directoryProcess
        command: ["mkdir", "-p", configFile.path.substring(0, configFile.path.lastIndexOf("/"))]
        running: true
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.directoryReady = true
                configFile.reload()
            }
        }
    }

    FileView {
        id: configFile
        path: root.configPath
        preload: true
        watchChanges: false
        atomicWrites: true
        printErrors: false
        onLoaded: root.load()
        onLoadFailed: {
            if (!root.directoryReady)
                return
            root.valid = true
            root.apply(root.defaults())
            root.save()
            root.loaded = true
        }
    }
}
