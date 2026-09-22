# Dependencies

## Runtime

The supported baseline is Arch Linux with Hyprland, Quickshell 0.2.1 (or a
compatible newer release), and Qt 6.6 or newer. Install the following packages
as needed:

| Capability | Package/command | Required |
| --- | --- | --- |
| Shell runtime | `quickshell`, `qt6-declarative` | yes |
| Compositor state | `hyprland`, `hyprctl` | yes |
| Network | `networkmanager`, `nmcli` | yes |
| Audio | `pipewire`, `wireplumber`, `wpctl` | optional fallback |
| Power | `upower` | optional |
| Bluetooth | `bluez`, `bluez-utils`, `bluetoothctl` | optional |
| Media | `playerctl` | optional |
| Brightness | `brightnessctl` | optional |
| Session actions | `systemd`, `loginctl` | optional |
| Notifications | `mako` or `swaync` | optional |

Optional backends are detected at runtime and show an unavailable state rather
than preventing the shell from starting. `scripts/install-arch.sh --install-deps`
installs the Arch package set with `pacman`; review it before running.

Fedora users can install equivalent packages with `dnf` (for example
`quickshell qt6-qtdeclarative hyprland NetworkManager pipewire wireplumber
bluez bluez-tools upower playerctl brightnessctl`). Package names and
Quickshell availability vary by Fedora release. On other distributions, use
the distribution's Qt 6, Quickshell, Hyprland, and backend packages.

## Installation

From a checkout:

```sh
./scripts/install-arch.sh
./scripts/setup.sh --enable-autostart
```

The setup script installs only under `~/.local/share/macos-qs` and
`~/.local/bin`. It creates timestamped backups before replacing an existing
install, launcher, or Hyprland configuration. Autostart is opt-in.

