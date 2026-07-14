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

    readonly property int lowBatteryPercent: 20

    // qmlformat off
    readonly property UPowerDevice mouse: UPower.devices.values.find(d => d.ready
        && d.type === UPowerDeviceType.Mouse
        && d.state !== UPowerDeviceState.Unknown) ?? null
    // qmlformat on

    readonly property bool hasMouse: mouse !== null
    readonly property bool isMouseDetected: UPower.devices.values.some(d => d.type === UPowerDeviceType.Mouse)
    readonly property bool hasData: hasMouse || _lastReading.percent >= 0
    readonly property bool isStale: hasData && !hasMouse
    readonly property int percent: hasMouse ? Math.round(mouse.percentage * 100) : _lastReading.percent
    readonly property real level: hasMouse ? mouse.percentage : _lastReading.level

    // qmlformat off
    readonly property bool isCharging: hasMouse
        && (mouse.state === UPowerDeviceState.Charging
            || mouse.state === UPowerDeviceState.FullyCharged)
    // qmlformat on

    readonly property bool isLow: hasMouse && !isCharging && percent <= lowBatteryPercent

    readonly property bool boltVisible: isCharging && showBolt
    readonly property bool labelVisible: showPercentage && hasData
    readonly property string label: hasData ? percent + "%" : ""

    readonly property string deviceName: hasMouse ? (mouse.model || "Mouse") : (_lastReading.name || "Mouse")
    readonly property string stateText: hasMouse ? UPowerDeviceState.toString(mouse.state) : ""

    readonly property string durationText: {
        if (!hasMouse)
            return "";
        if (isCharging)
            return mouse.timeToFull > 0 ? formatDuration(mouse.timeToFull) : "";
        return mouse.timeToEmpty > 0 ? formatDuration(mouse.timeToEmpty) : "";
    }

    readonly property QtObject _lastReading: QtObject {
        property int percent: -1
        property real level: 0
        property string name: ""
    }

    function formatDuration(seconds: real): string {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    function _captureReading() {
        if (!hasMouse)
            return;
        _lastReading.percent = percent;
        _lastReading.level = level;
        _lastReading.name = deviceName;
    }

    onMouseChanged: _captureReading()
    onLevelChanged: _captureReading()
    onDeviceNameChanged: _captureReading()

    Component.onCompleted: _captureReading()
}
