// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

import QtQuick

import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "mouseBatteryWidget"

    StyledText {
        width: parent.width
        text: I18n.tr("Mouse Battery Widget")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
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
}
