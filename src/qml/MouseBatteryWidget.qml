// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property MouseBatteryViewModel viewModel: MouseBatteryViewModel {
        showPercentage: root.pluginData?.showPercentage ?? MouseBatteryDefaults.showPercentage
        showBolt: root.pluginData?.showBolt ?? MouseBatteryDefaults.showBolt
        lowBatteryPercent: root.pluginData?.lowBatteryPercent ?? MouseBatteryDefaults.lowBatteryPercent
        notifyOnLowBattery: root.pluginData?.notifyOnLowBattery ?? MouseBatteryDefaults.notifyOnLowBattery
    }

    popoutContent: Component {
        MouseBatteryPopout {
            viewModel: root.viewModel
        }
    }

    horizontalBarPill: Component {
        MouseBatteryHorizontalPill {
            viewModel: root.viewModel
            iconSize: root.iconSize
            barThickness: root.barThickness
            barConfig: root.barConfig
        }
    }

    verticalBarPill: Component {
        MouseBatteryVerticalPill {
            viewModel: root.viewModel
            iconSize: root.iconSize
            barThickness: root.barThickness
            barConfig: root.barConfig
        }
    }
}
