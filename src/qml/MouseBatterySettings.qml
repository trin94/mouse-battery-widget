// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

import qs.Common
import qs.Modules.Plugins
import qs.Widgets

import "logic"

PluginSettings {
    id: root

    readonly property string _homepage: pluginService?.availablePlugins?.[pluginId]?.homepage ?? ""

    pluginId: "mouseBatteryWidget"

    StyledText {
        text: I18n.tr("Bar", "status bar section title")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "showPercentage"
        label: I18n.tr("Show battery percentage")
        defaultValue: MouseBatteryDefaults.showPercentage
    }

    ToggleSetting {
        settingKey: "showBolt"
        label: I18n.tr("Show charging indicator")
        defaultValue: MouseBatteryDefaults.showBolt
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        text: I18n.tr("Low battery")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    SliderSetting {
        settingKey: "lowBatteryPercent"
        label: I18n.tr("Threshold", "low battery threshold")
        description: I18n.tr("Battery percentage at or below which the battery counts as low")
        defaultValue: MouseBatteryDefaults.lowBatteryPercent
        minimum: 0
        maximum: 100
        unit: "%"
    }

    ToggleSetting {
        settingKey: "notifyOnLowBattery"
        label: I18n.tr("Send a notification")
        defaultValue: MouseBatteryDefaults.notifyOnLowBattery
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        text: "GitHub"
        font.pixelSize: Theme.fontSizeSmall
        color: repoLinkArea.containsMouse ? Theme.primary : Theme.surfaceVariantText
        visible: !!root._homepage

        MouseArea {
            id: repoLinkArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally(root._homepage)
        }
    }
}
