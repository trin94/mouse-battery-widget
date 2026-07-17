// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

import MouseBatteryWidget.Test
import Quickshell.Services.UPower

TestCase {
    id: testCase

    width: 400
    height: 400
    visible: true
    when: windowShown
    name: "MouseBatteryViewModel"

    Component {
        id: objectUnderTest

        MouseBatteryViewModel {
            showPercentage: true
            showBolt: true
            lowBatteryPercent: 20
        }
    }

    Component {
        id: signalSpy

        SignalSpy {}
    }

    MouseBatteryTestBridge {
        id: bridge
    }

    function init() {
        bridge.reset();
    }

    function makeControl(initProperties = {}): MouseBatteryViewModel {
        const control = createTemporaryObject(objectUnderTest, testCase, initProperties);
        verify(control);
        return control;
    }

    function makeSpy(target, signalName) {
        const spy = createTemporaryObject(signalSpy, testCase, {
            target: target,
            signalName: signalName
        });
        verify(spy);
        return spy;
    }

    function test_noReadingsYetShowsEmptyState() {
        const control = makeControl();

        verify(!control.hasData);
        verify(control.isDimmed);
        compare(control.barLabel, "");
        compare(control.percentText, "");
        compare(control.statusText, "");
        compare(control.estimateText, "");
        compare(control.emptyStateText, "No supported mouse detected.");
        compare(control.deviceName, "Mouse");
        compare(control.level, 0);
        compare(control.tone, MouseBatteryViewModel.Tone.Normal);
    }

    function test_nonMouseDevicesAreIgnored() {
        bridge.addDevice({
            type: UPowerDeviceType.Keyboard,
            state: UPowerDeviceState.Discharging,
            percentage: 0.5,
            model: "Test Keyboard"
        });

        const control = makeControl();

        verify(!control.hasData);
        verify(control.isDimmed);
        compare(control.emptyStateText, "No supported mouse detected.");
        compare(control.deviceName, "Mouse");
    }

    function test_mouseWithUnknownStateIsDetectedButIgnored() {
        bridge.addMouse({
            state: UPowerDeviceState.Unknown
        });

        const control = makeControl();

        verify(!control.hasData);
        verify(control.isDimmed);
        compare(control.deviceName, "Test Mouse");
        compare(control.emptyStateText, "No recent battery data. Waiting for Test Mouse to report.");
    }

    function test_mouseAddedAtRuntimeIsPickedUp() {
        const control = makeControl();
        verify(control.isDimmed);

        bridge.addMouse({
            percentage: 0.42
        });

        verify(!control.isDimmed);
        compare(control.percentText, "42%");
    }

    function test_qualifyingMouseIsPickedAmongOtherDevices() {
        bridge.addDevice({
            type: UPowerDeviceType.Keyboard,
            state: UPowerDeviceState.Discharging,
            percentage: 0.5,
            model: "Test Keyboard"
        });
        bridge.addMouse({
            state: UPowerDeviceState.Unknown,
            model: "Unknown Mouse"
        });
        bridge.addMouse({
            percentage: 0.63
        });

        const control = makeControl();

        verify(!control.isDimmed);
        compare(control.percentText, "63%");
        compare(control.deviceName, "Test Mouse");
    }

    function test_mouseWithoutModelGetsFallbackName() {
        bridge.addMouse({
            model: ""
        });

        const control = makeControl();

        verify(!control.isDimmed);
        compare(control.deviceName, "Mouse");
    }

    function test_dischargingMouseIsShown() {
        bridge.addMouse({});

        const control = makeControl();

        verify(control.hasData);
        verify(!control.isDimmed);
        compare(control.barLabel, "100%");
        compare(control.percentText, "100%");
        compare(control.deviceName, "Test Mouse");
        compare(control.level, 1);
        compare(control.emptyStateText, "");
    }

    function test_statusText_data() {
        return [
            {
                tag: "discharging",
                props: {},
                expected: "Discharging"
            },
            {
                tag: "charging",
                props: {
                    state: UPowerDeviceState.Charging
                },
                expected: "Charging"
            },
            {
                tag: "fullyCharged",
                props: {
                    state: UPowerDeviceState.FullyCharged
                },
                expected: "Fully charged"
            },
            {
                tag: "notReporting",
                props: {
                    state: UPowerDeviceState.Unknown
                },
                expected: ""
            }
        ];
    }

    function test_statusText(data) {
        bridge.addMouse(data.props);

        compare(makeControl().statusText, data.expected);
    }

    function test_estimateText_data() {
        return [
            {
                tag: "timeRemaining",
                props: {
                    timeToEmpty: 4500
                },
                expected: "Time remaining: 1h 15m"
            },
            {
                tag: "timeUntilFull",
                props: {
                    state: UPowerDeviceState.Charging,
                    timeToFull: 2700,
                    timeToEmpty: 9999
                },
                expected: "Time until full: 45m"
            },
            {
                tag: "chargingWithoutEstimate",
                props: {
                    state: UPowerDeviceState.Charging,
                    timeToEmpty: 9999
                },
                expected: ""
            },
            {
                tag: "dischargingWithoutEstimate",
                props: {},
                expected: ""
            }
        ];
    }

    function test_estimateText(data) {
        bridge.addMouse(data.props);

        compare(makeControl().estimateText, data.expected);
    }

    function test_tone_data() {
        return [
            {
                tag: "discharging",
                props: {
                    percentage: 0.5
                },
                expected: MouseBatteryViewModel.Tone.Normal
            },
            {
                tag: "atLowThreshold",
                props: {
                    percentage: 0.2
                },
                expected: MouseBatteryViewModel.Tone.Low
            },
            {
                tag: "aboveLowThreshold",
                props: {
                    percentage: 0.21
                },
                expected: MouseBatteryViewModel.Tone.Normal
            },
            {
                tag: "charging",
                props: {
                    state: UPowerDeviceState.Charging
                },
                expected: MouseBatteryViewModel.Tone.Charging
            },
            {
                tag: "fullyCharged",
                props: {
                    state: UPowerDeviceState.FullyCharged
                },
                expected: MouseBatteryViewModel.Tone.Charging
            }
        ];
    }

    function test_tone(data) {
        bridge.addMouse(data.props);

        compare(makeControl().tone, data.expected);
    }

    function test_showsBolt_data() {
        return [
            {
                tag: "discharging",
                props: {},
                expected: false
            },
            {
                tag: "charging",
                props: {
                    state: UPowerDeviceState.Charging
                },
                expected: true
            },
            {
                tag: "fullyCharged",
                props: {
                    state: UPowerDeviceState.FullyCharged
                },
                expected: true
            }
        ];
    }

    function test_showsBolt(data) {
        bridge.addMouse(data.props);

        compare(makeControl().showsBolt, data.expected);
    }

    function test_lowBatteryThresholdIsConfigurable_data() {
        return [
            {
                tag: "atRaisedThreshold",
                props: {
                    percentage: 0.4
                },
                threshold: 40,
                expected: MouseBatteryViewModel.Tone.Low
            },
            {
                tag: "aboveRaisedThreshold",
                props: {
                    percentage: 0.41
                },
                threshold: 40,
                expected: MouseBatteryViewModel.Tone.Normal
            },
            {
                tag: "atLoweredThreshold",
                props: {
                    percentage: 0.05
                },
                threshold: 5,
                expected: MouseBatteryViewModel.Tone.Low
            },
            {
                tag: "aboveLoweredThreshold",
                props: {
                    percentage: 0.06
                },
                threshold: 5,
                expected: MouseBatteryViewModel.Tone.Normal
            }
        ];
    }

    function test_lowBatteryThresholdIsConfigurable(data) {
        bridge.addMouse(data.props);

        const control = makeControl({
            lowBatteryPercent: data.threshold
        });

        compare(control.tone, data.expected);
    }

    function test_propertyUpdatesPropagate() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        verify(!control.isDimmed);

        bridge.update(mouse, {
            percentage: 0.12,
            state: UPowerDeviceState.Charging
        });

        compare(control.percentText, "12%");
        compare(control.statusText, "Charging");
        verify(control.showsBolt);
        compare(control.tone, MouseBatteryViewModel.Tone.Charging);
    }

    function test_boltStaysHiddenWhenDisabled() {
        bridge.addMouse({
            state: UPowerDeviceState.Charging
        });

        const control = makeControl({
            showBolt: false
        });

        compare(control.statusText, "Charging");
        verify(!control.showsBolt);
    }

    function test_labelStaysHiddenWhenPercentageDisabled() {
        bridge.addMouse({});

        const control = makeControl({
            showPercentage: false
        });

        verify(!control.isDimmed);
        compare(control.barLabel, "");
        compare(control.percentText, "100%");
    }

    function test_mouseTurningUnknownKeepsLastReading() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        verify(!control.isDimmed);
        bridge.update(mouse, {
            percentage: 0.42
        });
        compare(control.percentText, "42%");

        bridge.update(mouse, {
            state: UPowerDeviceState.Unknown
        });

        verify(control.isDimmed);
        verify(control.hasData);
        compare(control.percentText, "42%");
        compare(control.statusText, "");
        compare(control.deviceName, "Test Mouse");
        compare(control.tone, MouseBatteryViewModel.Tone.Stale);
    }

    function test_removedMouseKeepsLastReading() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        verify(!control.isDimmed);
        bridge.update(mouse, {
            percentage: 0.42
        });
        compare(control.percentText, "42%");

        bridge.remove(mouse);

        verify(control.isDimmed);
        verify(control.hasData);
        compare(control.barLabel, "42%");
        compare(control.percentText, "42%");
        compare(control.emptyStateText, "No supported mouse detected.");
        compare(control.deviceName, "Test Mouse");
        compare(control.tone, MouseBatteryViewModel.Tone.Stale);
    }

    function test_returningMouseReplacesStaleReading() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        verify(!control.isDimmed);

        bridge.remove(mouse);
        verify(control.isDimmed);

        bridge.addMouse({
            percentage: 0.63,
            model: "Returned Mouse"
        });

        verify(!control.isDimmed);
        compare(control.percentText, "63%");
        compare(control.deviceName, "Returned Mouse");
        compare(control.tone, MouseBatteryViewModel.Tone.Normal);
    }
}
