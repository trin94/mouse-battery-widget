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

    function formatDuration(seconds: real): string {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? I18n.tr("%1h %2m").arg(hours).arg(minutes) : I18n.tr("%1m").arg(minutes);
    }

    headerText: viewModel.deviceName

    // qmlformat off
    detailsText: viewModel.isLive ? ""
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
                : root.viewModel.isPluggedIn ? Theme.primary
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
                // qmlformat off
                text: root.viewModel.isFullyCharged ? I18n.tr("Fully charged")
                    : root.viewModel.isPluggedIn ? I18n.tr("Charging")
                    : I18n.tr("Discharging")
                // qmlformat on
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                visible: root.viewModel.isLive
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StyledText {
            text: I18n.tr("Time remaining: %1").arg(root.formatDuration(root.viewModel.secondsUntilEmpty))
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            visible: root.viewModel.secondsUntilEmpty > 0
        }

        StyledText {
            text: I18n.tr("Time until full: %1").arg(root.formatDuration(root.viewModel.secondsUntilFull))
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            visible: root.viewModel.secondsUntilFull > 0
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
