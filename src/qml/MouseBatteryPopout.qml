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

    detailsText: viewModel.emptyStateText

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

            to: {
                if (root.viewModel.tone === MouseBatteryViewModel.Tone.Stale)
                    return Theme.surfaceVariantText;
                if (root.viewModel.tone === MouseBatteryViewModel.Tone.Low)
                    return Theme.error;
                if (root.viewModel.tone === MouseBatteryViewModel.Tone.Charging)
                    return Theme.primary;
                return Theme.surfaceText;
            }
        }

        DankColorAnimation {
            id: barColorAnimation

            to: {
                if (root.viewModel.tone === MouseBatteryViewModel.Tone.Stale)
                    return Theme.withAlpha(Theme.primary, 0.4);
                if (root.viewModel.tone === MouseBatteryViewModel.Tone.Low)
                    return Theme.error;
                return Theme.primary;
            }
        }

        Row {
            spacing: Theme.spacingS

            StyledText {
                text: root.viewModel.percentText
                font.pixelSize: Theme.fontSizeXLarge
                font.weight: Font.Bold
                color: batteryDetails.stateColor
            }

            StyledText {
                text: root.viewModel.statusText
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                visible: !!root.viewModel.statusText
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

        StyledText {
            text: root.viewModel.estimateText
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            visible: !!root.viewModel.estimateText
        }

        StyledText {
            text: root.viewModel.deviceName
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
    }
}
