# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Harness for the system tests.

UPowerMock serves org.freedesktop.UPower on a private dbus-daemon using
dbus-fast, running an asyncio loop on a background thread. ProbeSession
runs a headless quickshell against that bus, loading probe.qml as config.
ViewModel wraps the object under test that the probe instantiates. Only
the bus daemon and quickshell itself are separate processes.
"""

import asyncio
import json
import os
import subprocess
import tempfile
import threading
import time
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from collections.abc import Callable, Coroutine, Mapping

from dbus_fast.aio import MessageBus

from upower_service import (
    DEVICE_DEFAULTS,
    DEVICE_PATH_PREFIX,
    DISPLAY_DEVICE_NAME,
    UPOWER_BUS_NAME,
    UPOWER_PATH,
    DeviceService,
    RootService,
)

PROBE_QML = Path(__file__).resolve().parent / "probe.qml"


def wait_until[T](probe: Callable[[], T | None], timeout: float = 10.0, interval: float = 0.1) -> T | None:
    """Poll probe() until it returns a truthy value or the timeout expires."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        result = probe()
        if result:
            return result
        time.sleep(interval)
    return None


class UPowerMock:
    """A fake upowerd owning org.freedesktop.UPower on its own private bus."""

    def __init__(self) -> None:
        self._bus: MessageBus | None = None
        self._devices: dict[str, DeviceService] = {}
        self._daemon = subprocess.Popen(
            ["dbus-daemon", "--session", "--print-address=1", "--nofork"],
            stdout=subprocess.PIPE,
            text=True,
        )
        self._loop = asyncio.new_event_loop()
        self._thread = threading.Thread(target=self._loop.run_forever, daemon=True)
        self._thread.start()

        stdout = self._daemon.stdout
        self.address = stdout.readline().strip() if stdout is not None else ""
        if not self.address:
            self.close()
            message = "dbus-daemon did not report a bus address"
            raise RuntimeError(message)

        try:
            self._run(self._serve())
        except Exception:
            self.close()
            raise

    def add_device(self, name: str, **props: object) -> str:
        unknown = set(props) - set(DEVICE_DEFAULTS)
        if unknown:
            message = f"unknown UPower device properties: {sorted(unknown)}"
            raise ValueError(message)
        return self._run(self._add_device(name, {**DEVICE_DEFAULTS, **props}))

    def update_device(self, path: str, **props: object) -> None:
        self._run(self._update_device(path, props))

    def remove_device(self, path: str) -> None:
        self._run(self._remove_device(path))

    def client_env(self, base: Mapping[str, str]) -> dict[str, str]:
        env = dict(base)
        env["DBUS_SYSTEM_BUS_ADDRESS"] = self.address
        return env

    def close(self) -> None:
        self._loop.call_soon_threadsafe(self._loop.stop)
        self._thread.join(timeout=5)
        self._daemon.terminate()
        try:
            self._daemon.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self._daemon.kill()
        if self._daemon.stdout is not None:
            self._daemon.stdout.close()

    def _run[T](self, coroutine: Coroutine[Any, Any, T]) -> T:
        return asyncio.run_coroutine_threadsafe(coroutine, self._loop).result(timeout=10)

    def _require_bus(self) -> MessageBus:
        if self._bus is None:
            message = "mock bus is not connected"
            raise RuntimeError(message)
        return self._bus

    async def _serve(self) -> None:
        self._bus = await MessageBus(bus_address=self.address).connect()
        self._root = RootService()
        self._bus.export(UPOWER_PATH, self._root)
        await self._add_device(DISPLAY_DEVICE_NAME, {**DEVICE_DEFAULTS, "IsPresent": False})
        await self._bus.request_name(UPOWER_BUS_NAME)

    async def _add_device(self, name: str, values: dict[str, object]) -> str:
        path = DEVICE_PATH_PREFIX + name
        if path in self._devices:
            message = f"device already exists: {path}"
            raise ValueError(message)
        device = DeviceService(values)
        self._require_bus().export(path, device)
        self._devices[path] = device
        if name != DISPLAY_DEVICE_NAME:
            self._root.device_paths.append(path)
            self._root.DeviceAdded(path)
        return path

    async def _update_device(self, path: str, props: dict[str, object]) -> None:
        device = self._devices[path]
        device.values.update(props)
        device.emit_properties_changed({name: device.values[name] for name in props})

    async def _remove_device(self, path: str) -> None:
        self._root.device_paths.remove(path)
        self._root.DeviceRemoved(path)
        self._require_bus().unexport(path)
        del self._devices[path]


class ProbeSession:
    """A headless quickshell instance loading probe.qml on the mock's bus."""

    def __init__(self, mock: UPowerMock) -> None:
        self._env = mock.client_env(os.environ)
        self._env["QT_QPA_PLATFORM"] = "offscreen"
        self._env.pop("WAYLAND_DISPLAY", None)
        self._env.pop("DISPLAY", None)
        with tempfile.NamedTemporaryFile(
            mode="w", prefix="mouse-battery-system-test-", suffix=".log", delete=False, encoding="utf-8"
        ) as log:
            self._log_path = log.name
            self._process = subprocess.Popen(
                ["qs", "-p", PROBE_QML],
                env=self._env,
                stdout=log,
                stderr=subprocess.STDOUT,
            )

    @property
    def log_path(self) -> str:
        return self._log_path

    def create(self, properties: dict[str, object]) -> None:
        if wait_until(lambda: self._ipc("ping")) is None:
            message = f"quickshell IPC did not come up, log: {self.log_path}"
            raise AssertionError(message)
        error = self._ipc("create", json.dumps(properties))
        if error is None or error:
            message = f"could not create object under test: {error}"
            raise AssertionError(message)

    def read(self) -> dict | None:
        output = self._ipc("read")
        if not output:
            return None
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            return None

    def close(self) -> None:
        self._process.terminate()
        try:
            self._process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self._process.kill()

    def _ipc(self, *args: str) -> str | None:
        result = subprocess.run(
            ["qs", "ipc", "--any-display", "--newest", "-p", PROBE_QML, "call", "test", *args],
            env=self._env,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        if result.returncode != 0:
            return None
        return result.stdout.strip()


class ViewModel:
    """Handle on a MouseBatteryViewModel instantiated inside the probe."""

    def __init__(self, session: ProbeSession, **properties: object) -> None:
        self._session = session
        session.create(properties)

    def state(self) -> dict | None:
        return self._session.read()

    def wait_state(self, predicate: Callable[[dict], object], timeout: float = 10.0) -> dict:
        def probe() -> dict | None:
            state = self.state()
            if state is not None and predicate(state):
                return state
            return None

        state = wait_until(probe, timeout)
        if state is None:
            message = f"view model state did not settle within {timeout}s, quickshell log: {self._session.log_path}"
            raise AssertionError(message)
        return state

    def wait_ready(self) -> dict:
        return self.wait_state(lambda _state: True)
