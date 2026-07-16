// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell.Services.UPower

QtObject {
    id: root

    // User setting: show the percentage label in the bar.
    required property bool showPercentage

    // User setting: show the charging bolt in the bar.
    required property bool showBolt

    // A valid battery reading is coming in right now.
    readonly property bool isLive: _private.current.isLive

    // The mouse stopped reporting and the shown values are its frozen last reading.
    readonly property bool isStale: _private.current.isStale

    // There is something to show, either live or stale.
    readonly property bool hasData: _private.current.hasData

    // UPower lists a mouse device at all, whatever its state.
    readonly property bool isMouseDetected: UPower.devices.values.some(d => d.type === UPowerDeviceType.Mouse)

    // Battery level from 0 to 1, frozen at the last reading while stale.
    readonly property real level: _private.current.level

    // Battery level from 0 to 100, or -1 before the first reading.
    readonly property int percent: _private.current.percent

    // Display text for the percentage, empty before the first reading.
    readonly property string label: hasData ? percent + "%" : ""

    // Product name of the mouse, "Mouse" if unknown.
    readonly property string deviceName: _private.current.deviceName

    // The mouse is charging or sits fully charged on the cable.
    readonly property bool isPluggedIn: _private.current.chargeState !== MouseBatteryViewModel.ChargeState.Discharging

    // The mouse is plugged in and the battery is full.
    readonly property bool isFullyCharged: _private.current.chargeState === MouseBatteryViewModel.ChargeState.FullyCharged

    // A live, discharging battery is at or below the low threshold.
    readonly property bool isLow: _private.current.isLow

    // Estimated seconds until empty, 0 unless live, discharging, and UPower provides an estimate.
    readonly property real secondsUntilEmpty: _private.current.secondsUntilEmpty

    // Estimated seconds until full, 0 unless live, charging, and UPower provides an estimate.
    readonly property real secondsUntilFull: _private.current.secondsUntilFull

    // The bar should render the percentage label.
    readonly property bool shouldShowLabel: showPercentage && hasData

    // The bar should render the charging bolt.
    readonly property bool shouldShowBolt: showBolt && isPluggedIn

    component NullDevice: QtObject {
        readonly property real percentage: 0
        readonly property string model: ""
        readonly property int state: UPowerDeviceState.Unknown
        readonly property real timeToEmpty: 0
        readonly property real timeToFull: 0
    }

    component DisplayState: QtObject {
        property bool isLive: false
        property bool isStale: false
        readonly property bool hasData: isLive || isStale
        property real level: 0
        property int percent: -1
        property string deviceName: "Mouse"
        property int chargeState: MouseBatteryViewModel.ChargeState.Discharging
        property real secondsUntilEmpty: 0
        property real secondsUntilFull: 0
        property bool isLow: false
    }

    component LiveState: DisplayState {
        required property var device

        readonly property int lowBatteryPercent: 20

        isLive: true
        level: device.percentage
        percent: Math.round(level * 100)
        deviceName: device.model || "Mouse"

        // qmlformat off
        chargeState: device.state === UPowerDeviceState.FullyCharged ? MouseBatteryViewModel.ChargeState.FullyCharged
            : device.state === UPowerDeviceState.Charging ? MouseBatteryViewModel.ChargeState.Charging
            : MouseBatteryViewModel.ChargeState.Discharging
        // qmlformat on

        secondsUntilEmpty: chargeState === MouseBatteryViewModel.ChargeState.Discharging ? device.timeToEmpty : 0
        secondsUntilFull: chargeState === MouseBatteryViewModel.ChargeState.Discharging ? 0 : device.timeToFull
        isLow: chargeState === MouseBatteryViewModel.ChargeState.Discharging && percent <= lowBatteryPercent
    }

    component StaleState: DisplayState {
        required property var reading

        isStale: true
        level: reading.level
        percent: Math.round(reading.level * 100)
        deviceName: reading.name || "Mouse"
    }

    // qmlformat off
    component Private: QtObject {
        id: priv

        readonly property UPowerDevice mouse: UPower.devices.values.find(d => d.ready
            && d.type === UPowerDeviceType.Mouse
            && d.state !== UPowerDeviceState.Unknown) ?? null

        readonly property NullDevice nullDevice: NullDevice {}

        readonly property DisplayState noData: DisplayState {}
        readonly property LiveState live: LiveState { device: priv.mouse ?? priv.nullDevice }
        readonly property StaleState stale: StaleState { reading: priv.lastReading }

        readonly property DisplayState current: mouse ? live : lastReading.valid ? stale : noData

        property var lastReading: ({ valid: false, level: 0, name: "" })

        function captureReading() {
            if (!root.isLive)
                return;
            lastReading = { valid: true, level: root.level, name: root.deviceName };
        }
    }
    // qmlformat on

    readonly property Private _private: Private {}

    enum ChargeState {
        Discharging,
        Charging,
        FullyCharged
    }

    onIsLiveChanged: _private.captureReading()
    onLevelChanged: _private.captureReading()
    onDeviceNameChanged: _private.captureReading()

    Component.onCompleted: _private.captureReading()
}
