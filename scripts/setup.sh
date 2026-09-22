#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: setup.sh [options]

Install the shell for the current user without changing system files.

Options:
  --source DIR          Checkout to install (default: repository containing this script)
  --install-dir DIR     Install location (default: ~/.local/share/macos-qs)
  --enable-autostart    Add a managed exec-once entry to ~/.config/hypr/hyprland.conf
  --help                Show this help
EOF
}

source_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/macos-qs"
enable_autostart=0

while (($#)); do
    case "$1" in
        --source) source_dir="$2"; shift 2 ;;
        --install-dir) install_dir="$2"; shift 2 ;;
        --enable-autostart) enable_autostart=1; shift ;;
        --help) usage; exit 0 ;;
        *) printf 'error: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

source_dir="$(CDPATH= cd -- "$source_dir" && pwd)"
if [[ ! -f "$source_dir/shell.qml" || ! -x "$source_dir/scripts/start-quickshell.sh" ]]; then
    printf 'error: %s is not a macOS-qs checkout\n' "$source_dir" >&2
    exit 1
fi
resolved_install_dir="$(realpath -m -- "$install_dir")"
case "$resolved_install_dir/" in
    "$source_dir/"*)
        printf 'error: install directory must not be inside the source checkout\n' >&2
        exit 1
        ;;
esac

backup_path() {
    local path="$1"
    local backup="${path}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -a -- "$path" "$backup"
    printf 'backup: %s -> %s\n' "$path" "$backup"
}

mkdir -p -- "$(dirname -- "$install_dir")"
if [[ -e "$install_dir" || -L "$install_dir" ]]; then
    backup_path "$install_dir"
fi
mkdir -p -- "$install_dir"
cp -a -- "$source_dir/." "$install_dir/"

bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"
mkdir -p -- "$bin_dir"
launcher="$bin_dir/macos-qs"
if [[ -e "$launcher" || -L "$launcher" ]]; then
    backup_path "$launcher"
fi
ln -sfn -- "$(realpath -- "$install_dir/scripts/start-quickshell.sh")" "$launcher"
printf 'installed: %s\n' "$install_dir"
printf 'launcher:  %s\n' "$launcher"

if ((enable_autostart)); then
    hypr_conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
    mkdir -p -- "$(dirname -- "$hypr_conf")"
    if [[ -e "$hypr_conf" ]]; then
        backup_path "$hypr_conf"
    else
        : > "$hypr_conf"
    fi
    if ! grep -Fqx 'exec-once = macos-qs # macOS-qs managed' "$hypr_conf"; then
        printf '\n# macOS-qs managed autostart\nexec-once = macos-qs # macOS-qs managed\n' >> "$hypr_conf"
    fi
    printf 'autostart: %s\n' "$hypr_conf"
fi

printf '%s\n' 'Setup complete. Start now with: macos-qs'
