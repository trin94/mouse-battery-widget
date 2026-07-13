# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

export PYTHONPATH := source_directory() / '..'

DMS_ROOT := if path_exists(config_directory() / 'quickshell' / 'dms' / 'shell.qml') == 'true' { config_directory() / 'quickshell' / 'dms' } else { '/usr/share/quickshell/dms' }
LOG := env('XDG_RUNTIME_DIR', '/tmp') / 'mouse-battery-mock.log'
CONTROL := 'io.github.trin94.MouseBatteryWidget.Mock'
SERVE := source_directory() / 'serve.py'

[private]
@default:
    just --unsorted --list mock

# Start a mock bar containing only the widget
start: _links
    #!/usr/bin/env sh
    if pgrep -f 'src/mock/serve[.]py' >/dev/null; then
        echo 'mock bar already running'
        exit 0
    fi
    setsid --fork sh -c 'exec uv run "{{ SERVE }}" >"{{ LOG }}" 2>&1'
    echo 'mock bar started, log: {{ LOG }}'

# Set the mock battery percentage on the running bar
@percentage value:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetPercentage d {{ value }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Set the mock charge state on the running bar (charging, discharging, full)
@state value:
    busctl --user call {{ CONTROL }} / {{ CONTROL }} SetState s {{ value }} || { echo 'hint: start the mock bar with `just mock start`'; exit 1; }

# Stop the mock bar
stop:
    #!/usr/bin/env sh
    pkill -f 'src/mock/serve[.]py' || { echo 'mock bar is not running'; exit 0; }
    echo 'mock bar stopped'

[private]
_links:
    for entry in '{{ DMS_ROOT }}'/*/; do ln -sfn "${entry%/}" preview/; done
    ln -sfn ../../qml preview/MouseBattery
