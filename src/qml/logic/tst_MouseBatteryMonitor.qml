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
    name: "MouseBatteryMonitor"

    Component {
        id: objectUnderTest

        MouseBatteryMonitor {
            lowBatteryPercent: 20
            enabled: true
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

    function makeControl(initProperties = {}): MouseBatteryMonitor {
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
        compare(spy.signalArguments[0][0], 15);
    }

    function test_wakingMouseWithUnreadPercentageDoesNotNotify() {
        const mouse = bridge.addMouse({
            state: UPowerDeviceState.Unknown,
            percentage: 0
        });
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            state: UPowerDeviceState.Discharging
        });
        bridge.update(mouse, {
            percentage: 0.77
        });

        compare(spy.count, 0);
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

    function test_chargingBelowMarginDoesNotRearm() {
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

        compare(spy.count, 1);
    }

    function test_chargingPastMarginRearms() {
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
            percentage: 0.5
        });
        bridge.update(mouse, {
            state: UPowerDeviceState.Discharging
        });
        bridge.update(mouse, {
            percentage: 0.18
        });

        compare(spy.count, 2);
    }

    function test_jitterAroundThresholdNotifiesOnce() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.2
        });
        bridge.update(mouse, {
            percentage: 0.21
        });
        bridge.update(mouse, {
            percentage: 0.2
        });

        compare(spy.count, 1);
    }

    function test_recoveryToMarginDoesNotRearm() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.2
        });
        bridge.update(mouse, {
            percentage: 0.25
        });
        bridge.update(mouse, {
            percentage: 0.2
        });

        compare(spy.count, 1);
    }

    function test_recoveryAboveMarginRearms() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.2
        });
        bridge.update(mouse, {
            percentage: 0.26
        });
        bridge.update(mouse, {
            percentage: 0.19
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

    function test_chargingMouseDoesNotNotify_data() {
        return [
            {
                tag: "charging",
                state: UPowerDeviceState.Charging
            },
            {
                tag: "pendingCharge",
                state: UPowerDeviceState.PendingCharge
            }
        ];
    }

    function test_chargingMouseDoesNotNotify(data) {
        const mouse = bridge.addMouse({
            state: data.state,
            percentage: 0.5
        });
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.1
        });

        compare(spy.count, 0);
    }

    function test_loweringThresholdPastMarginRearms() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");
        bridge.update(mouse, {
            percentage: 0.15
        });
        compare(spy.count, 1);

        control.lowBatteryPercent = 5;
        bridge.update(mouse, {
            percentage: 0.05
        });

        compare(spy.count, 2);
    }

    function test_loweringThresholdWithinMarginKeepsLatch() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        const spy = makeSpy(control, "lowBatteryReached");
        bridge.update(mouse, {
            percentage: 0.15
        });
        compare(spy.count, 1);

        control.lowBatteryPercent = 12;
        bridge.update(mouse, {
            percentage: 0.12
        });

        compare(spy.count, 1);
    }

    function test_zeroThresholdNotifiesOnlyAtEmpty() {
        const mouse = bridge.addMouse({});
        const control = makeControl({
            lowBatteryPercent: 0
        });
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.01
        });
        compare(spy.count, 0);

        bridge.update(mouse, {
            percentage: 0.004
        });
        compare(spy.count, 1);
    }

    function test_fullThresholdNotifiesOnAppearance() {
        const control = makeControl({
            lowBatteryPercent: 100
        });
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.addMouse({});

        compare(spy.count, 1);
    }

    function test_disabledNotificationStaysSilent() {
        const mouse = bridge.addMouse({});
        const control = makeControl({
            enabled: false
        });
        const spy = makeSpy(control, "lowBatteryReached");

        bridge.update(mouse, {
            percentage: 0.15
        });

        compare(spy.count, 0);
    }

    function test_enablingWhileLowDoesNotNotify() {
        const mouse = bridge.addMouse({});
        const control = makeControl({
            enabled: false
        });
        const spy = makeSpy(control, "lowBatteryReached");
        bridge.update(mouse, {
            percentage: 0.15
        });

        control.enabled = true;

        compare(spy.count, 0);

        bridge.update(mouse, {
            percentage: 0.8
        });
        bridge.update(mouse, {
            percentage: 0.19
        });

        compare(spy.count, 1);
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
