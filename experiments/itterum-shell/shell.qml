import Quickshell
import QtQuick
import QtQuick.Layouts

import "services"

ShellRoot {
    PanelWindow {
        anchors.top: true
        anchors.left: true
        anchors.right: true

        implicitHeight: 30
        color: "#1a1b26"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8

            Repeater {
                model: Niri.workspaces

                delegate: Text {
                    required property var modelData

                    text: modelData.idx

                    color: modelData.is_focused
                        ? "#0db9d7"
                        : "#7aa2f7"

                    font.pixelSize: 14
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            Niri.focusWorkspace(modelData.idx)
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
