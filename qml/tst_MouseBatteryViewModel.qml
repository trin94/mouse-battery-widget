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
            showPercentage: true
            showBolt: true
            fallbackName: "Generic Mouse"
            disconnectedName: "Nothing connected"
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
        verify(!control.hasMouse);
        compare(control.percent, -1);
        compare(control.label, "—");
        compare(control.deviceName, "Nothing connected");
    }

    function test_connected_mouse() {
        const control = makeControl([mouse]);
        verify(control.hasMouse);
        compare(control.percent, 79);
        compare(control.label, "79%");
        compare(control.deviceName, "Logitech PRO X 2");
        compare(control.status, "79% · " + testCase.stateDischarging);
    }

    function test_bolt_visibility() {
        const whenCharging = makeControl([mouseCharging]);
        verify(whenCharging.boltVisible);

        const whenFullyCharged = makeControl([mouseFullyCharged]);
        verify(whenFullyCharged.boltVisible);

        const whenDischarging = makeControl([mouse]);
        verify(!whenDischarging.boltVisible);

        const whenHidden = makeControl([mouseCharging]);
        whenHidden.showBolt = false;
        verify(!whenHidden.boltVisible);
    }

    function test_name_falls_back_without_model() {
        const control = makeControl([mouseWithoutModel]);
        compare(control.deviceName, "Generic Mouse");
    }

    function test_selects_first_ready_mouse() {
        const control = makeControl([keyboard, mouseNotReady, mouse]);
        verify(control.hasMouse);
        compare(control.percent, 79);
    }

    function test_label_visibility() {
        const shown = makeControl([mouse]);
        verify(shown.labelVisible);

        const hidden = makeControl([mouse]);
        hidden.showPercentage = false;
        verify(!hidden.labelVisible);

        const noMouseStillShown = makeControl([]);
        verify(noMouseStillShown.labelVisible);
    }
}
