#!/usr/bin/env bash

set -euo pipefail

install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/macos-qs"
bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"
launcher="$bin_dir/macos-qs"
hypr_conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"

if [[ -e "$hypr_conf" ]]; then
    backup="${hypr_conf}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -a -- "$hypr_conf" "$backup"
    sed -i '/^# macOS-qs managed autostart$/d;/^exec-once = macos-qs # macOS-qs managed$/d' "$hypr_conf"
    printf 'updated: %s (backup: %s)\n' "$hypr_conf" "$backup"
fi

if [[ -L "$launcher" || -f "$launcher" ]]; then
    rm -f -- "$launcher"
    printf 'removed: %s\n' "$launcher"
fi
if [[ -d "$install_dir" ]]; then
    rm -rf -- "$install_dir"
    printf 'removed: %s\n' "$install_dir"
fi
printf '%s\n' 'Uninstall complete. Backups and user configuration files were retained.'
