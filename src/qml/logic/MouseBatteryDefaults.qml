// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma Singleton

import QtQuick

QtObject {
    readonly property bool showPercentage: true
    readonly property bool showBolt: true
    readonly property int lowBatteryPercent: 20
    readonly property bool notifyOnLowBattery: true
}
