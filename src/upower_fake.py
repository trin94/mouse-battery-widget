# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""In-process fake of the Quickshell.Services.UPower QML module for QML tests."""

from enum import IntEnum

from PySide6.QtCore import Property, QEnum, QObject, Signal
from PySide6.QtQml import QmlElement, QmlSingleton, QmlUncreatable

QML_IMPORT_NAME = "Quickshell.Services.UPower"
QML_IMPORT_MAJOR_VERSION = 1


def register() -> None:
    """Importing this module already registers the fake QML types."""


@QmlElement
@QmlUncreatable("UPowerDeviceState only holds enum values")
class UPowerDeviceState(QObject):
    @QEnum
    class State(IntEnum):
        Unknown = 0
        Charging = 1
        Discharging = 2
        Empty = 3
        FullyCharged = 4
        PendingCharge = 5
        PendingDischarge = 6


@QmlElement
@QmlUncreatable("UPowerDeviceType only holds enum values")
class UPowerDeviceType(QObject):
    @QEnum
    class Type(IntEnum):
        Unknown = 0
        LinePower = 1
        Battery = 2
        Ups = 3
        Monitor = 4
        Mouse = 5
        Keyboard = 6


@QmlElement
class UPowerDevice(QObject):
    typeChanged = Signal()
    stateChanged = Signal()
    percentageChanged = Signal()
    modelChanged = Signal()
    timeToEmptyChanged = Signal()
    timeToFullChanged = Signal()
    readyChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._type = int(UPowerDeviceType.Type.Unknown)
        self._state = int(UPowerDeviceState.State.Unknown)
        self._percentage = 0.0
        self._model = ""
        self._time_to_empty = 0.0
        self._time_to_full = 0.0
        self._ready = True

    def _get_type(self) -> int:
        return self._type

    def _set_type(self, value: int) -> None:
        if self._type != value:
            self._type = value
            self.typeChanged.emit()

    def _get_state(self) -> int:
        return self._state

    def _set_state(self, value: int) -> None:
        if self._state != value:
            self._state = value
            self.stateChanged.emit()

    def _get_percentage(self) -> float:
        return self._percentage

    def _set_percentage(self, value: float) -> None:
        if self._percentage != value:
            self._percentage = value
            self.percentageChanged.emit()

    def _get_model(self) -> str:
        return self._model

    def _set_model(self, value: str) -> None:
        if self._model != value:
            self._model = value
            self.modelChanged.emit()

    def _get_time_to_empty(self) -> float:
        return self._time_to_empty

    def _set_time_to_empty(self, value: float) -> None:
        if self._time_to_empty != value:
            self._time_to_empty = value
            self.timeToEmptyChanged.emit()

    def _get_time_to_full(self) -> float:
        return self._time_to_full

    def _set_time_to_full(self, value: float) -> None:
        if self._time_to_full != value:
            self._time_to_full = value
            self.timeToFullChanged.emit()

    def _get_ready(self) -> bool:
        return self._ready

    def _set_ready(self, value: bool) -> None:
        if self._ready != value:
            self._ready = value
            self.readyChanged.emit()

    type = Property(int, _get_type, _set_type, notify=typeChanged)
    state = Property(int, _get_state, _set_state, notify=stateChanged)
    percentage = Property(float, _get_percentage, _set_percentage, notify=percentageChanged)
    model = Property(str, _get_model, _set_model, notify=modelChanged)
    timeToEmpty = Property(float, _get_time_to_empty, _set_time_to_empty, notify=timeToEmptyChanged)
    timeToFull = Property(float, _get_time_to_full, _set_time_to_full, notify=timeToFullChanged)
    ready = Property(bool, _get_ready, _set_ready, notify=readyChanged)


class FakeDeviceModel(QObject):
    """Stands in for Quickshell's ObjectModel holding the UPower devices."""

    valuesChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._values: list[UPowerDevice] = []

    def _get_values(self) -> list[UPowerDevice]:
        return list(self._values)

    values = Property(list, _get_values, notify=valuesChanged)

    def add(self, device: UPowerDevice) -> None:
        self._values = [*self._values, device]
        self.valuesChanged.emit()

    def contains(self, device: UPowerDevice) -> bool:
        return any(d is device for d in self._values)

    def remove(self, device: UPowerDevice) -> None:
        self._values = [d for d in self._values if d is not device]
        self.valuesChanged.emit()

    def clear(self) -> None:
        for device in self._values:
            device.deleteLater()
        self._values = []
        self.valuesChanged.emit()


_DEVICE_MODEL = FakeDeviceModel()


def device_model() -> FakeDeviceModel:
    return _DEVICE_MODEL


@QmlElement
@QmlSingleton
class UPower(QObject):
    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._devices = _DEVICE_MODEL

    def _get_devices(self) -> FakeDeviceModel:
        return self._devices

    devices = Property(QObject, _get_devices, constant=True)
