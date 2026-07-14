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
NO_DATA_PERCENT = -1
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

    state = vm.wait_state(itemgetter("isReporting"))
    assert state["percent"] == DEFAULT_PERCENTAGE
    assert state["label"] == "100%"
    assert state["deviceName"] == "Test Mouse"
    assert state["level"] == pytest.approx(DEFAULT_PERCENTAGE / 100)
    assert not state["isPluggedIn"]
    assert not state["isFullyCharged"]
    assert not state["isLow"]
    assert not state["boltVisible"]
    assert state["labelVisible"]
    assert not state["durationSeconds"]


def test_charging_mouse_shows_bolt(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    percentage = 50.0
    mock.update_device(mouse, Percentage=percentage, State=STATE_CHARGING)

    vm = make_view_model()

    state = vm.wait_state(lambda s: s["percent"] == percentage and s["isPluggedIn"])
    assert state["boltVisible"]
    assert not state["isFullyCharged"]


def test_fully_charged_mouse_shows_bolt(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, State=STATE_FULLY_CHARGED)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("boltVisible"))
    assert state["isFullyCharged"]
    assert state["isPluggedIn"]


def test_property_updates_propagate(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    vm = make_view_model()
    vm.wait_state(itemgetter("isReporting"))

    percentage = 12.0
    mock.update_device(mouse, Percentage=percentage, State=STATE_CHARGING)

    state = vm.wait_state(lambda s: s["percent"] == percentage)
    assert state["boltVisible"]
    assert state["isPluggedIn"]
    assert not state["isLow"]


def test_removed_mouse_keeps_last_reading(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    vm = make_view_model()
    vm.wait_state(itemgetter("isReporting"))

    percentage = 42.0
    mock.update_device(mouse, Percentage=percentage)
    vm.wait_state(lambda s: s["percent"] == percentage)

    mock.remove_device(mouse)

    state = vm.wait_state(lambda s: not s["isReporting"])
    assert state["isStale"]
    assert state["hasData"]
    assert not state["isMouseDetected"]
    assert state["label"] == "42%"
    assert state["deviceName"] == "Test Mouse"
    assert state["percent"] == percentage
    assert state["level"] == pytest.approx(percentage / 100)
    assert not state["isPluggedIn"]
    assert not state["boltVisible"]
    assert state["labelVisible"]


def test_no_readings_yet_shows_empty_state(make_view_model: MakeViewModel) -> None:
    vm = make_view_model()

    state = vm.wait_ready()
    assert not state["isReporting"]
    assert not state["hasData"]
    assert not state["isStale"]
    assert not state["isMouseDetected"]
    assert not state["label"]
    assert not state["labelVisible"]
    assert state["deviceName"] == "Mouse"
    assert state["percent"] == NO_DATA_PERCENT
    assert state["level"] == 0


def test_returning_mouse_replaces_stale_reading(
    mock: UPowerMock, mouse: str, add_mouse: AddMouse, make_view_model: MakeViewModel
) -> None:
    vm = make_view_model()
    vm.wait_state(itemgetter("isReporting"))

    mock.remove_device(mouse)
    vm.wait_state(itemgetter("isStale"))

    percentage = 63.0
    add_mouse(Percentage=percentage, Model="Returned Mouse")

    state = vm.wait_state(itemgetter("isReporting"))
    assert not state["isStale"]
    assert state["percent"] == percentage
    assert state["deviceName"] == "Returned Mouse"


def test_mouse_added_at_runtime_is_picked_up(add_mouse: AddMouse, make_view_model: MakeViewModel) -> None:
    vm = make_view_model()
    state = vm.wait_ready()
    assert not state["isReporting"]

    percentage = 42.0
    add_mouse(Percentage=percentage)

    state = vm.wait_state(itemgetter("isReporting"))
    assert state["percent"] == percentage


def test_bolt_stays_hidden_when_disabled(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, State=STATE_CHARGING)

    vm = make_view_model(showBolt=False)

    state = vm.wait_state(itemgetter("isPluggedIn"))
    assert not state["boltVisible"]


def test_label_stays_hidden_when_percentage_disabled(mouse: str, make_view_model: MakeViewModel) -> None:
    vm = make_view_model(showPercentage=False)

    state = vm.wait_state(itemgetter("isReporting"))
    assert not state["labelVisible"]


def test_discharging_mouse_shows_time_remaining(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    time_to_empty = 4500
    mock.update_device(mouse, TimeToEmpty=time_to_empty)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("isReporting"))
    assert state["durationSeconds"] == time_to_empty


def test_charging_mouse_shows_time_until_full(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    time_to_full = 2700
    mock.update_device(mouse, State=STATE_CHARGING, TimeToFull=time_to_full, TimeToEmpty=9999)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("isReporting"))
    assert state["durationSeconds"] == time_to_full


def test_charging_mouse_without_estimate_has_no_duration(
    mock: UPowerMock, mouse: str, make_view_model: MakeViewModel
) -> None:
    mock.update_device(mouse, State=STATE_CHARGING, TimeToEmpty=9999)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("isReporting"))
    assert not state["durationSeconds"]


def test_low_discharging_mouse_is_marked_low(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, Percentage=LOW_BATTERY_PERCENTAGE)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("isReporting"))
    assert state["isLow"]


def test_mouse_above_low_threshold_is_not_marked_low(
    mock: UPowerMock, mouse: str, make_view_model: MakeViewModel
) -> None:
    mock.update_device(mouse, Percentage=LOW_BATTERY_PERCENTAGE + 1)

    vm = make_view_model()

    state = vm.wait_state(itemgetter("isReporting"))
    assert not state["isLow"]


def test_mouse_without_model_gets_fallback_name(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, Model="")

    vm = make_view_model()

    state = vm.wait_state(itemgetter("isReporting"))
    assert state["deviceName"] == "Mouse"


def test_mouse_with_unknown_state_is_ignored(mock: UPowerMock, mouse: str, make_view_model: MakeViewModel) -> None:
    mock.update_device(mouse, State=STATE_UNKNOWN)

    vm = make_view_model()

    vm.wait_ready()
    time.sleep(0.5)
    state = vm.state()
    assert state is not None
    assert not state["isReporting"]
    assert state["isMouseDetected"]


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
    assert not state["isReporting"]
    assert not state["isMouseDetected"]
    assert state["deviceName"] == "Mouse"


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

    state = vm.wait_state(itemgetter("isReporting"))
    assert state["percent"] == percentage
    assert state["deviceName"] == "Test Mouse"


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, *sys.argv[1:]]))
