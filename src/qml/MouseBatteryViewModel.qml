// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell.Services.UPower

QtObject {
    id: vm

    required property bool showPercentage
    required property bool showBolt

    readonly property bool isReporting: _private.mouse !== null
    readonly property bool isMouseDetected: UPower.devices.values.some(d => d.type === UPowerDeviceType.Mouse)
    readonly property bool hasData: isReporting || _private.hasLastReading
    readonly property bool isStale: hasData && !isReporting
    readonly property real level: isReporting ? _private.mouse.percentage : _private.lastLevel
    readonly property int percent: hasData ? Math.round(level * 100) : -1

    // qmlformat off
    readonly property bool isPluggedIn: isReporting
        && (_private.mouse.state === UPowerDeviceState.Charging
            || _private.mouse.state === UPowerDeviceState.FullyCharged)
    // qmlformat on

    readonly property bool isFullyCharged: isReporting && _private.mouse.state === UPowerDeviceState.FullyCharged
    readonly property bool isLow: isReporting && !isPluggedIn && percent <= _private.lowBatteryPercent

    readonly property bool boltVisible: isPluggedIn && showBolt
    readonly property bool labelVisible: showPercentage && hasData
    readonly property string label: hasData ? percent + "%" : ""

    readonly property string deviceName: (isReporting ? _private.mouse.model : _private.lastName) || "Mouse"

    readonly property real durationSeconds: {
        if (!isReporting)
            return 0;
        return isPluggedIn ? _private.mouse.timeToFull : _private.mouse.timeToEmpty;
    }

    readonly property QtObject _private: QtObject {
        readonly property int lowBatteryPercent: 20

        // qmlformat off
        readonly property UPowerDevice mouse: UPower.devices.values.find(d => d.ready
            && d.type === UPowerDeviceType.Mouse
            && d.state !== UPowerDeviceState.Unknown) ?? null
        // qmlformat on

        property bool hasLastReading: false
        property real lastLevel: 0
        property string lastName: ""

        function captureReading() {
            if (!vm.isReporting)
                return;
            hasLastReading = true;
            lastLevel = vm.level;
            lastName = vm.deviceName;
        }
    }

    onIsReportingChanged: _private.captureReading()
    onLevelChanged: _private.captureReading()
    onDeviceNameChanged: _private.captureReading()

    Component.onCompleted: _private.captureReading()
}
