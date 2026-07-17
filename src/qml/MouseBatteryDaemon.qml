// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell

import qs.Common

QtObject {
    id: root

    property string pluginId
    property var pluginService: null

    property int _lowBatteryPercent: MouseBatteryDefaults.lowBatteryPercent
    property bool _notifyOnLowBattery: MouseBatteryDefaults.notifyOnLowBattery

    readonly property MouseBatteryViewModel _viewModel: MouseBatteryViewModel {
        showPercentage: true
        showBolt: true
        lowBatteryPercent: root._lowBatteryPercent
        notifyOnLowBattery: root._notifyOnLowBattery
    }

    readonly property Connections _settingsWatcher: Connections {
        target: root.pluginService

        function onPluginDataChanged(changedPluginId: string) {
            if (changedPluginId === root.pluginId)
                root._loadSettings();
        }
    }

    readonly property Connections _notifier: Connections {
        target: root._viewModel

        function onLowBatteryReached(percent: int, deviceName: string) {
            const summary = I18n.tr("Mouse battery low");
            const body = I18n.tr("%1 is at %2%. Recharge it soon.").arg(deviceName).arg(percent);
            Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "Mouse Battery Widget", "-i", "battery-caution", "--", summary, body]);
        }
    }

    function _loadSettings(): void {
        _lowBatteryPercent = pluginService?.loadPluginData(pluginId, "lowBatteryPercent", MouseBatteryDefaults.lowBatteryPercent) ?? MouseBatteryDefaults.lowBatteryPercent;
        _notifyOnLowBattery = pluginService?.loadPluginData(pluginId, "notifyOnLowBattery", MouseBatteryDefaults.notifyOnLowBattery) ?? MouseBatteryDefaults.notifyOnLowBattery;
    }

    onPluginServiceChanged: _loadSettings()

    Component.onCompleted: _loadSettings()
}
