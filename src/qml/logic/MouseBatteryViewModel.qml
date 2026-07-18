// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell.Services.UPower

import qs.Common

QtObject {
    id: root

    required property bool showPercentage // User setting: show the percentage label in the bar.
    required property bool showBolt // User setting: show the charging bolt in the bar.
    required property int lowBatteryPercent // User setting: percentage at or below which the battery counts as low.
    required property bool notifyOnLowBattery // User setting: announce the drop into the low state.

    // Percentage text for the bar, empty while hidden by setting or missing data.
    readonly property string barLabel: showPercentage ? percentText : ""

    // The bar should render the charging bolt.
    readonly property bool showsBolt: showBolt && _private.current.chargeState !== MouseBatteryViewModel.ChargeState.Discharging

    // The bar content renders muted while no live reading is coming in.
    readonly property bool isDimmed: !_private.current.isLive

    // There is something to show, either live or stale.
    readonly property bool hasData: _private.current.hasData

    // The popout should render the level bar, false without a supported mouse.
    readonly property bool showsLevelBar: _private.mouse !== null

    // Battery level from 0 to 1, frozen at the last reading while stale.
    readonly property real level: _private.current.level

    // Low battery threshold from 0 to 1, splits the level bar into
    // segments. Zero while notifications are off, rendering a plain bar.
    readonly property real thresholdLevel: notifyOnLowBattery ? lowBatteryPercent / 100 : 0

    // Filled share of the bar segment below the threshold, from 0 to 1.
    readonly property real lowSegmentFill: thresholdLevel > 0 ? Math.min(level, thresholdLevel) / thresholdLevel : 0

    // Filled share of the bar segment above the threshold, from 0 to 1.
    readonly property real highSegmentFill: thresholdLevel < 1 ? Math.max(0, level - thresholdLevel) / (1 - thresholdLevel) : 0

    // Battery percentage text, empty before the first reading.
    readonly property string percentText: hasData ? _private.current.percent + "%" : ""

    // Charge state line, empty unless a battery reading is coming in right now.
    readonly property string statusText: {
        if (!_private.current.isLive)
            return "";
        if (_private.current.chargeState === MouseBatteryViewModel.ChargeState.FullyCharged)
            return I18n.tr("Fully charged");
        if (_private.current.chargeState === MouseBatteryViewModel.ChargeState.Charging)
            return I18n.tr("Charging");
        return I18n.tr("Discharging");
    }

    // Time estimate line, empty when UPower provides no estimate.
    readonly property string estimateText: {
        if (_private.current.secondsUntilEmpty > 0)
            return I18n.tr("Time remaining: %1").arg(_private.formatDuration(_private.current.secondsUntilEmpty));
        if (_private.current.secondsUntilFull > 0)
            return I18n.tr("Time until full: %1").arg(_private.formatDuration(_private.current.secondsUntilFull));
        return "";
    }

    // Explanation shown while live data is missing, empty otherwise.
    readonly property string emptyStateText: {
        if (_private.current.isLive)
            return "";
        if (_private.mouse !== null)
            return I18n.tr("No recent battery data. Waiting for %1 to report.").arg(deviceName);
        return I18n.tr("No supported mouse detected.");
    }

    // Product name of the mouse, "Mouse" if unknown.
    readonly property string deviceName: _private.current.deviceName

    // Color role for the shown data.
    readonly property int tone: {
        if (_private.current.isStale)
            return MouseBatteryViewModel.Tone.Stale;
        if (_private.current.isLow)
            return MouseBatteryViewModel.Tone.Low;
        if (_private.current.chargeState !== MouseBatteryViewModel.ChargeState.Discharging)
            return MouseBatteryViewModel.Tone.Charging;
        return MouseBatteryViewModel.Tone.Normal;
    }

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
        property string deviceName: MouseBatteryDevices.displayName()
        property int chargeState: MouseBatteryViewModel.ChargeState.Discharging
        property real secondsUntilEmpty: 0
        property real secondsUntilFull: 0
        property bool isLow: false
    }

    component LiveState: DisplayState {
        required property var device

        isLive: true
        level: device.percentage
        percent: Math.round(level * 100)
        deviceName: MouseBatteryDevices.displayName(device.model)

        chargeState: {
            if (device.state === UPowerDeviceState.FullyCharged)
                return MouseBatteryViewModel.ChargeState.FullyCharged;
            if (MouseBatteryDevices.isDraining(device.state))
                return MouseBatteryViewModel.ChargeState.Discharging;
            return MouseBatteryViewModel.ChargeState.Charging;
        }

        secondsUntilEmpty: chargeState === MouseBatteryViewModel.ChargeState.Discharging ? device.timeToEmpty : 0
        secondsUntilFull: chargeState === MouseBatteryViewModel.ChargeState.Discharging ? 0 : device.timeToFull
        isLow: chargeState === MouseBatteryViewModel.ChargeState.Discharging && percent <= root.lowBatteryPercent
    }

    component StaleState: DisplayState {
        required property var reading

        isStale: true
        level: reading.level
        percent: Math.round(reading.level * 100)
        deviceName: MouseBatteryDevices.displayName(reading.name)
    }

    component Private: QtObject {
        id: priv

        readonly property UPowerDevice mouse: MouseBatteryDevices.mouse
        readonly property bool isMouseLive: MouseBatteryDevices.reportingMouse !== null
        readonly property NullDevice nullDevice: NullDevice {}

        readonly property DisplayState noData: DisplayState {
            deviceName: MouseBatteryDevices.displayName(priv.mouse?.model)
        }

        readonly property LiveState live: LiveState {
            device: priv.isMouseLive ? priv.mouse ?? priv.nullDevice : priv.nullDevice
        }

        readonly property StaleState stale: StaleState {
            reading: priv.lastReading
        }

        readonly property DisplayState current: {
            if (isMouseLive)
                return live;
            return lastReading.valid ? stale : noData;
        }

        property var lastReading: ({
                valid: false,
                level: 0,
                name: ""
            })

        readonly property Connections reportingMouseWatcher: Connections {
            target: MouseBatteryDevices

            function onReportingMouseChanged() {
                priv.captureReading();
            }
        }

        readonly property Connections readingWatcher: Connections {
            target: MouseBatteryDevices.reportingMouse

            function onPercentageChanged() {
                priv.captureReading();
            }

            function onModelChanged() {
                priv.captureReading();
            }
        }

        function captureReading(): void {
            const device = MouseBatteryDevices.reportingMouse;
            if (device === null)
                return;
            lastReading = {
                valid: true,
                level: device.percentage,
                name: device.model
            };
        }

        function formatDuration(seconds: real): string {
            const hours = Math.floor(seconds / 3600);
            const minutes = Math.floor((seconds % 3600) / 60);
            return hours > 0 ? I18n.tr("%1h %2m").arg(hours).arg(minutes) : I18n.tr("%1m").arg(minutes);
        }
    }

    readonly property Private _private: Private {}

    enum ChargeState {
        Discharging,
        Charging,
        FullyCharged
    }

    enum Tone {
        Normal,
        Charging,
        Low,
        Stale
    }

    Component.onCompleted: _private.captureReading()
}
