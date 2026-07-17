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
    name: "MouseBatteryViewModelBar"

    Component {
        id: objectUnderTest

        MouseBatteryViewModel {
            showPercentage: true
            showBolt: true
            lowBatteryPercent: 20
        }
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

    function test_barSegments_data() {
        return [
            {
                tag: "aboveThreshold",
                percentage: 0.5,
                threshold: 20,
                expectedThresholdLevel: 0.2,
                expectedLowFill: 1,
                expectedHighFill: 0.375
            },
            {
                tag: "belowThreshold",
                percentage: 0.1,
                threshold: 20,
                expectedThresholdLevel: 0.2,
                expectedLowFill: 0.5,
                expectedHighFill: 0
            },
            {
                tag: "atThreshold",
                percentage: 0.2,
                threshold: 20,
                expectedThresholdLevel: 0.2,
                expectedLowFill: 1,
                expectedHighFill: 0
            },
            {
                tag: "zeroThreshold",
                percentage: 0.5,
                threshold: 0,
                expectedThresholdLevel: 0,
                expectedLowFill: 0,
                expectedHighFill: 0.5
            },
            {
                tag: "fullThreshold",
                percentage: 0.5,
                threshold: 100,
                expectedThresholdLevel: 1,
                expectedLowFill: 0.5,
                expectedHighFill: 0
            }
        ];
    }

    function test_barSegments(data) {
        bridge.addMouse({
            percentage: data.percentage
        });

        const control = makeControl({
            lowBatteryPercent: data.threshold
        });

        fuzzyCompare(control.thresholdLevel, data.expectedThresholdLevel, 1e-9);
        fuzzyCompare(control.lowSegmentFill, data.expectedLowFill, 1e-9);
        fuzzyCompare(control.highSegmentFill, data.expectedHighFill, 1e-9);
    }

    function test_showsLevelBar_data() {
        return [
            {
                tag: "noMouse",
                setup: () => {},
                expected: false
            },
            {
                tag: "liveMouse",
                setup: () => bridge.addMouse({}),
                expected: true
            },
            {
                tag: "sleepingMouse",
                setup: () => bridge.addMouse({
                        state: UPowerDeviceState.Unknown
                    }),
                expected: true
            },
            {
                tag: "removedMouse",
                setup: () => bridge.remove(bridge.addMouse({})),
                expected: false
            }
        ];
    }

    function test_showsLevelBar(data) {
        data.setup();

        compare(makeControl().showsLevelBar, data.expected);
    }

    function test_removedMouseKeepsDataButHidesBar() {
        const mouse = bridge.addMouse({});
        const control = makeControl();
        verify(control.showsLevelBar);

        bridge.remove(mouse);

        verify(control.hasData);
        verify(!control.showsLevelBar);
    }
}
