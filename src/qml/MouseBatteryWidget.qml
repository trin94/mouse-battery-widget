// SPDX-FileCopyrightText: Elias Mueller
//
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick

import Quickshell

import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property MouseBatteryViewModel viewModel: MouseBatteryViewModel {
        showPercentage: root.pluginData?.showPercentage ?? true
        showBolt: root.pluginData?.showBolt ?? true
        lowBatteryPercent: root.pluginData?.lowBatteryPercent ?? 20
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

    Connections {
        target: root.viewModel

        function onLowBatteryReached(percent: int, deviceName: string) {
            const summary = I18n.tr("Mouse battery low");
            const body = I18n.tr("%1 is at %2%. Recharge it soon.").arg(deviceName).arg(percent);
            Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "Mouse Battery Widget", "-i", "battery-caution", summary, body]);
        }
    }
}
