# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

set lazy

PLUGIN_ID := 'mouseBatteryWidget'
LINK := config_directory() / 'DankMaterialShell' / 'plugins' / file_name(justfile_directory())

alias fmt := format

# List available recipes
default:
    @just --list --unsorted

[group('dev')]
format:
    prek run --all-files

[group('dev')]
update-hooks:
    prek auto-update

[group('dev')]
test *args:
    uv run src/test_mouse_battery.py {{ args }}

# List all plugins and their state
[group('dms')]
list:
    dms ipc call plugins list

# Check whether the plugin is running
[group('dms')]
status:
    dms ipc call plugins status {{ PLUGIN_ID }}

# Reload the plugin after making changes
[group('dms')]
reload:
    dms ipc call plugins reload {{ PLUGIN_ID }}

# Restart DMS with a fresh plugin symlink
[group('dms')]
restart:
    rm -f {{ LINK }}
    dms restart
    ln -s {{ justfile_directory() }} {{ LINK }}

[group('reuse')]
verify-reuse-compliance:
    reuse lint
