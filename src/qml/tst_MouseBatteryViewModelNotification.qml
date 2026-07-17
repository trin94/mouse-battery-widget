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
    name: "MouseBatteryViewModelNotification"

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

    function makeSpy(target, signalName): SignalSpy {
        const spy = createTemporaryObject(signalSpy, testCase, {
            target: target,
            signalName: signalName
        });
        verify(spy);
        return spy;
    }

    function test_notifiesWhenLevelDropsBelowThreshold() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.2
        });

        compare(spy.count, 1);
        compare(spy.signalArguments[0][0], 20);
        compare(spy.signalArguments[0][1], "Test Mouse");
    }

    function test_doesNotNotifyAgainWhileStillLow() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.2
        });
        bridge.update(mouse, {
            percentage: 0.15
        });

        compare(spy.count, 1);
    }

    function test_alreadyLowMouseDoesNotNotifyOnStartup() {
        const mouse = bridge.addMouse({
            percentage: 0.1
        });

        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");
        bridge.update(mouse, {
            percentage: 0.05
        });

        compare(spy.count, 0);
    }

    function test_mouseWakingUpLowNotifies() {
        const mouse = bridge.addMouse({
            state: UPowerDeviceState.Unknown,
            percentage: 0.15
        });
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            state: UPowerDeviceState.Discharging
        });

        compare(spy.count, 1);
    }

    function test_notifiesAgainAfterRecharge() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.2
        });
        bridge.update(mouse, {
            percentage: 0.8
        });
        bridge.update(mouse, {
            percentage: 0.19
        });

        compare(spy.count, 2);
    }

    function test_notifiesAgainAfterChargingInBetween() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.18
        });
        bridge.update(mouse, {
            state: UPowerDeviceState.Charging
        });
        bridge.update(mouse, {
            state: UPowerDeviceState.Discharging
        });

        compare(spy.count, 2);
    }

    function test_sleepingLowMouseDoesNotNotifyAgain() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.15
        });
        bridge.update(mouse, {
            state: UPowerDeviceState.Unknown
        });
        bridge.update(mouse, {
            state: UPowerDeviceState.Discharging
        });

        compare(spy.count, 1);
    }

    function test_reconnectingLowMouseDoesNotNotifyAgain() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.15
        });
        bridge.remove(mouse);
        bridge.addMouse({
            percentage: 0.15
        });

        compare(spy.count, 1);
    }

    function test_chargingMouseDoesNotNotify() {
        const mouse = bridge.addMouse({
            state: UPowerDeviceState.Charging,
            percentage: 0.5
        });
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.1
        });

        compare(spy.count, 0);
    }

    function test_raisingThresholdAboveLevelNotifies() {
        bridge.addMouse({
            percentage: 0.4
        });
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        control.lowBatteryPercent = 50;

        compare(spy.count, 1);
        compare(spy.signalArguments[0][0], 40);
    }
}
