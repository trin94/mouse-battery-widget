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
    readonly property int stateUnknown: 0
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
    readonly property MockDevice mouseUnknown: MockDevice {
        state: testCase.stateUnknown
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
            unknownState: testCase.stateUnknown
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

    function test_device_presence() {
        const present = makeControl([mouse]);
        verify(present.hasMouse);
        compare(present.percent, 79);

        const absent = makeControl([]);
        verify(!absent.hasMouse);
        compare(absent.percent, -1);

        const nullDevices = makeControl(null);
        verify(!nullDevices.hasMouse);
    }

    function test_device_selection() {
        const control = makeControl([keyboard, mouseNotReady, mouseUnknown, mouse]);
        verify(control.hasMouse);
        compare(control.percent, 79);

        const onlyUnmeasured = makeControl([mouseUnknown]);
        verify(!onlyUnmeasured.hasMouse);
    }

    function test_pill_bolt_visibility() {
        const whenCharging = makeControl([mouseCharging]);
        verify(whenCharging.boltVisible);

        const whenFullyCharged = makeControl([mouseFullyCharged]);
        verify(whenFullyCharged.boltVisible);

        const whenDischarging = makeControl([mouse]);
        verify(!whenDischarging.boltVisible);

        const whenHidden = makeControl([mouseCharging]);
        whenHidden.showBolt = false;
        verify(!whenHidden.boltVisible);

        const whenAbsent = makeControl([]);
        verify(!whenAbsent.boltVisible);
    }

    function test_pill_label_text() {
        const present = makeControl([mouse]);
        compare(present.label, "79%");

        const absent = makeControl([]);
        compare(absent.label, "—");
    }

    function test_pill_label_visibility() {
        const shown = makeControl([mouse]);
        verify(shown.labelVisible);

        const hidden = makeControl([mouse]);
        hidden.showPercentage = false;
        verify(!hidden.labelVisible);

        const absentStillShown = makeControl([]);
        verify(absentStillShown.labelVisible);
    }

    function test_popout_device_name() {
        const withModel = makeControl([mouse]);
        compare(withModel.deviceName, "Logitech PRO X 2");

        const withoutModel = makeControl([mouseWithoutModel]);
        compare(withoutModel.deviceName, "Generic Mouse");

        const absent = makeControl([]);
        compare(absent.deviceName, "Nothing connected");
    }

    function test_popout_status() {
        const present = makeControl([mouse]);
        compare(present.status, "79% · " + testCase.stateDischarging);

        const absent = makeControl([]);
        compare(absent.status, "");
    }
}
