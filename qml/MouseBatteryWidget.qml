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

    readonly property MouseBatteryViewModel viewModel: MouseBatteryViewModel {
        devices: UPower.devices.values
        mouseType: UPowerDeviceType.Mouse
        chargingStates: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged]
        stateToString: state => UPowerDeviceState.toString(state)
        showPercentage: root.pluginData?.showPercentage ?? true
        showBolt: root.pluginData?.showBolt ?? true
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
                opacity: root.viewModel.boltVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            StyledText {
                text: root.viewModel.label
                visible: root.viewModel.labelVisible
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
                opacity: root.viewModel.boltVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            StyledText {
                text: root.viewModel.label
                visible: root.viewModel.labelVisible
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
