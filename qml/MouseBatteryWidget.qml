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
        unknownState: UPowerDeviceState.Unknown
        chargingStates: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged]
        stateToString: state => I18n.tr(UPowerDeviceState.toString(state))
        showPercentage: root.pluginData?.showPercentage ?? true
        showBolt: root.pluginData?.showBolt ?? true
        fallbackName: I18n.tr("Mouse")
        disconnectedName: I18n.tr("No mouse connected")
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: root.viewModel.deviceName
            detailsText: root.viewModel.status
            showCloseButton: true
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: 0

            DankIcon {
                id: mouseIcon
                name: "mouse"
                size: root.iconSize
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                height: mouseIcon.height
                width: root.viewModel.boltVisible ? Theme.spacingXS + root.iconSize : 0
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                DankIcon {
                    name: "bolt"
                    size: root.iconSize
                    color: Theme.primary
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.viewModel.boltVisible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            Item {
                height: labelText.implicitHeight
                width: root.viewModel.labelVisible ? Theme.spacingXS + labelText.implicitWidth : 0
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                StyledText {
                    id: labelText
                    text: root.viewModel.label
                    font.pixelSize: root.textSize
                    color: Theme.surfaceText
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 0

            DankIcon {
                id: mouseIconV
                name: "mouse"
                size: root.iconSize
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item {
                width: mouseIconV.width
                height: root.viewModel.boltVisible ? Theme.spacingXS + root.iconSize : 0
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true

                DankIcon {
                    name: "bolt"
                    size: root.iconSize
                    color: Theme.primary
                    anchors.top: parent.top
                    anchors.topMargin: Theme.spacingXS
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: root.viewModel.boltVisible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            Item {
                width: labelTextV.implicitWidth
                height: root.viewModel.labelVisible ? Theme.spacingXS + labelTextV.implicitHeight : 0
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true

                StyledText {
                    id: labelTextV
                    text: root.viewModel.label
                    font.pixelSize: root.textSize
                    color: Theme.surfaceText
                    anchors.top: parent.top
                    anchors.topMargin: Theme.spacingXS
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }
        }
    }
}
