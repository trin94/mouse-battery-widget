// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property UPowerDevice reportingMouse: _mice.find(d => root.isReporting(d)) ?? null
    readonly property UPowerDevice mouse: reportingMouse ?? _mice[0] ?? null

    readonly property list<UPowerDevice> _mice: UPower.devices.values.filter(d => d.type === UPowerDeviceType.Mouse)

    function isReporting(device: UPowerDevice): bool {
        return device.ready && device.state !== UPowerDeviceState.Unknown && device.percentage > 0;
    }

    function isDraining(state: int): bool {
        return state !== UPowerDeviceState.Charging && state !== UPowerDeviceState.PendingCharge && state !== UPowerDeviceState.FullyCharged;
    }
}
