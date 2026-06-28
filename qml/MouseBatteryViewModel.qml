// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: vm

    required property var devices
    required property int mouseType
    required property int unknownState
    required property var chargingStates
    required property var stateToString

    required property bool showPercentage
    required property bool showBolt

    required property string fallbackName
    required property string disconnectedName

    readonly property var mouse: (devices ?? []).find(d => d && d.ready && d.type === mouseType && d.state !== unknownState) ?? null
    readonly property bool hasMouse: mouse !== null
    readonly property int percent: hasMouse ? Math.round(mouse.percentage * 100) : -1

    readonly property bool boltVisible: hasMouse && showBolt && chargingStates.includes(mouse.state)
    readonly property bool labelVisible: showPercentage
    readonly property string label: hasMouse ? percent + "%" : "—"

    readonly property string deviceName: hasMouse ? (mouse.model || fallbackName) : disconnectedName
    readonly property string status: hasMouse ? percent + "% · " + stateToString(mouse.state) : ""
}
