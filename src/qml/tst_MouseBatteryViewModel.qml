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

    function makeControl(initProperties = {}) {
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

    function test_mouseWithUnknownStateIsIgnored() {
        bridge.addMouse({
            state: UPowerDeviceState.Unknown
        });

        const control = makeControl();

        verify(!control.hasData);
        verify(control.isDimmed);
        compare(control.emptyStateText, "No recent battery data. Waiting for Test Mouse to report.");
    }

    function test_mouseWithUnknownStateShowsItsModelName() {
        bridge.addMouse({
            state: UPowerDeviceState.Unknown
        });

        const control = makeControl();

        compare(control.deviceName, "Test Mouse");
        verify(!control.hasData);
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

    function test_dischargingMouseIsShown() {
        bridge.addMouse({});

        const control = makeControl();

        verify(control.hasData);
        verify(!control.isDimmed);
        compare(control.barLabel, "100%");
        compare(control.percentText, "100%");
        compare(control.statusText, "Discharging");
        compare(control.estimateText, "");
        compare(control.emptyStateText, "");
        compare(control.deviceName, "Test Mouse");
        compare(control.level, 1);
        verify(!control.showsBolt);
        compare(control.tone, MouseBatteryViewModel.Tone.Normal);
    }

    function test_mouseWithoutModelGetsFallbackName() {
        bridge.addMouse({
            model: ""
        });

        const control = makeControl();

        verify(!control.isDimmed);
        compare(control.deviceName, "Mouse");
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

    function test_lowDischargingMouseIsMarkedLow() {
        bridge.addMouse({
            percentage: 0.2
        });

        const control = makeControl();

        verify(!control.isDimmed);
        compare(control.tone, MouseBatteryViewModel.Tone.Low);
    }

    function test_mouseAboveLowThresholdIsNotMarkedLow() {
        bridge.addMouse({
            percentage: 0.21
        });

        const control = makeControl();

        verify(!control.isDimmed);
        compare(control.tone, MouseBatteryViewModel.Tone.Normal);
    }

    function test_dischargingMouseShowsTimeRemaining() {
        bridge.addMouse({
            timeToEmpty: 4500
        });

        const control = makeControl();

        verify(!control.isDimmed);
        compare(control.estimateText, "Time remaining: 1h 15m");
    }

    function test_chargingMouseShowsBolt() {
        bridge.addMouse({
            percentage: 0.5,
            state: UPowerDeviceState.Charging
        });

        const control = makeControl();

        compare(control.percentText, "50%");
        compare(control.statusText, "Charging");
        verify(control.showsBolt);
        compare(control.tone, MouseBatteryViewModel.Tone.Charging);
    }

    function test_chargingMouseShowsTimeUntilFull() {
        bridge.addMouse({
            state: UPowerDeviceState.Charging,
            timeToFull: 2700,
            timeToEmpty: 9999
        });

        const control = makeControl();

        verify(!control.isDimmed);
        compare(control.estimateText, "Time until full: 45m");
    }

    function test_chargingMouseWithoutEstimateHasNoDuration() {
        bridge.addMouse({
            state: UPowerDeviceState.Charging,
            timeToEmpty: 9999
        });

        const control = makeControl();

        verify(!control.isDimmed);
        compare(control.estimateText, "");
    }

    function test_fullyChargedMouseShowsBolt() {
        bridge.addMouse({
            state: UPowerDeviceState.FullyCharged
        });

        const control = makeControl();

        verify(control.showsBolt);
        compare(control.statusText, "Fully charged");
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
