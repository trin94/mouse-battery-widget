# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

set lazy

PLUGIN_ID := 'mouseBatteryWidget'
QMLTESTRUNNER := `command -v qmltestrunner-qt6 || command -v qmltestrunner || echo qmltestrunner`

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
test:
    {{ QMLTESTRUNNER }} -platform offscreen -input qml

[group('dev')]
test-ci:
    #!/usr/bin/env -S uv run --script
    # /// script
    # requires-python = ">=3.9"
    # dependencies = ["PySide6-Essentials==6.11.1"]
    # ///
    import sys
    from PySide6.QtQuickTest import QUICK_TEST_MAIN
    sys.exit(QUICK_TEST_MAIN("MouseBatteryWidget", [sys.argv[0], "-platform", "offscreen", "-input", "qml"]))

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
