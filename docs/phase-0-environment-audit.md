# Phase 0 Environment and Reference Audit

Audit date: 2026-09-22

## Pinned implementation target

The first implementation target is the locally installed Quickshell release:

| Component | Result |
| --- | --- |
| Quickshell | `0.2.1` |
| Quickshell revision | `7511545ee20664e3b8b8d3322c0ffe7567c56f7a` |
| Distribution | AUR package `quickshell-git` |
| Minimum Qt 6 | `6.6` per project requirement |
| Audited Qt 6 | `6.11.2` |
| Hyprland | `0.56.2`, tag `v0.56.2` |

Qt private headers required by Quickshell packaging must be available to a
build on systems that compile Quickshell. This project does not build
Quickshell itself, but retains the minimum Qt requirement in its installation
documentation.

## Reference repository

Repository: `https://github.com/end-4/dots-hyprland.git`

Audited revision: `2f0c8bf` (shallow clone in `/tmp/macos-qs-dots-hyprland-audit`).
The reference places its Quickshell project under
`dots/.config/quickshell/ii/` and separates:

- `modules/common/` for shared QML helpers and visual primitives;
- `services/` for system and compositor state;
- `modules/` for feature surfaces;
- `panelFamilies/` for selectable panel compositions;
- `settings.qml` and `shell.qml` for configuration and composition entrypoints.

The reference entrypoint uses `ShellRoot`, `LazyLoader`, `IpcHandler`, and
`GlobalShortcut`. Its Hyprland service listens to `Hyprland.rawEvent` and uses
`Process` plus `StdioCollector` for JSON queries such as clients, monitors,
layers, workspaces, and the active workspace.

Observed imports in the audited QML include:

- `Quickshell`, `Quickshell.Io`, `Quickshell.Hyprland`, and `Quickshell.Wayland`;
- `Quickshell.Services.Pipewire`, `UPower`, `Mpris`, `Notifications`,
  `Bluetooth`, `SystemTray`, and `Polkit`;
- `QtQuick`, `QtQuick.Window`, and `Qt.labs.folderlistmodel`.

These are observations from the pinned reference, not a promise that every
module or property is stable in Quickshell `0.2.1`. Each integration will be
validated locally before use.

## Target-machine audit

The audit was read-only and did not modify the user's configuration.

| Area | Result |
| --- | --- |
| Session | `XDG_CURRENT_DESKTOP=Hyprland`, Wayland session active |
| Hyprland config | Split Lua configuration under `~/.config/hypr/`; no root `hyprland.conf` |
| Hyprland startup | Existing `qs -c $qsConfig` startup command is present |
| Idle policy | `~/.config/hypr/hypridle.conf` exists; locks through `loginctl`/Hyprlock fallback and suspends through `loginctl` |
| Lock screen | `~/.config/hypr/hyprlock.conf` exists |
| Portal | `xdg-desktop-portal-hyprland` is selected, with GTK fallback and KDE file chooser |
| Installed | `quickshell`, `hyprctl`, `hyprland`, `hyprlock`, `hypridle`, `nmcli`, `wpctl`, `brightnessctl` |
| Missing or unavailable | `hyprpolkitagent` was not found; no running `mako`, `swaync`, or Quickshell process was observed |

The existing startup and idle configuration is intentionally left untouched.
Future integration must provide snippets and backups rather than overwrite it.

## Phase 0 boundary

Created in this phase:

- the project directory skeleton;
- the pinned-version and audit documentation;
- the initial theme/metrics token contract in `themes/tokens.json`.

The token file has no consumers yet. No QML, service wrapper, compositor
configuration, or user configuration has been added.
