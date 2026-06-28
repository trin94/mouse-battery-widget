// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell.Services.UPower
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginComponent {
    id: root

    readonly property int textSize: Theme.barTextSize(barThickness, barConfig?.fontScale, barConfig?.maximizeWidgetText)

    readonly property QtObject viewModel: QtObject {
        readonly property var device: UPower.devices.values.find(d => d && d.ready && d.type === UPowerDeviceType.Mouse) ?? null
        readonly property bool present: device !== null
        readonly property int percent: present ? Math.round(device.percentage * 100) : -1
        readonly property bool charging: present && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged)
        readonly property string label: present ? percent + "%" : "—"
        readonly property string name: present ? (device.model || UPowerDeviceType.toString(device.type)) : "No mouse connected"
        readonly property string detail: present ? percent + "% · " + UPowerDeviceState.toString(device.state) : ""
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: root.viewModel.name
            detailsText: root.viewModel.detail
            showCloseButton: true
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "mouse"
                size: root.iconSize
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            DankIcon {
                name: "bolt"
                size: root.iconSize
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
                visible: opacity > 0
                opacity: root.viewModel.charging ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            StyledText {
                text: root.viewModel.label
                font.pixelSize: root.textSize
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "mouse"
                size: root.iconSize
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            DankIcon {
                name: "bolt"
                size: root.iconSize
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
                visible: opacity > 0
                opacity: root.viewModel.charging ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            StyledText {
                text: root.viewModel.label
                font.pixelSize: root.textSize
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }
    }
}
