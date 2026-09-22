import QtQuick
import QtQuick.Controls

import "../components"

Row {
    id: root

    property var settings
    property var network
    property var audio
    property var battery
    property var bluetooth
    property var inputLayout
    property var notifications
    property var mpris
    property var session
    signal controlCenterRequested()
    signal overviewRequested()
    signal sessionMenuRequested()

    spacing: 2

    StatusItem {
        visible: root.settings.wifi
        icon: "⌁"
        label: root.network.connected ? root.network.connection : "--"
        unavailable: !root.network.available || !root.network.connected
    }
    StatusItem {
        visible: root.settings.volume
        icon: root.audio.muted ? "⌁" : "◖"
        label: root.audio.available ? root.audio.volume + "%" : "--"
        unavailable: !root.audio.available
    }
    StatusItem {
        visible: root.settings.battery
        icon: root.battery.onBattery ? "▯" : "⚡"
        label: root.battery.available ? root.battery.percentage + "%" : "--"
        unavailable: !root.battery.available
    }
    StatusItem {
        visible: root.settings.bluetooth
        icon: "ᛒ"
        label: root.bluetooth.connected ? "" : "--"
        unavailable: !root.bluetooth.available
    }
    StatusItem {
        visible: root.settings.inputLayout
        icon: "文"
        label: root.inputLayout.layout
        unavailable: !root.inputLayout.available
    }
    StatusItem {
        visible: root.settings.notifications
        icon: "○"
        label: root.notifications.available ? "" : "--"
        unavailable: !root.notifications.available
    }
    StatusItem {
        visible: root.mpris && root.mpris.available
        icon: root.mpris && root.mpris.status === "Playing" ? "▶" : "Ⅱ"
        label: ""
        onClicked: if (root.mpris) root.mpris.command("play-pause")
    }
    StatusItem {
        visible: root.settings.controlCenter
        icon: "☷"
        label: ""
        onClicked: root.controlCenterRequested()
    }
    StatusItem {
        visible: root.settings.controlCenter
        icon: "▦"
        label: ""
        onClicked: root.overviewRequested()
    }
    StatusItem {
        visible: root.settings.userSession
        icon: "●"
        label: ""
        onClicked: root.sessionMenuRequested()
    }
}