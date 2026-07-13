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
    readonly property int percent: hasMouse ? Math.round(mouse.percentage * 100) : -1
    readonly property real level: hasMouse ? mouse.percentage : 0

    // qmlformat off
    readonly property bool isCharging: hasMouse
        && (mouse.state === UPowerDeviceState.Charging
            || mouse.state === UPowerDeviceState.FullyCharged)
    // qmlformat on

    readonly property bool isLow: hasMouse && !isCharging && percent <= lowBatteryPercent

    readonly property bool boltVisible: isCharging && showBolt
    readonly property bool labelVisible: showPercentage
    readonly property string label: hasMouse ? percent + "%" : "—"

    readonly property string deviceName: hasMouse ? (mouse.model || "Mouse") : "No mouse connected"
    readonly property string stateText: hasMouse ? UPowerDeviceState.toString(mouse.state) : ""

    readonly property string durationText: {
        if (!hasMouse)
            return "";
        if (isCharging)
            return mouse.timeToFull > 0 ? formatDuration(mouse.timeToFull) : "";
        return mouse.timeToEmpty > 0 ? formatDuration(mouse.timeToEmpty) : "";
    }

    function formatDuration(seconds: real): string {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }
}
