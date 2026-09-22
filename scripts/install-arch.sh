#!/usr/bin/env bash

set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install_deps=0
for arg in "$@"; do
    case "$arg" in
        --install-deps) install_deps=1 ;;
        --help)
            printf 'Usage: install-arch.sh [--install-deps]\n'
            printf 'Install user files; optionally install Arch runtime packages with pacman.\n'
            exit 0
            ;;
        *) printf 'error: unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

if [[ ! -r /etc/arch-release ]]; then
    printf 'error: this helper is for Arch Linux; use docs/dependencies.md for other distros.\n' >&2
    exit 1
fi

if ((install_deps)); then
    command -v sudo >/dev/null 2>&1 || { printf 'error: --install-deps requires sudo\n' >&2; exit 1; }
    sudo pacman -S --needed quickshell qt6-declarative hyprland networkmanager pipewire wireplumber \
        bluez bluez-utils upower playerctl brightnessctl
else
    printf '%s\n' 'Skipping package installation (pass --install-deps to use pacman).'
fi

exec "$root_dir/scripts/setup.sh" --source "$root_dir"
