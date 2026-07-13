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
from operator import itemgetter
from typing import TYPE_CHECKING

import pytest

from harness import ProbeSession, UPowerMock, ViewModel

if TYPE_CHECKING:
    from collections.abc import Callable, Iterator

type MakeViewModel = Callable[..., ViewModel]
type AddMouse = Callable[..., str]

TYPE_MOUSE = 5
TYPE_KEYBOARD = 6
STATE_UNKNOWN = 0
STATE_CHARGING = 1
STATE_DISCHARGING = 2
STATE_FULLY_CHARGED = 4

DEFAULT_PERCENTAGE = 100.0
DISCONNECTED_PERCENT = -1
LOW_BATTERY_PERCENTAGE = 20.0


@pytest.fixture
def mock() -> Iterator[UPowerMock]:
    upower = UPowerMock()
    yield upower
    upower.close()


@pytest.fixture
def probe_session(mock: UPowerMock) -> Iterator[ProbeSession]:
    session = ProbeSession(mock)
    yield session
    session.close()


@pytest.fixture
def make_view_model(probe_session: ProbeSession) -> MakeViewModel:
    def start(**properties: object) -> ViewModel:
        return ViewModel(probe_session, **properties)

    return start


@pytest.fixture
def add_mouse(mock: UPowerMock) -> AddMouse:
    ids = itertools.count()

    def add(**props: object) -> str:
        device_id = next(ids)
        defaults = {
            "Type": TYPE_MOUSE,
            "State": STATE_DISCHARGING,
            "Percentage": DEFAULT_PERCENTAGE,
            "Model": "Test Mouse",
            "NativePath": f"hidpp_battery_{device_id}",
        }
        return mock.add_device(f"mouse_{device_id}", **{**defaults, **props})

    return add


@pytest.fixture
def mouse(add_mouse: AddMouse) -> str:
    return add_mouse()


def test_discharging_mouse_is_shown(mouse: str, make_view_model: MakeViewModel) -> None:
    vm = make_view_model()

    state = vm.wait_state(itemgetter("hasMouse"))
    assert state["percent"] == DEFAULT_PERCENTAGE
    assert state["label"] == "100%"
    assert state["deviceName"] == "Test Mouse"
    assert state["stateText"] == "Discharging"
    assert state["level"] == pytest.approx(DEFAULT_PERCENTAGE / 100)
    assert not state["isCharging"]
    assert not state["isLow"]
    assert not state["boltVisible"]
    assert state["labelVisible"]


def test_charging_mouse_shows_bolt(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    percentage = 50.0
    mock.update_device(mouse, Percentage=percentage, State=STATE_CHARGING)

    vm = make_view_model()

    state = vm.wait_state(lambda s: s["percent"] == percentage and s["stateText"] == "Charging")
    assert state["boltVisible"]
    assert state["isCharging"]


def test_fully_charged_mouse_shows_bolt(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, State=STATE_FULLY_CHARGED)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("boltVisible"))
    assert state["stateText"] == "Fully Charged"
    assert state["isCharging"]


def test_property_updates_propagate(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    vm = make_view_model()
    vm.wait_state(itemgetter("hasMouse"))

    percentage = 12.0
    mock.update_device(mouse, Percentage=percentage, State=STATE_CHARGING)

    state = vm.wait_state(lambda s: s["percent"] == percentage)
    assert state["boltVisible"]
    assert state["stateText"] == "Charging"
    assert not state["isLow"]


def test_removed_mouse_shows_disconnected(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    vm = make_view_model()
    vm.wait_state(itemgetter("hasMouse"))

    mock.remove_device(mouse)

    state = vm.wait_state(lambda s: not s["hasMouse"])
    assert state["label"] == "—"
    assert state["deviceName"] == "No mouse connected"
    assert state["percent"] == DISCONNECTED_PERCENT
    assert state["level"] == 0
    assert not state["stateText"]
    assert not state["boltVisible"]
    assert state["labelVisible"]


def test_mouse_added_at_runtime_is_picked_up(add_mouse: AddMouse, make_view_model: MakeViewModel) -> None:
    vm = make_view_model()
    state = vm.wait_ready()
    assert not state["hasMouse"]

    percentage = 42.0
    add_mouse(Percentage=percentage)

    state = vm.wait_state(itemgetter("hasMouse"))
    assert state["percent"] == percentage


def test_bolt_stays_hidden_when_disabled(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, State=STATE_CHARGING)

    vm = make_view_model(showBolt=False)

    state = vm.wait_state(lambda s: s["stateText"] == "Charging")
    assert not state["boltVisible"]
    assert state["isCharging"]


def test_label_stays_hidden_when_percentage_disabled(mouse: str, make_view_model: MakeViewModel) -> None:
    vm = make_view_model(showPercentage=False)

    state = vm.wait_state(itemgetter("hasMouse"))
    assert not state["labelVisible"]


def test_low_discharging_mouse_is_marked_low(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, Percentage=LOW_BATTERY_PERCENTAGE)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("hasMouse"))
    assert state["isLow"]


def test_mouse_above_low_threshold_is_not_marked_low(
    mock: UPowerMock, mouse: str, make_view_model: MakeViewModel
) -> None:
    mock.update_device(mouse, Percentage=LOW_BATTERY_PERCENTAGE + 1)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("hasMouse"))
    assert not state["isLow"]


def test_mouse_without_model_gets_fallback_name(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, Model="")

    vm = make_view_model()

    state = vm.wait_state(itemgetter("hasMouse"))
    assert state["deviceName"] == "Mouse"


def test_mouse_with_unknown_state_is_ignored(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, State=STATE_UNKNOWN)

    vm = make_view_model()

    vm.wait_ready()
    time.sleep(0.5)
    state = vm.state()
    assert state is not None
    assert not state["hasMouse"]


def test_non_mouse_devices_are_ignored(mock: UPowerMock, make_view_model: MakeViewModel) -> None:
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
    assert state is not None
    assert not state["hasMouse"]
    assert state["deviceName"] == "No mouse connected"


def test_qualifying_mouse_is_picked_among_other_devices(
    mock: UPowerMock, add_mouse: AddMouse, make_view_model: MakeViewModel
) -> None:
    mock.add_device(
        "keyboard_test",
        Type=TYPE_KEYBOARD,
        State=STATE_DISCHARGING,
        Percentage=50.0,
        Model="Test Keyboard",
    )
    add_mouse(State=STATE_UNKNOWN, Model="Unknown Mouse")
    percentage = 63.0
    add_mouse(Percentage=percentage)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("hasMouse"))
    assert state["percent"] == percentage
    assert state["deviceName"] == "Test Mouse"


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, *sys.argv[1:]]))
