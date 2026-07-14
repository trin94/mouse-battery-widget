// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginComponent {
    id: root

    readonly property int textSize: Theme.barTextSize(barThickness, barConfig?.fontScale, barConfig?.maximizeWidgetText)
    readonly property color contentColor: viewModel.hasMouse ? Theme.surfaceText : Theme.surfaceTextSecondary

    readonly property MouseBatteryViewModel viewModel: MouseBatteryViewModel {
        showPercentage: root.pluginData?.showPercentage ?? true
        showBolt: root.pluginData?.showBolt ?? true
    }

    popoutContent: Component {
        MouseBatteryPopout {
            viewModel: root.viewModel
        }
    }

    horizontalBarPill: Component {
        Row {
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
    }

    verticalBarPill: Component {
        Column {
            spacing: 0

            DankIcon {
                id: mouseIconV
                name: "mouse"
                size: root.iconSize
                color: root.contentColor
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
    }
}
