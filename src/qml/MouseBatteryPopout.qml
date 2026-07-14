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

    // qmlformat off
    detailsText: viewModel.hasMouse ? ""
        : viewModel.isMouseDetected ? I18n.tr("No recent battery data. Waiting for the mouse to report.")
        : I18n.tr("No supported mouse detected.")
    // qmlformat on

    showCloseButton: true

    Column {
        id: batteryDetails

        readonly property color stateColor: stateColorAnimation.value
        readonly property color barColor: barColorAnimation.value

        x: Theme.spacingS
        width: parent.width - Theme.spacingS * 2
        bottomPadding: Theme.spacingS
        spacing: Theme.spacingS
        visible: root.viewModel.hasData

        DankColorAnimation {
            id: stateColorAnimation

            // qmlformat off
            to: root.viewModel.isStale ? Theme.surfaceVariantText
                : root.viewModel.isLow ? Theme.error
                : root.viewModel.isCharging ? Theme.primary
                : Theme.surfaceText
            // qmlformat on
        }

        DankColorAnimation {
            id: barColorAnimation

            // qmlformat off
            to: root.viewModel.isStale ? Theme.withAlpha(Theme.primary, 0.4)
                : root.viewModel.isLow ? Theme.error
                : Theme.primary
            // qmlformat on
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

        StyledText {
            text: root.viewModel.isCharging ? I18n.tr("Time until full: %1").arg(root.viewModel.durationText) : I18n.tr("Time remaining: %1").arg(root.viewModel.durationText)
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            visible: root.viewModel.durationText.length > 0
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
