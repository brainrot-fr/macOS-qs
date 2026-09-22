import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: true
    property bool unavailable: false
    signal clicked()

    implicitWidth: content.implicitWidth + 16
    implicitHeight: 28
    radius: 6
    color: mouse.containsMouse ? "#e5e5ea" : "transparent"
    opacity: active ? 1 : 0

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 5

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.unavailable ? "#8e8e93" : "#1d1d1f"
            font.family: "Noto Sans, DejaVu Sans, sans-serif"
            font.pixelSize: 14
        }

        Text {
            id: labelText
            visible: root.label.length > 0
            text: root.label
            color: root.unavailable ? "#8e8e93" : "#1d1d1f"
            font.family: "Noto Sans, DejaVu Sans, sans-serif"
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}