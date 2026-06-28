// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "MouseBatteryViewModel"

    readonly property int typeMouse: 5
    readonly property int typeKeyboard: 6
    readonly property int stateCharging: 1
    readonly property int stateDischarging: 2
    readonly property int stateFullyCharged: 4

    component MockDevice: QtObject {
        property bool ready: true
        property int type: testCase.typeMouse
        property real percentage: 0.79
        property int state: testCase.stateDischarging
        property string model: "Logitech PRO X 2"
    }

    readonly property MockDevice mouse: MockDevice {}
    readonly property MockDevice mouseCharging: MockDevice {
        state: testCase.stateCharging
    }
    readonly property MockDevice mouseFullyCharged: MockDevice {
        state: testCase.stateFullyCharged
    }
    readonly property MockDevice mouseWithoutModel: MockDevice {
        model: ""
    }
    readonly property MockDevice mouseNotReady: MockDevice {
        ready: false
        percentage: 0.5
    }
    readonly property MockDevice keyboard: MockDevice {
        type: testCase.typeKeyboard
        percentage: 0.5
    }

    Component {
        id: objectUnderTest

        MouseBatteryViewModel {
            mouseType: testCase.typeMouse
            chargingStates: [testCase.stateCharging, testCase.stateFullyCharged]
            stateToString: state => String(state)
        }
    }

    function makeControl(devices) {
        const control = createTemporaryObject(objectUnderTest, testCase, {
            devices
        });
        verify(control);
        return control;
    }

    function test_no_mouse() {
        const control = makeControl([]);
        verify(!control.present);
        compare(control.percent, -1);
        compare(control.label, "—");
        compare(control.name, "No mouse connected");
    }

    function test_connected_mouse() {
        const control = makeControl([mouse]);
        verify(control.present);
        compare(control.percent, 79);
        compare(control.label, "79%");
        compare(control.name, "Logitech PRO X 2");
        compare(control.detail, "79% · " + testCase.stateDischarging);
    }

    function test_charging() {
        const whenCharging = makeControl([mouseCharging]);
        verify(whenCharging.charging);

        const whenFullyCharged = makeControl([mouseFullyCharged]);
        verify(whenFullyCharged.charging);

        const whenDischarging = makeControl([mouse]);
        verify(!whenDischarging.charging);
    }

    function test_name_falls_back_without_model() {
        const control = makeControl([mouseWithoutModel]);
        compare(control.name, "Mouse");
    }

    function test_selects_first_ready_mouse() {
        const control = makeControl([keyboard, mouseNotReady, mouse]);
        verify(control.present);
        compare(control.percent, 79);
    }
}
