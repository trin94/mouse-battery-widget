// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

import Quickshell
import Quickshell.Io

import "qml"

ShellRoot {
    id: root

    property var objectUnderTest: null

    IpcHandler {
        target: "test"

        function ping(): bool {
            return true;
        }

        function create(kwargs: string): string {
            if (root.objectUnderTest) {
                root.objectUnderTest.destroy();
                root.objectUnderTest = null;
            }
            root.objectUnderTest = viewModelFactory.createObject(root, JSON.parse(kwargs));
            return root.objectUnderTest ? "" : "could not create view model";
        }

        function read(): string {
            if (!root.objectUnderTest)
                return "";
            const result = {};
            for (const name of Object.keys(root.objectUnderTest)) {
                const value = root.objectUnderTest[name];
                if (typeof value !== "object" && typeof value !== "function")
                    result[name] = value;
            }
            return JSON.stringify(result);
        }
    }

    Component {
        id: viewModelFactory

        MouseBatteryViewModel {
            showPercentage: true
            showBolt: true
        }
    }
}
