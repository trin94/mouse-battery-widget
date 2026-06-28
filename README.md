<!--
SPDX-FileCopyrightText: Elias Mueller

SPDX-License-Identifier: MIT
-->

# Mouse Battery Widget

A [Dank Material Shell](https://github.com/AvengeMedia/DankMaterialShell) plugin
that shows your wireless mouse battery level in the bar.

- Battery percentage in a bar pill (a dash when no mouse is connected).
- Bolt icon while charging.
- Click for a popout with the mouse name and charge state.
- Reads `Quickshell.Services.UPower` directly; no polling or shelling out.

## Requirements

- Dank Material Shell (the plugin imports its `qs.*` modules at runtime).

- A mouse whose battery UPower reports. To check:

  ```sh
  for d in $(upower -e); do upower -i "$d" | grep -q 'mouse' && echo "$d"; done
  ```

## Installation

Clone the repo and symlink it into the DMS plugins directory, then add the
widget to the bar from
[the plugin settings](https://danklinux.com/docs/dankmaterialshell/plugin-development#5-load-it):

```sh
git clone https://github.com/trin94/mouse-battery-widget.git
cd mouse-battery-widget
mkdir -p ~/.config/DankMaterialShell/plugins
ln -s "$PWD" ~/.config/DankMaterialShell/plugins/mouse-battery-widget
```

## Contributing

Set up the dev environment per the official
[plugin development guide](https://danklinux.com/docs/dankmaterialshell/plugin-development#development-environment),
with one change: this is a standalone repo, so don't create a directory under
`dms-plugins/`. Instead, symlink DMS's qmlls config into the repo (git-ignored)
and open your editor here:

```sh
ln -s /path/to/DankMaterialShell/quickshell/.qmlls.ini .qmlls.ini
```

Tooling: [just](https://github.com/casey/just) for the task runner and
[prek](https://prek.j178.dev) for the formatting and pre-commit hooks.

Hot-reload and formatting are driven by the [`Justfile`](Justfile); run `just`
for a list of actions (and `just fmt` before committing).

## License

[MIT](LICENSES/MIT.txt), following the [REUSE](https://reuse.software)
specification; per-file copyright lives in the SPDX headers.
