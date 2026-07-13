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
MOCK_MOUSE: dict[str, object] = {
    "Type": MOUSE_TYPE,
    "State": STATES["discharging"],
    "Percentage": 75.0,
    "Model": "Mock Mouse",
    "NativePath": "hidpp_battery_mock",
    "TimeToEmpty": 4500,
    "TimeToFull": 2700,
}


class MockControlService(ServiceInterface):
    """Session-bus control surface to adjust the mock mouse at runtime."""

    def __init__(self, update):
        super().__init__(CONTROL_NAME)
        self._update = update

    @method()
    def SetPercentage(self, percentage: "d"):
        self._update(Percentage=percentage)

    @method()
    def SetState(self, state: "s"):
        self._update(State=STATES[state])


def export_control(update) -> None:
    loop = asyncio.new_event_loop()
    threading.Thread(target=loop.run_forever, daemon=True).start()

    async def export() -> None:
        bus = await MessageBus().connect()
        bus.export("/", MockControlService(update))
        await bus.request_name(CONTROL_NAME)

    asyncio.run_coroutine_threadsafe(export(), loop).result(timeout=10)


def run() -> int:
    mock = UPowerMock()
    try:
        path = mock.add_device("mock_mouse", **MOCK_MOUSE)
        export_control(lambda **props: mock.update_device(path, **props))
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
