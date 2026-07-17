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

        verify(!control.isLive);
        verify(!control.hasData);
        verify(!control.isStale);
        verify(!control.isMouseDetected);
        compare(control.label, "");
        verify(!control.shouldShowLabel);
        compare(control.deviceName, "Mouse");
        compare(control.percent, -1);
        compare(control.level, 0);
    }

    function test_nonMouseDevicesAreIgnored() {
        bridge.addDevice({
            type: UPowerDeviceType.Keyboard,
            state: UPowerDeviceState.Discharging,
            percentage: 0.5,
            model: "Test Keyboard"
        });

        const control = makeControl();

        verify(!control.isLive);
        verify(!control.isMouseDetected);
        compare(control.deviceName, "Mouse");
    }

    function test_mouseWithUnknownStateIsIgnored() {
        bridge.addMouse({
            state: UPowerDeviceState.Unknown
        });

        const control = makeControl();

        verify(!control.isLive);
        verify(control.isMouseDetected);
    }

    function test_mouseWithUnknownStateShowsItsModelName() {
        bridge.addMouse({
            state: UPowerDeviceState.Unknown
        });

        const control = makeControl();

        compare(control.deviceName, "Test Mouse");
        verify(!control.isLive);
        verify(!control.hasData);
    }

    function test_mouseAddedAtRuntimeIsPickedUp() {
        const control = makeControl();
        verify(!control.isLive);

        bridge.addMouse({
            percentage: 0.42
        });

        verify(control.isLive);
        compare(control.percent, 42);
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

        verify(control.isLive);
        compare(control.percent, 63);
        compare(control.deviceName, "Test Mouse");
    }

    function test_dischargingMouseIsShown() {
        bridge.addMouse({});

        const control = makeControl();

        verify(control.isLive);
        compare(control.percent, 100);
        compare(control.label, "100%");
        compare(control.deviceName, "Test Mouse");
        compare(control.level, 1);
        verify(!control.isPluggedIn);
        verify(!control.isFullyCharged);
        verify(!control.isLow);
        verify(!control.shouldShowBolt);
        verify(control.shouldShowLabel);
        compare(control.secondsUntilEmpty, 0);
        compare(control.secondsUntilFull, 0);
    }

    function test_mouseWithoutModelGetsFallbackName() {
        bridge.addMouse({
            model: ""
        });

        const control = makeControl();

        verify(control.isLive);
        compare(control.deviceName, "Mouse");
    }

    function test_propertyUpdatesPropagate() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        verify(control.isLive);

        bridge.update(mouse, {
            percentage: 0.12,
            state: UPowerDeviceState.Charging
        });

        compare(control.percent, 12);
        verify(control.shouldShowBolt);
        verify(control.isPluggedIn);
        verify(!control.isLow);
    }

    function test_lowDischargingMouseIsMarkedLow() {
        bridge.addMouse({
            percentage: 0.2
        });

        const control = makeControl();

        verify(control.isLive);
        verify(control.isLow);
    }

    function test_mouseAboveLowThresholdIsNotMarkedLow() {
        bridge.addMouse({
            percentage: 0.21
        });

        const control = makeControl();

        verify(control.isLive);
        verify(!control.isLow);
    }

    function test_dischargingMouseShowsTimeRemaining() {
        bridge.addMouse({
            timeToEmpty: 4500
        });

        const control = makeControl();

        verify(control.isLive);
        compare(control.secondsUntilEmpty, 4500);
        compare(control.secondsUntilFull, 0);
    }

    function test_chargingMouseShowsBolt() {
        bridge.addMouse({
            percentage: 0.5,
            state: UPowerDeviceState.Charging
        });

        const control = makeControl();

        compare(control.percent, 50);
        verify(control.isPluggedIn);
        verify(control.shouldShowBolt);
        verify(!control.isFullyCharged);
    }

    function test_chargingMouseShowsTimeUntilFull() {
        bridge.addMouse({
            state: UPowerDeviceState.Charging,
            timeToFull: 2700,
            timeToEmpty: 9999
        });

        const control = makeControl();

        verify(control.isLive);
        compare(control.secondsUntilFull, 2700);
        compare(control.secondsUntilEmpty, 0);
    }

    function test_chargingMouseWithoutEstimateHasNoDuration() {
        bridge.addMouse({
            state: UPowerDeviceState.Charging,
            timeToEmpty: 9999
        });

        const control = makeControl();

        verify(control.isLive);
        compare(control.secondsUntilEmpty, 0);
        compare(control.secondsUntilFull, 0);
    }

    function test_fullyChargedMouseShowsBolt() {
        bridge.addMouse({
            state: UPowerDeviceState.FullyCharged
        });

        const control = makeControl();

        verify(control.shouldShowBolt);
        verify(control.isFullyCharged);
        verify(control.isPluggedIn);
    }

    function test_boltStaysHiddenWhenDisabled() {
        bridge.addMouse({
            state: UPowerDeviceState.Charging
        });

        const control = makeControl({
            showBolt: false
        });

        verify(control.isPluggedIn);
        verify(!control.shouldShowBolt);
    }

    function test_labelStaysHiddenWhenPercentageDisabled() {
        bridge.addMouse({});

        const control = makeControl({
            showPercentage: false
        });

        verify(control.isLive);
        verify(!control.shouldShowLabel);
    }

    function test_mouseTurningUnknownKeepsLastReading() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        verify(control.isLive);
        bridge.update(mouse, {
            percentage: 0.42
        });
        compare(control.percent, 42);

        bridge.update(mouse, {
            state: UPowerDeviceState.Unknown
        });

        verify(!control.isLive);
        verify(control.isStale);
        verify(control.isMouseDetected);
        compare(control.percent, 42);
        compare(control.label, "42%");
        compare(control.deviceName, "Test Mouse");
    }

    function test_removedMouseKeepsLastReading() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        verify(control.isLive);
        bridge.update(mouse, {
            percentage: 0.42
        });
        compare(control.percent, 42);

        bridge.remove(mouse);

        verify(!control.isLive);
        verify(control.isStale);
        verify(control.hasData);
        verify(!control.isMouseDetected);
        compare(control.label, "42%");
        compare(control.deviceName, "Test Mouse");
    }

    function test_returningMouseReplacesStaleReading() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        verify(control.isLive);

        bridge.remove(mouse);
        verify(control.isStale);

        bridge.addMouse({
            percentage: 0.63,
            model: "Returned Mouse"
        });

        verify(control.isLive);
        verify(!control.isStale);
        compare(control.percent, 63);
        compare(control.deviceName, "Returned Mouse");
    }
}
