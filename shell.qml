import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "services"

ShellRoot {
    id: root

    property string clockText: ""
    property string searchText: ""
    property bool launcherOpen: false
    property var pinnedIds: ["firefox", "org.kde.dolphin", "foot"]
    property var applications: DesktopEntries.applications

    Workspace {
        id: workspace
    }

    NetworkStatus {
        id: network
    }

    function updateClock() {
        clockText = Qt.formatDateTime(new Date(), "ddd, MMM d  HH:mm")
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

    onLauncherOpenChanged: {
        if (launcherOpen)
            searchField.forceActiveFocus()
    }

    Component.onCompleted: {
        updateClock()
        workspace.refresh()
        network.refresh()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateClock()
    }

    Process {
        id: focusProcess
        command: ["hyprctl", "dispatch", "focuswindow", "class:"]
    }

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

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 16

                Rectangle {
                    width: menuLabel.implicitWidth + 20
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 6
                    color: menuMouse.containsMouse ? "#e5e5ea" : "transparent"

                    Text {
                        id: menuLabel
                        anchors.centerIn: parent
                        text: "Apps"
                        color: "#1d1d1f"
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

                Row {
                    spacing: 5
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: workspace.ids
                        delegate: Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            color: modelData === workspace.activeId ? "#0a84ff" : "#e5e5ea"
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: modelData === workspace.activeId ? "white" : "#6e6e73"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: workspace.switchTo(modelData)
                            }
                        }
                    }
                }

                Item { width: 1 }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.clockText
                    color: "#1d1d1f"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Item { width: 1 }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: network.connected ? "● " + network.label : "○ Offline"
                    color: network.connected ? "#1d1d1f" : "#6e6e73"
                    font.pixelSize: 12
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
        implicitHeight: 62
        color: "transparent"

        Rectangle {
            width: 300
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 7
            radius: 15
            color: "#e8e8ed"
            border.color: "#d2d2d7"

            Row {
                anchors.centerIn: parent
                spacing: 7
                Repeater {
                    model: root.applications
                    delegate: Rectangle {
                        visible: root.pinnedIds.some(function(id) { return modelData.id.indexOf(id) !== -1 })
                            || root.isRunning(modelData)
                        width: visible ? 42 : 0
                        height: visible ? 42 : 0
                        radius: 10
                        color: mouse.containsMouse ? "#ffffff" : "transparent"
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
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launch(modelData)
                        }
                    }
                }
            }
        }
    }
}