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

from dbus_fast.aio import MessageBus
from dbus_fast.service import PropertyAccess, ServiceInterface, dbus_property, method, signal

PROBE_QML = os.path.join(os.path.dirname(os.path.abspath(__file__)), "probe.qml")

UPOWER_BUS_NAME = "org.freedesktop.UPower"
UPOWER_PATH = "/org/freedesktop/UPower"
DEVICE_IFACE = "org.freedesktop.UPower.Device"
DEVICE_PATH_PREFIX = "/org/freedesktop/UPower/devices/"
DISPLAY_DEVICE_NAME = "DisplayDevice"

DEVICE_DEFAULTS = {
    "Type": 0,
    "State": 0,
    "Percentage": 0.0,
    "IsPresent": True,
    "IsRechargeable": True,
    "PowerSupply": False,
    "Online": False,
    "Model": "",
    "NativePath": "",
    "IconName": "",
    "Energy": 0.0,
    "EnergyFull": 0.0,
    "EnergyRate": 0.0,
    "TimeToEmpty": 0,
    "TimeToFull": 0,
    "WarningLevel": 1,
}


def wait_until(probe, timeout=10.0, interval=0.1):
    """Poll probe() until it returns a truthy value or the timeout expires."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        result = probe()
        if result:
            return result
        time.sleep(interval)
    return None


class _Device(ServiceInterface):
    def __init__(self, values):
        super().__init__(DEVICE_IFACE)
        self.values = values

    @dbus_property(access=PropertyAccess.READ)
    def Type(self) -> "u":
        return self.values["Type"]

    @dbus_property(access=PropertyAccess.READ)
    def State(self) -> "u":
        return self.values["State"]

    @dbus_property(access=PropertyAccess.READ)
    def Percentage(self) -> "d":
        return self.values["Percentage"]

    @dbus_property(access=PropertyAccess.READ)
    def IsPresent(self) -> "b":
        return self.values["IsPresent"]

    @dbus_property(access=PropertyAccess.READ)
    def IsRechargeable(self) -> "b":
        return self.values["IsRechargeable"]

    @dbus_property(access=PropertyAccess.READ)
    def PowerSupply(self) -> "b":
        return self.values["PowerSupply"]

    @dbus_property(access=PropertyAccess.READ)
    def Online(self) -> "b":
        return self.values["Online"]

    @dbus_property(access=PropertyAccess.READ)
    def Model(self) -> "s":
        return self.values["Model"]

    @dbus_property(access=PropertyAccess.READ)
    def NativePath(self) -> "s":
        return self.values["NativePath"]

    @dbus_property(access=PropertyAccess.READ)
    def IconName(self) -> "s":
        return self.values["IconName"]

    @dbus_property(access=PropertyAccess.READ)
    def Energy(self) -> "d":
        return self.values["Energy"]

    @dbus_property(access=PropertyAccess.READ)
    def EnergyFull(self) -> "d":
        return self.values["EnergyFull"]

    @dbus_property(access=PropertyAccess.READ)
    def EnergyRate(self) -> "d":
        return self.values["EnergyRate"]

    @dbus_property(access=PropertyAccess.READ)
    def TimeToEmpty(self) -> "x":
        return self.values["TimeToEmpty"]

    @dbus_property(access=PropertyAccess.READ)
    def TimeToFull(self) -> "x":
        return self.values["TimeToFull"]

    @dbus_property(access=PropertyAccess.READ)
    def WarningLevel(self) -> "u":
        return self.values["WarningLevel"]


class _Root(ServiceInterface):
    def __init__(self):
        super().__init__(UPOWER_BUS_NAME)
        self.device_paths = []

    @method()
    def EnumerateDevices(self) -> "ao":
        return list(self.device_paths)

    @method()
    def GetDisplayDevice(self) -> "o":
        return DEVICE_PATH_PREFIX + DISPLAY_DEVICE_NAME

    @method()
    def GetCriticalAction(self) -> "s":
        return "HybridSleep"

    @dbus_property(access=PropertyAccess.READ)
    def DaemonVersion(self) -> "s":
        return "0.99"

    @dbus_property(access=PropertyAccess.READ)
    def OnBattery(self) -> "b":
        return False

    @signal()
    def DeviceAdded(self, path) -> "o":
        return path

    @signal()
    def DeviceRemoved(self, path) -> "o":
        return path


class UPowerMock:
    """A fake upowerd owning org.freedesktop.UPower on its own private bus."""

    def __init__(self):
        self._bus = None
        self._loop = None
        self._thread = None
        self._devices = {}
        self._daemon = subprocess.Popen(
            ["dbus-daemon", "--session", "--print-address=1", "--nofork"],
            stdout=subprocess.PIPE,
            text=True,
        )
        self.address = self._daemon.stdout.readline().strip()
        if not self.address:
            self.close()
            raise RuntimeError("dbus-daemon did not report a bus address")

        self._loop = asyncio.new_event_loop()
        self._thread = threading.Thread(target=self._loop.run_forever, daemon=True)
        self._thread.start()
        try:
            self._run(self._serve())
        except Exception:
            self.close()
            raise

    def add_device(self, name, **props):
        unknown = set(props) - set(DEVICE_DEFAULTS)
        if unknown:
            raise ValueError(f"unknown UPower device properties: {sorted(unknown)}")
        return self._run(self._add_device(name, {**DEVICE_DEFAULTS, **props}))

    def update_device(self, path, **props):
        self._run(self._update_device(path, props))

    def remove_device(self, path):
        self._run(self._remove_device(path))

    def client_env(self, base):
        env = dict(base)
        env["DBUS_SYSTEM_BUS_ADDRESS"] = self.address
        return env

    def close(self):
        if self._loop is not None:
            self._loop.call_soon_threadsafe(self._loop.stop)
            self._thread.join(timeout=5)
        self._daemon.terminate()
        try:
            self._daemon.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self._daemon.kill()
        self._daemon.stdout.close()

    def _run(self, coroutine):
        return asyncio.run_coroutine_threadsafe(coroutine, self._loop).result(timeout=10)

    async def _serve(self):
        self._bus = await MessageBus(bus_address=self.address).connect()
        self._root = _Root()
        self._bus.export(UPOWER_PATH, self._root)
        await self._add_device(DISPLAY_DEVICE_NAME, {**DEVICE_DEFAULTS, "IsPresent": False})
        await self._bus.request_name(UPOWER_BUS_NAME)

    async def _add_device(self, name, values):
        path = DEVICE_PATH_PREFIX + name
        if path in self._devices:
            raise ValueError(f"device already exists: {path}")
        device = _Device(values)
        self._bus.export(path, device)
        self._devices[path] = device
        if name != DISPLAY_DEVICE_NAME:
            self._root.device_paths.append(path)
            self._root.DeviceAdded(path)
        return path

    async def _update_device(self, path, props):
        device = self._devices[path]
        device.values.update(props)
        device.emit_properties_changed({name: device.values[name] for name in props})

    async def _remove_device(self, path):
        self._root.device_paths.remove(path)
        self._root.DeviceRemoved(path)
        self._bus.unexport(path)
        del self._devices[path]


class ProbeSession:
    """A headless quickshell instance loading probe.qml on the mock's bus."""

    def __init__(self, mock):
        self._env = mock.client_env(os.environ)
        self._env["QT_QPA_PLATFORM"] = "offscreen"
        self._env.pop("WAYLAND_DISPLAY", None)
        self._env.pop("DISPLAY", None)
        self._log = tempfile.NamedTemporaryFile(
            mode="w", prefix="mouse-battery-system-test-", suffix=".log", delete=False
        )
        self._process = subprocess.Popen(
            ["qs", "-p", PROBE_QML],
            env=self._env,
            stdout=self._log,
            stderr=subprocess.STDOUT,
        )

    @property
    def log_path(self):
        return self._log.name

    def create(self, properties):
        if wait_until(lambda: self._ipc("ping")) is None:
            raise AssertionError(f"quickshell IPC did not come up, log: {self.log_path}")
        error = self._ipc("create", json.dumps(properties))
        if error != "":
            raise AssertionError(f"could not create object under test: {error}")

    def read(self):
        output = self._ipc("read")
        if not output:
            return None
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            return None

    def close(self):
        self._process.terminate()
        try:
            self._process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self._process.kill()
        self._log.close()

    def _ipc(self, *args):
        result = subprocess.run(
            ["qs", "ipc", "--any-display", "--newest", "-p", PROBE_QML, "call", "test", *args],
            env=self._env,
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode != 0:
            return None
        return result.stdout.strip()


class ViewModel:
    """Handle on a MouseBatteryViewModel instantiated inside the probe."""

    def __init__(self, session, **properties):
        self._session = session
        session.create(properties)

    def state(self):
        return self._session.read()

    def wait_state(self, predicate, timeout=10.0):
        def probe():
            state = self.state()
            if state is not None and predicate(state):
                return state
            return None

        state = wait_until(probe, timeout)
        if state is None:
            raise AssertionError(
                f"view model state did not settle within {timeout}s, "
                f"quickshell log: {self._session.log_path}"
            )
        return state

    def wait_ready(self):
        return self.wait_state(lambda state: True)
