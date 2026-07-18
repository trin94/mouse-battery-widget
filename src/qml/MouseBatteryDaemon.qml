// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell

import qs.Common

import "logic"

QtObject {
    id: root

    property string pluginId
    property var pluginService: null

    property int _lowBatteryPercent: MouseBatteryDefaults.lowBatteryPercent
    property bool _notifyOnLowBattery: MouseBatteryDefaults.notifyOnLowBattery

    readonly property MouseBatteryMonitor _monitor: MouseBatteryMonitor {
        lowBatteryPercent: root._lowBatteryPercent
        enabled: root._notifyOnLowBattery

        onLowBatteryReached: (percent, deviceName) => {
            const summary = I18n.tr("Mouse battery low");
            const body = I18n.tr("%1 is at %2%. Recharge it soon.").arg(deviceName).arg(percent);
            Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "Mouse Battery Widget", "-i", "battery-caution", "--", summary, body]);
        }
    }

    readonly property Connections _settingsWatcher: Connections {
        target: root.pluginService

        function onPluginDataChanged(changedPluginId: string) {
            if (changedPluginId === root.pluginId)
                root._loadSettings();
        }
    }

    function _loadSettings(): void {
        _lowBatteryPercent = pluginService?.loadPluginData(pluginId, "lowBatteryPercent", MouseBatteryDefaults.lowBatteryPercent) ?? MouseBatteryDefaults.lowBatteryPercent;
        _notifyOnLowBattery = pluginService?.loadPluginData(pluginId, "notifyOnLowBattery", MouseBatteryDefaults.notifyOnLowBattery) ?? MouseBatteryDefaults.notifyOnLowBattery;
    }

    onPluginServiceChanged: _loadSettings()

    Component.onCompleted: _loadSettings()
}
