// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

QtObject {
    id: root

    property list<string> targets: ["MouseBatteryWidget.qml", "MouseBatteryDaemon.qml", "MouseBatterySettings.qml"]

    function check(): var {
        for (const target of root.targets) {
            const component = Qt.createComponent(target, Component.PreferSynchronous);
            if (component.status === Component.Error) {
                console.warn("MouseBatteryWidget: startup check failed:", component.errorString());
                return {
                    title: "Incompatible DMS or Quickshell installation",
                    details: component.errorString()
                };
            }
        }
        console.info("MouseBatteryWidget: startup check passed");
        return null;
    }
}
