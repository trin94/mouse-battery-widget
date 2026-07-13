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

    readonly property var mouse: UPower.devices.values.find(d => d.ready && d.type === UPowerDeviceType.Mouse && d.state !== UPowerDeviceState.Unknown) ?? null
    readonly property bool hasMouse: mouse !== null
    readonly property int percent: hasMouse ? Math.round(mouse.percentage * 100) : -1

    readonly property bool boltVisible: hasMouse && showBolt && (mouse.state === UPowerDeviceState.Charging || mouse.state === UPowerDeviceState.FullyCharged)
    readonly property bool labelVisible: showPercentage
    readonly property string label: hasMouse ? percent + "%" : "—"

    readonly property string deviceName: hasMouse ? (mouse.model || "Mouse") : "No mouse connected"
    readonly property string status: hasMouse ? percent + "% · " + UPowerDeviceState.toString(mouse.state) : ""
}
