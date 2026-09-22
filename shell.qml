import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "services"
import "modules"
import "settings"

ShellRoot {
    id: root

    property string clockText: ""
    property string searchText: ""
    property bool launcherOpen: false
    property var pinnedIds: config.pinnedIds
    property var applications: DesktopEntries.applications
    property string activeApplication: "Desktop"
    property bool controlCenterOpen: false
    property bool sessionMenuOpen: false
    property bool overviewOpen: false
    property bool doNotDisturb: false
    property string pendingSessionAction: ""

    Workspace {
        id: workspace
    }

    NetworkManager {
        id: network
    }

    Audio { id: audio }
    UPower { id: battery }
    BlueZ { id: bluetooth }
    InputLayout { id: inputLayout }
    Notifications { id: notifications }
    Brightness { id: brightness }
    Mpris { id: mpris }
    SessionActions { id: session }
    ConfigService { id: config }
    MenuBarSettings { id: menuBarSettings; config: config }

    function updateClock() {
        clockText = Qt.formatDateTime(new Date(), "ddd, MMM d  HH:mm")
    }

    function updateActiveApplication() {
        activeApplication = workspace.activeClient.title
            ? workspace.activeClient.title
            : (workspace.activeClient.class || "Desktop")
    }

    function appMatches(app) {
        if (!app || app.noDisplay)
            return false
        if (searchText.length === 0)
            return true
        var query = searchText.toLowerCase()
        return app.name.toLowerCase().indexOf(query) !== -1
            || app.genericName.toLowerCase().indexOf(query) !== -1
            || app.id.toLowerCase().indexOf(query) !== -1
    }

    function isRunning(app) {
        return runningClient(app) !== null
    }

    function runningClient(app) {
        for (var i = 0; i < workspace.clients.length; i++) {
            var client = workspace.clients[i]
            if (client.class && app.id.toLowerCase().indexOf(client.class.toLowerCase()) !== -1)
                return client
        }
        return null
    }

    function launch(app) {
        if (!app)
            return
        var client = runningClient(app)
        if (client) {
            focusProcess.command = ["hyprctl", "dispatch", "focuswindow", "class:" + client.class]
            focusProcess.running = true
        } else {
            app.execute()
        }
        launcherOpen = false
        searchText = ""
    }

    function confirmSession(action) {
        pendingSessionAction = action
        sessionConfirmation.open()
    }

    onLauncherOpenChanged: {
        if (launcherOpen)
            searchField.forceActiveFocus()
    }

    Component.onCompleted: {
        updateClock()
        workspace.refresh()
        network.refresh()
        audio.refresh()
        battery.refresh()
        bluetooth.refresh()
        inputLayout.refresh()
        notifications.refresh()
        brightness.refresh()
        mpris.refresh()
        updateActiveApplication()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateClock()
    }

    Connections {
        target: workspace
        function onClientsChanged() { root.updateActiveApplication() }
        function onActiveClientChanged() { root.updateActiveApplication() }
    }

    Process {
        id: focusProcess
        command: ["hyprctl", "dispatch", "focuswindow", "class:"]
    }

    Process { id: dockProcess; command: ["true"] }

    PanelWindow {
        id: bar
        anchors.top: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 38
        exclusiveZone: implicitHeight
        color: "transparent"
        focusable: true

        Rectangle {
            anchors.fill: parent
            color: "#f5f5f7"
            border.color: "#d2d2d7"
            border.width: 1

            Item {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14

                Row {
                    id: leftMenu
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Rectangle {
                    width: menuLabel.implicitWidth + 20
                    height: 28
                    radius: 6
                    color: menuMouse.containsMouse ? "#e5e5ea" : "transparent"

                    Text {
                        id: menuLabel
                        anchors.centerIn: parent
                        text: "⌘  Apps"
                        color: "#1d1d1f"
                        font.family: "Noto Sans, DejaVu Sans, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: menuMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.launcherOpen = !root.launcherOpen
                    }
                    }

                    Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#1d1d1f"
                    text: root.activeApplication
                    font.family: "Noto Sans, DejaVu Sans, sans-serif"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    width: 150
                    }
                }

                Row {
                    id: applicationMenus
                    anchors.left: leftMenu.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Repeater {
                    model: ["File", "Edit", "View", "Window", "Help"]
                    delegate: Rectangle {
                        width: menuText.implicitWidth + 14
                        height: 26
                        radius: 5
                        color: menuMouse.containsMouse ? "#e5e5ea" : "transparent"
                        Text {
                            id: menuText
                            anchors.centerIn: parent
                            text: modelData
                            color: "#1d1d1f"
                            font.family: "Noto Sans, DejaVu Sans, sans-serif"
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: menuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: applicationMenu.popup()
                        }
                    }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Repeater {
                    model: workspace.ids
                    delegate: Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: modelData === workspace.activeId ? "#1d1d1f" : "#e5e5ea"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: modelData === workspace.activeId ? "white" : "#6e6e73"
                            font.family: "Noto Sans, DejaVu Sans, sans-serif"
                            font.pixelSize: 11
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: workspace.switchTo(modelData)
                        }
                    }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 3
                    text: root.clockText
                    color: "#6e6e73"
                    font.family: "Noto Sans, DejaVu Sans, sans-serif"
                    font.pixelSize: 10
                }

                MenuBarRight {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    settings: menuBarSettings
                    network: network
                    audio: audio
                    battery: battery
                    bluetooth: bluetooth
                    inputLayout: inputLayout
                    notifications: notifications
                    mpris: mpris
                    session: session
                    onControlCenterRequested: root.controlCenterOpen = !root.controlCenterOpen
                    onOverviewRequested: root.overviewOpen = !root.overviewOpen
                    onSessionMenuRequested: sessionMenu.popup()
                }
            }
        }

        Menu {
            id: applicationMenu
            Action { text: "New Window" }
            Action { text: "Preferences" }
            Action { text: "Close Window" }
        }

        Menu {
            id: sessionMenu
            onClosed: root.sessionMenuOpen = false
            Action { text: "Lock"; onTriggered: session.action("lock-session") }
            Action { text: "Log Out"; onTriggered: root.confirmSession("terminate-session") }
            Action { text: "Suspend"; onTriggered: root.confirmSession("suspend") }
            Action { text: "Reboot"; onTriggered: root.confirmSession("reboot") }
            Action { text: "Shut Down"; onTriggered: root.confirmSession("poweroff") }
        }

        Dialog {
            id: sessionConfirmation
            title: "Confirm session action"
            modal: true
            width: 300
            height: 140
            standardButtons: Dialog.Ok | Dialog.Cancel
            contentItem: Text {
                text: "Run " + root.pendingSessionAction + "?"
                color: "#1d1d1f"
                padding: 18
            }
            onAccepted: {
                session.action(root.pendingSessionAction)
                root.pendingSessionAction = ""
            }
            onRejected: root.pendingSessionAction = ""
        }

        Rectangle {
            visible: root.controlCenterOpen
            anchors.top: parent.bottom
            anchors.right: parent.right
            width: 260
            height: 300
            color: "#ffffff"
            border.color: "#d2d2d7"
            radius: 8
            z: 10
            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8
                Text { text: "Control Center"; color: "#1d1d1f"; font.bold: true }
                Text { text: network.connected ? "Wi-Fi: " + network.connection : "Wi-Fi unavailable"; color: "#1d1d1f" }
                Row {
                    spacing: 8
                    Rectangle {
                        width: 108; height: 28; radius: 6
                        color: wifiMouse.containsMouse ? "#e5e5ea" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: network.connected ? "Wi-Fi On" : "Wi-Fi Off"; color: "#1d1d1f" }
                        MouseArea { id: wifiMouse; anchors.fill: parent; hoverEnabled: true; onClicked: network.toggleWifi() }
                    }

                    Rectangle {
                        width: 108; height: 28; radius: 6
                        color: bluetoothMouse.containsMouse ? "#e5e5ea" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: bluetooth.powered ? "Bluetooth On" : "Bluetooth Off"; color: "#1d1d1f" }
                        MouseArea { id: bluetoothMouse; anchors.fill: parent; hoverEnabled: true; onClicked: bluetooth.togglePower() }
                    }
                }
                Row {
                    spacing: 6
                    Text {
                        width: 104
                        text: audio.available ? "Volume: " + audio.volume + "%" : "Volume unavailable"
                        color: "#1d1d1f"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 28
                        height: 26
                        radius: 6
                        color: volumeDownMouse.containsMouse ? "#e5e5ea" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: "−"; color: "#1d1d1f" }
                        MouseArea {
                            id: volumeDownMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (audio.available) audio.setVolume(Math.max(0, audio.volume - 5))
                        }
                    }
                    Rectangle {
                        width: 28
                        height: 26
                        radius: 6
                        color: volumeMuteMouse.containsMouse ? "#e5e5ea" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: audio.muted ? "◖" : "⌁"; color: "#1d1d1f" }
                        MouseArea {
                            id: volumeMuteMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (audio.available) audio.setMuted(!audio.muted)
                        }
                    }
                    Rectangle {
                        width: 28
                        height: 26
                        radius: 6
                        color: volumeUpMouse.containsMouse ? "#e5e5ea" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: "+"; color: "#1d1d1f" }
                        MouseArea {
                            id: volumeUpMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (audio.available) audio.setVolume(Math.min(100, audio.volume + 5))
                        }
                    }
                }
                Text { text: battery.available ? "Battery: " + battery.percentage + "%" : "Battery unavailable"; color: "#1d1d1f" }
                Row {
                    spacing: 8
                    Text { width: 104; text: brightness.available ? "Brightness: " + brightness.percentage + "%" : "Brightness unavailable"; color: "#1d1d1f" }
                    Rectangle {
                        width: 28; height: 26; radius: 6
                        color: brightnessMouse.containsMouse ? "#e5e5ea" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: "−"; color: "#1d1d1f" }
                        MouseArea { id: brightnessMouse; anchors.fill: parent; hoverEnabled: true; onClicked: if (brightness.available) brightness.setPercentage(Math.max(1, brightness.percentage - 5)) }
                    }
                    Rectangle {
                        width: 28; height: 26; radius: 6
                        color: brightnessUpMouse.containsMouse ? "#e5e5ea" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: "+"; color: "#1d1d1f" }
                        MouseArea { id: brightnessUpMouse; anchors.fill: parent; hoverEnabled: true; onClicked: if (brightness.available) brightness.setPercentage(Math.min(100, brightness.percentage + 5)) }
                    }
                }
                Row {
                    spacing: 8
                    Rectangle {
                        width: 108; height: 28; radius: 6
                        color: root.doNotDisturb ? "#1d1d1f" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: root.doNotDisturb ? "DND On" : "DND Off"; color: root.doNotDisturb ? "white" : "#1d1d1f" }
                        MouseArea { anchors.fill: parent; onClicked: root.doNotDisturb = !root.doNotDisturb }
                    }
                    Rectangle {
                        width: 108; height: 28; radius: 6
                        color: mpris.available ? "#f5f5f7" : "#eeeeee"
                        Text { anchors.centerIn: parent; text: mpris.available ? (mpris.status === "Playing" ? "Pause media" : "Play media") : "No media"; color: "#1d1d1f" }
                        MouseArea { anchors.fill: parent; enabled: mpris.available; onClicked: mpris.command("play-pause") }
                    }
                }
                Text { text: mpris.available ? mpris.player + " · " + mpris.title : "No media player"; color: "#6e6e73"; elide: Text.ElideRight; width: 232 }
                Row {
                    spacing: 8
                    Rectangle {
                        width: 108; height: 28; radius: 6
                        color: notificationOpenMouse.containsMouse ? "#e5e5ea" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: "Notifications"; color: "#1d1d1f" }
                        MouseArea { id: notificationOpenMouse; anchors.fill: parent; hoverEnabled: true; onClicked: notifications.openCenter() }
                    }
                    Rectangle {
                        width: 108; height: 28; radius: 6
                        color: notificationClearMouse.containsMouse ? "#e5e5ea" : "#f5f5f7"
                        Text { anchors.centerIn: parent; text: "Clear"; color: "#1d1d1f" }
                        MouseArea { id: notificationClearMouse; anchors.fill: parent; hoverEnabled: true; onClicked: notifications.dismissAll() }
                    }
                }
                Text { text: root.doNotDisturb ? "Notifications paused" : (notifications.available ? "Notifications: " + notifications.owner : "Notifications unavailable"); color: "#6e6e73" }
            }
        }

        Rectangle {
            visible: root.overviewOpen
            anchors.top: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 260
            color: "#f5f5f7"
            border.color: "#d2d2d7"
            z: 9

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10
                width: parent.width - 36
                Text { text: "Window Overview"; color: "#1d1d1f"; font.pixelSize: 16; font.bold: true }
                GridView {
                    id: overviewGrid
                    width: parent.width
                    height: 196
                    cellWidth: 210
                    cellHeight: 82
                    model: workspace.clients
                    clip: true
                    delegate: Rectangle {
                        width: 196
                        height: 68
                        radius: 8
                        color: overviewMouse.containsMouse ? "#e5e5ea" : "#ffffff"
                        border.color: "#d2d2d7"
                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            Text { text: modelData.title || modelData.class || "Window"; color: "#1d1d1f"; elide: Text.ElideRight; width: 176 }
                            Text { text: "Workspace " + (modelData.workspace ? modelData.workspace.id : "?"); color: "#6e6e73"; font.pixelSize: 11 }
                        }
                        MouseArea {
                            id: overviewMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (modelData.address) {
                                    focusProcess.command = ["hyprctl", "dispatch", "focuswindow", "address:" + modelData.address]
                                    focusProcess.running = true
                                }
                                root.overviewOpen = false
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: launcher
            visible: root.launcherOpen
            anchors.top: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 12
            width: 360
            height: Math.min(420, 56 + applicationList.contentHeight)
            color: "#ffffff"
            border.color: "#d2d2d7"
            radius: 8
            z: 10

            TextField {
                id: searchField
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                height: 34
                placeholderText: "Search applications"
                text: root.searchText
                onTextChanged: root.searchText = text
                Keys.onPressed: {
                    if (event.key === Qt.Key_Escape) {
                        root.launcherOpen = false
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        applicationList.currentIndex = Math.min(applicationList.count - 1, applicationList.currentIndex + 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        applicationList.currentIndex = Math.max(0, applicationList.currentIndex - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return && applicationList.currentItem) {
                        root.launch(applicationList.currentItem.entry)
                        event.accepted = true
                    }
                }
                Component.onCompleted: if (root.launcherOpen) forceActiveFocus()
            }

            ListView {
                id: applicationList
                anchors.top: searchField.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                clip: true
                model: root.applications
                delegate: Rectangle {
                    property var entry: modelData
                    width: applicationList.width
                    height: root.appMatches(entry) ? 34 : 0
                    visible: root.appMatches(entry)
                    color: ListView.isCurrentItem ? "#e5e5ea" : "transparent"
                    radius: 5
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        text: entry ? entry.name : ""
                        color: "#1d1d1f"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.launch(entry)
                    }
                }
            }
        }
    }

    PanelWindow {
        id: dock
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 76
        color: "transparent"
        exclusiveZone: 0

        Rectangle {
            id: dockSurface
            width: Math.min(620, 74 + (dockItems.count * 52))
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 7
            radius: 13
            color: "#e8e8ed"
            border.color: "#d2d2d7"
            opacity: dockHover.containsMouse ? 1 : 0.92

            Behavior on width { NumberAnimation { duration: 120 } }

            Row {
                anchors.centerIn: parent
                spacing: 3
                Repeater {
                    id: dockItems
                    model: root.applications
                    delegate: Item {
                        visible: root.pinnedIds.some(function(id) { return modelData.id.indexOf(id) !== -1 })
                            || root.isRunning(modelData)
                        width: visible ? 48 : 0
                        height: 58
                        property real distance: Math.abs((mouseArea.x + width / 2) - (dockSurface.width / 2))
                        property real iconScale: mouseArea.containsMouse ? 1.18 : (distance < 90 ? 1.08 : 1)
                        Behavior on width { NumberAnimation { duration: 100 } }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: 42 * parent.iconScale
                            height: 42 * parent.iconScale
                            radius: 10
                            color: mouseArea.containsMouse ? "#ffffff" : "transparent"
                            Behavior on width { NumberAnimation { duration: 100 } }
                            Behavior on height { NumberAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name.substring(0, 1).toUpperCase()
                                color: "#1d1d1f"
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                            }
                            Rectangle {
                                visible: root.isRunning(modelData)
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 5
                                height: 5
                                radius: 3
                                color: "#0a84ff"
                            }
                        }
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    dockMenu.app = modelData
                                    dockMenu.popup()
                                } else {
                                    root.launch(modelData)
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    width: 1
                    height: 38
                    color: "#c7c7cc"
                }
                Rectangle {
                    width: 42
                    height: 42
                    radius: 10
                    color: trashMouse.containsMouse ? "#ffffff" : "transparent"
                    Text { anchors.centerIn: parent; text: "⌫"; color: "#1d1d1f"; font.pixelSize: 20 }
                    MouseArea {
                        id: trashMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: dockProcess.command = ["xdg-open", "trash:///"], dockProcess.running = true
                    }
                }
            }
            MouseArea { id: dockHover; anchors.fill: parent; z: -1; hoverEnabled: true }
        }

        Menu {
            id: dockMenu
            property var app
            Action { text: "New Window"; onTriggered: if (dockMenu.app) dockMenu.app.execute() }
            Action { text: "Close"; onTriggered: {
                var client = root.runningClient(dockMenu.app)
                if (client && client.address) {
                    dockProcess.command = ["hyprctl", "dispatch", "closewindow", "address:" + client.address]
                    dockProcess.running = true
                }
            }}
            Action { text: "Quit"; onTriggered: if (dockMenu.app) dockMenu.app.execute() }
            Action { text: "Open File Location"; onTriggered: dockProcess.command = ["xdg-open", "file:///usr/share/applications"], dockProcess.running = true }
        }
    }
}