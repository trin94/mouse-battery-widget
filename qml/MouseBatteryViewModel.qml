// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: vm

    required property var devices
    required property int mouseType
    required property var chargingStates
    required property var stateToString
    required property bool showPercentage
    required property bool showBolt

    readonly property var device: devices.find(d => d && d.ready && d.type === mouseType) ?? null
    readonly property bool present: device !== null
    readonly property int percent: present ? Math.round(device.percentage * 100) : -1
    readonly property bool boltVisible: present && showBolt && chargingStates.includes(device.state)
    readonly property bool labelVisible: showPercentage
    readonly property string label: present ? percent + "%" : "—"
    readonly property string name: present ? (device.model || "Mouse") : "No mouse connected"
    readonly property string detail: present ? percent + "% · " + stateToString(device.state) : ""
}
