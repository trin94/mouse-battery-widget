// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell.Services.UPower

QtObject {
    id: root

    required property int lowBatteryPercent
    required property bool enabled

    readonly property UPowerDevice _device: MouseBatteryDevices.reportingMouse

    readonly property int _rearmMargin: 5

    property bool _hasAnnounced: false

    property bool _isReady: false

    readonly property Connections _deviceWatcher: Connections {
        target: root._device

        function onPercentageChanged() {
            root._evaluate();
        }

        function onStateChanged() {
            root._evaluate();
        }
    }

    signal lowBatteryReached(percent: int, deviceName: string)

    function _evaluate(): void {
        if (_device === null || !MouseBatteryDevices.isReporting(_device))
            return;
        const percent = Math.round(_device.percentage * 100);
        if (percent > lowBatteryPercent + _rearmMargin) {
            _hasAnnounced = false;
            return;
        }
        if (!MouseBatteryDevices.isDraining(_device.state) || percent > lowBatteryPercent || _hasAnnounced)
            return;
        _hasAnnounced = true;
        if (_isReady && enabled)
            lowBatteryReached(percent, MouseBatteryDevices.displayName(_device.model));
    }

    on_DeviceChanged: _evaluate()
    onLowBatteryPercentChanged: _evaluate()

    Component.onCompleted: {
        _evaluate();
        _isReady = true;
    }
}
