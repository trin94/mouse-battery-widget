// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Widgets

Row {
    id: root

    required property MouseBatteryViewModel viewModel
    required property int iconSize
    required property real barThickness
    required property var barConfig

    readonly property int textSize: Theme.barTextSize(barThickness, barConfig?.fontScale, barConfig?.maximizeWidgetText)
    readonly property color contentColor: viewModel.isLive ? Theme.surfaceText : Theme.surfaceTextSecondary

    spacing: 0

    DankIcon {
        id: mouseIcon
        name: "mouse"
        size: root.iconSize
        color: root.contentColor
        anchors.verticalCenter: parent.verticalCenter
    }

    Item {
        height: mouseIcon.height
        width: root.viewModel.shouldShowBolt ? Theme.spacingXS + root.iconSize : 0
        anchors.verticalCenter: parent.verticalCenter
        clip: true

        DankIcon {
            name: "bolt"
            size: root.iconSize
            color: Theme.primary
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.viewModel.shouldShowBolt ? 1 : 0

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
        width: root.viewModel.shouldShowLabel ? Theme.spacingXS + labelText.implicitWidth : 0
        anchors.verticalCenter: parent.verticalCenter
        clip: true

        StyledText {
            id: labelText
            text: root.viewModel.label
            font.pixelSize: root.textSize
            color: root.contentColor
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
