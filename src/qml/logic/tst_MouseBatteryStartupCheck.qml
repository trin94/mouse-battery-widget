// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick
import QtTest

import ".."

TestCase {
    id: testCase

    width: 400
    height: 400
    visible: true
    when: windowShown
    name: "MouseBatteryStartupCheck"

    Component {
        id: objectUnderTest

        MouseBatteryStartupCheck {}
    }

    function makeControl(initProperties = {}): MouseBatteryStartupCheck {
        const control = createTemporaryObject(objectUnderTest, testCase, initProperties);
        verify(control);
        return control;
    }

    function test_defaultTargetsAreTheEntryPoints() {
        const control = makeControl();

        compare(control.targets, ["MouseBatteryWidget.qml", "MouseBatteryDaemon.qml", "MouseBatterySettings.qml"]);
    }

    function test_compilableTargetsReturnNull() {
        const control = makeControl({
            targets: ["logic/MouseBatteryDefaults.qml"]
        });

        compare(control.check(), null);
    }

    function test_failingTargetReportsError() {
        const control = makeControl({
            targets: ["DoesNotExist.qml"]
        });

        ignoreWarning(new RegExp("MouseBatteryWidget: startup check failed: .+"));
        const result = control.check();

        verify(result !== null);
        verify(result.title.length > 0);
        verify(result.details.length > 0);
    }
}
