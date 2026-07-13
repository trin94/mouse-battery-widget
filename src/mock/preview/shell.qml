// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import Quickshell

import qs.Common

import "MouseBattery"

ShellRoot {
    id: root

    PanelWindow {
        id: bar

        anchors {
            left: true
            right: true
            bottom: true
        }
        implicitHeight: widget.barThickness
        color: Theme.surfaceContainer

        MouseBatteryWidget {
            id: widget
            parentScreen: bar.screen
            anchors.centerIn: parent
        }
    }
}
