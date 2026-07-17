<!--
SPDX-FileCopyrightText: Elias Mueller

SPDX-License-Identifier: MIT
-->

# 🖱️ Mouse Battery Widget

A [Dank Material Shell](https://github.com/AvengeMedia/DankMaterialShell) plugin that shows your wireless mouse battery level in the bar.

- 🔋 Battery percentage in a bar pill.
- ⚡ Bolt icon while charging.
- 💤 Keeps the last reading visible but dimmed while the mouse sleeps or is disconnected.
- 🪟 Click for a popout with the mouse name, charge state, level bar, and time estimate.
- 🔌 Reads `Quickshell.Services.UPower` directly. No polling or shelling out.

## Requirements

You need Dank Material Shell and a mouse whose battery UPower reports. To check:

```sh
for d in $(upower -e); do upower -i "$d" | grep -q 'mouse' && echo "$d"; done
```

## Installation

This plugin is not yet in the official third-party plugin repository, so install it manually.

Clone the repo into the DMS plugins directory:

```sh
git clone https://github.com/trin94/mouse-battery-widget.git ~/.config/DankMaterialShell/plugins/mouse-battery-widget
```

Or clone it anywhere and symlink it in:

```sh
git clone https://github.com/trin94/mouse-battery-widget.git
mkdir -p ~/.config/DankMaterialShell/plugins
ln -s "$PWD/mouse-battery-widget" ~/.config/DankMaterialShell/plugins/mouse-battery-widget
```

Then add the widget to the bar from [the plugin settings](https://danklinux.com/docs/dankmaterialshell/plugin-development#5-load-it).

## Alternatives

[dms-mouse-battery](https://github.com/Ripolin99/dms-mouse-battery) also shows the mouse battery in DMS and adds DPI preset switching via Solaar or ratbagctl.

## Contributing

Set up the dev environment per the official [plugin development guide](https://danklinux.com/docs/dankmaterialshell/plugin-development#development-environment),
with one change: this is a standalone repo, so don't create a directory under `dms-plugins/`.

Instead, clone the repo into a directory of your choice, then run `just init`.

Required tools:

- [just](https://github.com/casey/just) runs the development tasks.
- [uv](https://docs.astral.sh/uv/) manages the Python environment and installs all dev dependencies itself.
- `dbus-daemon` hosts the private bus the tests fake UPower on.
- `dms` drives the hot-reload recipes. It comes with Dank Material Shell.

The most important recipes (run `just` for the full list):

```sh
just init        # Set up the development environment
just fmt         # Run all formatting and lint hooks
just test        # Run the system tests
just reload      # Reload the plugin after making changes
just mock start  # Show the widget in a mock bar with a fake mouse
```

`just test` launches the real quickshell binary headless against an in-process fake UPower daemon
and asserts the derived state over IPC.

## License

[MIT](LICENSES/MIT.txt), following the [REUSE](https://reuse.software) specification. Per-file copyright lives in the SPDX headers.
