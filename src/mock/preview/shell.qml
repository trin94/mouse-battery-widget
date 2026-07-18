// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Io

import qs.Common

import "MouseBattery"
import "MouseBattery/logic"

ShellRoot {
    id: root

    readonly property string pluginId: "mouseBatteryWidget"

    function _settingKeys(): var {
        const keys = [];
        for (const key in MouseBatteryDefaults) {
            if (key !== "objectName" && typeof MouseBatteryDefaults[key] !== "function")
                keys.push(key);
        }
        return keys;
    }

    MockPluginService {
        id: mockPluginService
    }

    IpcHandler {
        id: settingsIpc

        target: "settings"

        function list(): string {
            return root._settingKeys().map(key => key + " (" + typeof MouseBatteryDefaults[key] + ") = " + JSON.stringify(MouseBatteryDefaults[key])).join("\n");
        }

        function set(key: string, value: string): string {
            if (!root._settingKeys().includes(key))
                return "unknown setting: " + key + "\nvalid settings, with their defaults:\n" + settingsIpc.list();
            const defaultValue = MouseBatteryDefaults[key];
            let parsed = value;
            if (typeof defaultValue === "boolean") {
                if (value !== "true" && value !== "false")
                    return key + " expects true or false";
                parsed = value === "true";
            } else if (typeof defaultValue === "number") {
                parsed = Number(value);
                if (Number.isNaN(parsed))
                    return key + " expects a number";
            }
            mockPluginService.savePluginData(root.pluginId, key, parsed);
            return key + " = " + JSON.stringify(parsed);
        }
    }

    Connections {
        target: mockPluginService

        function onPluginDataChanged(changedPluginId: string) {
            widget.pluginData = mockPluginService.data[changedPluginId] ?? {};
        }
    }

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

    MouseBatteryDaemon {
        pluginId: root.pluginId
        pluginService: mockPluginService
    }
}
