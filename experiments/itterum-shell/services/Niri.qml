pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []

    function refreshWorkspaces() {
        workspacesProcess.running = true
    }

    function focusWorkspace(index) {
        focusProcess.exec([
            "niri",
            "msg",
            "action",
            "focus-workspace",
            index.toString()
        ])
    }

    Process {
        id: workspacesProcess

        command: [
            "niri",
            "msg",
            "--json",
            "workspaces"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.workspaces = JSON.parse(text)

                    console.log(
                        "Niri workspaces:",
                        JSON.stringify(root.workspaces)
                    )
                } catch (e) {
                    console.error(
                        "Failed to parse Niri workspaces:",
                        e
                    )
                }
            }
        }
    }

    Process {
        id: focusProcess
    }

    Component.onCompleted: refreshWorkspaces()
}
