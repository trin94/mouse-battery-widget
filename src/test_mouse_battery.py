# /// script
# requires-python = ">=3.9"
# dependencies = ["pytest", "dbus-fast"]
# ///

# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""System tests running the real quickshell binary against a mocked upowerd.

Each test starts a private D-Bus bus serving an in-process fake upowerd and
a headless quickshell instance loading probe.qml straight from src/, which
keeps the view model inside quickshell's config-folder import boundary. The
probe is a generic stub: tests create the object under test through its IPC
interface and read back the derived state, so they observe what the view
model computes from Quickshell's real UPower client code.
"""

import itertools
import sys
import time

import pytest

from harness import ProbeSession, UPowerMock, ViewModel

TYPE_MOUSE = 5
TYPE_KEYBOARD = 6
STATE_UNKNOWN = 0
STATE_CHARGING = 1
STATE_DISCHARGING = 2
STATE_FULLY_CHARGED = 4


@pytest.fixture
def mock():
    upower = UPowerMock()
    yield upower
    upower.close()


@pytest.fixture
def probe_session(mock):
    session = ProbeSession(mock)
    yield session
    session.close()


@pytest.fixture
def make_view_model(probe_session):
    def start(**properties):
        return ViewModel(probe_session, **properties)

    return start


@pytest.fixture
def add_mouse(mock):
    ids = itertools.count()

    def add(**props):
        device_id = next(ids)
        defaults = {
            "Type": TYPE_MOUSE,
            "State": STATE_DISCHARGING,
            "Percentage": 100.0,
            "Model": "Test Mouse",
            "NativePath": f"hidpp_battery_{device_id}",
        }
        return mock.add_device(f"mouse_{device_id}", **{**defaults, **props})

    return add


@pytest.fixture
def mouse(add_mouse):
    return add_mouse()


def test_discharging_mouse_is_shown(mouse, make_view_model):
    vm = make_view_model()

    state = vm.wait_state(lambda s: s["hasMouse"])
    assert state["percent"] == 100
    assert state["label"] == "100%"
    assert state["deviceName"] == "Test Mouse"
    assert state["status"] == "100% · Discharging"
    assert not state["boltVisible"]
    assert state["labelVisible"]


def test_charging_mouse_shows_bolt(mock, mouse, make_view_model):
    mock.update_device(mouse, Percentage=50.0, State=STATE_CHARGING)

    vm = make_view_model()

    state = vm.wait_state(lambda s: s["status"] == "50% · Charging")
    assert state["boltVisible"]


def test_fully_charged_mouse_shows_bolt(mock, mouse, make_view_model):
    mock.update_device(mouse, State=STATE_FULLY_CHARGED)

    vm = make_view_model()

    state = vm.wait_state(lambda s: s["boltVisible"])
    assert state["status"] == "100% · Fully Charged"


def test_property_updates_propagate(mock, mouse, make_view_model):
    vm = make_view_model()
    vm.wait_state(lambda s: s["hasMouse"])

    mock.update_device(mouse, Percentage=12.0, State=STATE_CHARGING)

    state = vm.wait_state(lambda s: s["percent"] == 12)
    assert state["boltVisible"]
    assert state["status"] == "12% · Charging"


def test_removed_mouse_shows_disconnected(mock, mouse, make_view_model):
    vm = make_view_model()
    vm.wait_state(lambda s: s["hasMouse"])

    mock.remove_device(mouse)

    state = vm.wait_state(lambda s: not s["hasMouse"])
    assert state["label"] == "—"
    assert state["deviceName"] == "No mouse connected"
    assert state["percent"] == -1
    assert state["status"] == ""
    assert not state["boltVisible"]
    assert state["labelVisible"]


def test_mouse_added_at_runtime_is_picked_up(add_mouse, make_view_model):
    vm = make_view_model()
    state = vm.wait_ready()
    assert not state["hasMouse"]

    add_mouse(Percentage=42.0)

    state = vm.wait_state(lambda s: s["hasMouse"])
    assert state["percent"] == 42


def test_bolt_stays_hidden_when_disabled(mock, mouse, make_view_model):
    mock.update_device(mouse, State=STATE_CHARGING)

    vm = make_view_model(showBolt=False)

    state = vm.wait_state(lambda s: s["status"] == "100% · Charging")
    assert not state["boltVisible"]


def test_label_stays_hidden_when_percentage_disabled(mouse, make_view_model):
    vm = make_view_model(showPercentage=False)

    state = vm.wait_state(lambda s: s["hasMouse"])
    assert not state["labelVisible"]


def test_mouse_without_model_gets_fallback_name(mock, mouse, make_view_model):
    mock.update_device(mouse, Model="")

    vm = make_view_model()

    state = vm.wait_state(lambda s: s["hasMouse"])
    assert state["deviceName"] == "Mouse"


def test_mouse_with_unknown_state_is_ignored(mock, mouse, make_view_model):
    mock.update_device(mouse, State=STATE_UNKNOWN)

    vm = make_view_model()

    vm.wait_ready()
    time.sleep(0.5)
    assert not vm.state()["hasMouse"]


def test_non_mouse_devices_are_ignored(mock, make_view_model):
    mock.add_device(
        "keyboard_test",
        Type=TYPE_KEYBOARD,
        State=STATE_DISCHARGING,
        Percentage=50.0,
        Model="Test Keyboard",
    )

    vm = make_view_model()

    vm.wait_ready()
    time.sleep(0.5)
    state = vm.state()
    assert not state["hasMouse"]
    assert state["deviceName"] == "No mouse connected"


def test_qualifying_mouse_is_picked_among_other_devices(mock, add_mouse, make_view_model):
    mock.add_device(
        "keyboard_test",
        Type=TYPE_KEYBOARD,
        State=STATE_DISCHARGING,
        Percentage=50.0,
        Model="Test Keyboard",
    )
    add_mouse(State=STATE_UNKNOWN, Model="Unknown Mouse")
    add_mouse(Percentage=63.0)

    vm = make_view_model()

    state = vm.wait_state(lambda s: s["hasMouse"])
    assert state["percent"] == 63
    assert state["deviceName"] == "Test Mouse"


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, *sys.argv[1:]]))
