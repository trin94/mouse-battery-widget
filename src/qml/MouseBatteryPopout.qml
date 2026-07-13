// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PopoutComponent {
    id: root

    required property MouseBatteryViewModel viewModel

    headerText: viewModel.deviceName
    detailsText: viewModel.hasMouse ? "" : I18n.tr("Connect a mouse to see its battery level.")
    showCloseButton: true

    Column {
        id: batteryDetails

        readonly property color stateColor: stateColorAnimation.value
        readonly property color barColor: barColorAnimation.value

        x: Theme.spacingS
        width: parent.width - Theme.spacingS * 2
        bottomPadding: Theme.spacingS
        spacing: Theme.spacingS
        visible: root.viewModel.hasMouse

        DankColorAnimation {
            id: stateColorAnimation
            to: root.viewModel.isLow ? Theme.error : root.viewModel.isCharging ? Theme.primary : Theme.surfaceText
        }

        DankColorAnimation {
            id: barColorAnimation
            to: root.viewModel.isLow ? Theme.error : Theme.primary
        }

        Row {
            spacing: Theme.spacingS

            StyledText {
                text: root.viewModel.label
                font.pixelSize: Theme.fontSizeXLarge
                font.weight: Font.Bold
                color: batteryDetails.stateColor
            }

            StyledText {
                text: root.viewModel.stateText
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: parent.width
            height: 8
            radius: height / 2
            color: Theme.surfaceVariantAlpha

            Rectangle {
                width: parent.width * root.viewModel.level
                height: parent.height
                radius: parent.radius
                color: batteryDetails.barColor

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }
        }
    }
}
