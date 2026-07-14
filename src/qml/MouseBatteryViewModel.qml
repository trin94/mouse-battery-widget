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

    readonly property bool isLive: _private.current.isLive
    readonly property bool isStale: _private.current.isStale
    readonly property bool hasData: _private.current.hasData
    readonly property bool isMouseDetected: UPower.devices.values.some(d => d.type === UPowerDeviceType.Mouse)
    readonly property real level: _private.current.level
    readonly property int percent: _private.current.percent
    readonly property bool isPluggedIn: _private.current.chargeState !== MouseBatteryViewModel.ChargeState.Discharging
    readonly property bool isFullyCharged: _private.current.chargeState === MouseBatteryViewModel.ChargeState.FullyCharged
    readonly property bool isLow: _private.current.isLow
    readonly property bool shouldShowBolt: showBolt && isPluggedIn
    readonly property bool shouldShowLabel: showPercentage && hasData
    readonly property string label: hasData ? percent + "%" : ""
    readonly property string deviceName: _private.current.deviceName
    readonly property real secondsUntilEmpty: _private.current.secondsUntilEmpty
    readonly property real secondsUntilFull: _private.current.secondsUntilFull

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
        required property QtObject device

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
    readonly property QtObject _private: QtObject {
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
            if (!vm.isLive)
                return;
            lastReading = { valid: true, level: vm.level, name: vm.deviceName };
        }
    }
    // qmlformat on

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
