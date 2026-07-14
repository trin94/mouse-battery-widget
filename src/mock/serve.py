# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Serve a controllable mock mouse and run the preview bar against it.

Runs UPowerMock with one mouse device on a private bus and a quickshell
instance rendering preview/ against it. The device is adjustable at
runtime through a control interface on the session bus. Orchestrated by
mod.just.
"""

import asyncio
import os
import signal
import subprocess
import sys
import threading
from pathlib import Path

from dbus_fast.aio import MessageBus
from dbus_fast.service import ServiceInterface, method

from harness import UPowerMock

PREVIEW_DIR = Path(__file__).resolve().parent / "preview"

CONTROL_NAME = "io.github.trin94.MouseBatteryWidget.Mock"
STATES = {"charging": 1, "discharging": 2, "full": 4}

MOUSE_TYPE = 5
DEVICE_NAME = "mock_mouse"
MOCK_MOUSE: dict[str, object] = {
    "Type": MOUSE_TYPE,
    "State": STATES["discharging"],
    "Percentage": 75.0,
    "Model": "Mock Mouse",
    "NativePath": "hidpp_battery_mock",
    "TimeToEmpty": 4500,
    "TimeToFull": 2700,
}


class MockMouse:
    """The mock mouse device, which can be unplugged and plugged back in.

    Property updates while unplugged are kept and applied on replug.
    """

    def __init__(self, mock: UPowerMock):
        self._mock = mock
        self._props = dict(MOCK_MOUSE)
        self._path: str | None = mock.add_device(DEVICE_NAME, **self._props)

    def update(self, **props: object) -> None:
        self._props.update(props)
        if self._path is not None:
            self._mock.update_device(self._path, **props)

    def set_connected(self, connected: bool) -> None:
        if connected and self._path is None:
            self._path = self._mock.add_device(DEVICE_NAME, **self._props)
        elif not connected and self._path is not None:
            self._mock.remove_device(self._path)
            self._path = None


class MockControlService(ServiceInterface):
    """Session-bus control surface to adjust the mock mouse at runtime."""

    def __init__(self, mouse: MockMouse):
        super().__init__(CONTROL_NAME)
        self._mouse = mouse

    @method()
    def SetPercentage(self, percentage: "d"):
        self._mouse.update(Percentage=percentage)

    @method()
    def SetState(self, state: "s"):
        self._mouse.update(State=STATES[state])

    @method()
    def SetConnected(self, connected: "b"):
        self._mouse.set_connected(connected)


def export_control(mouse: MockMouse) -> None:
    loop = asyncio.new_event_loop()
    threading.Thread(target=loop.run_forever, daemon=True).start()

    async def export() -> None:
        bus = await MessageBus().connect()
        bus.export("/", MockControlService(mouse))
        await bus.request_name(CONTROL_NAME)

    asyncio.run_coroutine_threadsafe(export(), loop).result(timeout=10)


def run() -> int:
    mock = UPowerMock()
    try:
        export_control(MockMouse(mock))
        process = subprocess.Popen(["qs", "-p", str(PREVIEW_DIR)], env=mock.client_env(os.environ))

        def terminate(_signum: int, _frame: object) -> None:
            process.terminate()

        signal.signal(signal.SIGTERM, terminate)
        signal.signal(signal.SIGINT, terminate)
        return process.wait()
    finally:
        mock.close()


if __name__ == "__main__":
    sys.exit(run())
