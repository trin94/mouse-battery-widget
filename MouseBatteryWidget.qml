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

    readonly property var mouseDevice: UPower.devices.values.find(d => d && d.ready && d.type === UPowerDeviceType.Mouse) ?? null
    readonly property bool mousePresent: mouseDevice !== null
    readonly property int batteryPercent: mousePresent ? Math.round(mouseDevice.percentage * 100) : -1
    readonly property string displayText: mousePresent ? batteryPercent + "%" : "—"
    readonly property bool charging: mousePresent && (mouseDevice.state === UPowerDeviceState.Charging || mouseDevice.state === UPowerDeviceState.FullyCharged)

    readonly property int textSize: Theme.barTextSize(barThickness, barConfig?.fontScale, barConfig?.maximizeWidgetText)

    popoutContent: Component {
        PopoutComponent {
            headerText: root.mousePresent ? root.mouseDevice.model : "No mouse connected"
            detailsText: root.mousePresent ? root.batteryPercent + "% · " + UPowerDeviceState.toString(root.mouseDevice.state) : ""
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
                size: root.charging ? root.iconSize : 0
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
                visible: opacity > 0
                opacity: root.charging ? 1 : 0

                Behavior on size {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            StyledText {
                text: root.displayText
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
                size: root.charging ? root.iconSize : 0
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
                visible: opacity > 0
                opacity: root.charging ? 1 : 0

                Behavior on size {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            StyledText {
                text: root.displayText
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
