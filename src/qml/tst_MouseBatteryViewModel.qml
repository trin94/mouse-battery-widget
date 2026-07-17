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
}
