#!/usr/bin/env bash

set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        printf 'ok %-14s available\n' "$1"
    else
        printf 'ok %-14s unavailable (fallback state expected)\n' "$1"
    fi
}

for command_name in busctl hyprctl nmcli wpctl bluetoothctl upower playerctl brightnessctl loginctl; do
    check_command "$command_name"
done

service_count="$(find "$root_dir/services" -maxdepth 1 -name '*.qml' -type f | wc -l)"
if [[ "$service_count" -lt 12 ]]; then
    printf 'not ok service wrappers: expected at least 12, found %s\n' "$service_count"
    failures=$((failures + 1))
else
    printf 'ok service wrappers: %s QML adapters\n' "$service_count"
fi

if busctl --user --no-pager list >/dev/null 2>&1; then
    echo 'ok session bus: connect'
else
    echo 'ok session bus: unavailable (fallback state expected)'
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl activeworkspace -j >/dev/null 2>&1; then
    echo 'ok Hyprland IPC: receive active workspace'
else
    echo 'ok Hyprland IPC: unavailable (fallback state expected)'
fi

exit "$failures"