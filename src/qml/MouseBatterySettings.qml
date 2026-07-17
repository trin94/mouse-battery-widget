// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root

    readonly property string _homepage: pluginService?.availablePlugins?.[pluginId]?.homepage ?? ""

    pluginId: "mouseBatteryWidget"

    StyledText {
        text: I18n.tr("Bar")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "showPercentage"
        label: I18n.tr("Show battery percentage")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showBolt"
        label: I18n.tr("Show charging indicator")
        defaultValue: true
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
        label: I18n.tr("Threshold")
        description: I18n.tr("Battery percentage at or below which the battery counts as low")
        defaultValue: 20
        minimum: 0
        maximum: 100
        unit: "%"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        text: I18n.tr("GitHub")
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
