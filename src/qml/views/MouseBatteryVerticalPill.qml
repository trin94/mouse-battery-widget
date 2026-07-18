// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Widgets

import "../logic"

Column {
    id: root

    required property MouseBatteryViewModel viewModel
    required property int iconSize
    required property real barThickness
    required property var barConfig

    readonly property int textSize: Theme.barTextSize(barThickness, barConfig?.fontScale, barConfig?.maximizeWidgetText)
    readonly property color contentColor: viewModel.isDimmed ? Theme.surfaceTextSecondary : Theme.surfaceText

    spacing: 0

    DankIcon {
        id: mouseIcon
        name: "mouse"
        size: root.iconSize
        color: root.contentColor
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Item {
        width: mouseIcon.width
        height: root.viewModel.showsBolt ? Theme.spacingXS + root.iconSize : 0
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true

        DankIcon {
            name: "bolt"
            size: root.iconSize
            color: Theme.primary
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingXS
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.viewModel.showsBolt ? 1 : 0

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
        width: labelText.implicitWidth
        height: root.viewModel.barLabel ? Theme.spacingXS + labelText.implicitHeight : 0
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true

        StyledText {
            id: labelText
            text: root.viewModel.barLabel
            font.pixelSize: root.textSize
            color: root.contentColor
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
