# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

PLUGIN_ID := 'mouseBatteryWidget'

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

[group('reuse')]
verify-reuse-compliance:
    reuse lint
