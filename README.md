# macOS-Inspired Quickshell Shell

This project is a macOS-inspired desktop shell for Hyprland, implemented with
Quickshell, Qt 6, and QML. Phase 1 vertical slice is implemented with a top
bar, dock, application launcher, network status, and live Hyprland workspace
state.

## Phase 0 target

- Quickshell: `0.2.1`
- Local package revision: `7511545ee20664e3b8b8d3322c0ffe7567c56f7a`
- Minimum Qt 6: `6.6`
- Audited Qt 6: `6.11.2`
- Compositor target: Hyprland `0.56.2`
- Reference repository revision: `end-4/dots-hyprland@2f0c8bf`

Quickshell is pre-1.0 and its QML API is version-sensitive. API usage will be
kept behind small adapters when compatibility is uncertain; such locations
will be marked `VERIFY` before implementation.

See [docs/phase-0-environment-audit.md](docs/phase-0-environment-audit.md) for
the evidence collected on the development machine and the reference tree.

## Development entrypoint

The shell will be launchable with:

```sh
quickshell -p .
```

The runnable entrypoint is `shell.qml`; launch it from the repository root with
`quickshell -p .`.

## Hyprland autostart

The repository includes `scripts/start-quickshell.sh`, which resolves this
checkout and starts it with Quickshell. To start the shell when Hyprland logs
in, add this to the `hyprland.start` section of your Lua configuration:

```lua
hl.on("hyprland.start", function()
	hl.exec_cmd("/home/macOS-qs/dev/macOS-qs/scripts/start-quickshell.sh")
end)
```

Replace the path if this repository lives elsewhere. The launcher is safe to
call from Hyprland because it uses an absolute project path and replaces its
own process with Quickshell.

## Feature status

| Area | Status |
| --- | --- |
| Top bar, dock, launcher, network status, workspaces | ✅ Phase 1 |
| Async system/compositor service adapters | ✅ Phase 2 |
| Menu bar modules and session actions | ✅ Phase 3 |
| Persistent settings application/config consumption | ✅ Phase 9 (module visibility and dock pins) |
| Dock polish, Control Center, notification actions, overview | Partial (Phases 4–7) |
| Media controls and session confirmations | Partial (Phases 10–11) |
| Packaging and documentation | ✅ Phase 12 |

## Screenshots

Screenshots will be added as the visual phases settle. These placeholders
reserve the documentation locations without bundling generated or
machine-specific images:

<!-- screenshot: top bar and dock (assets/screenshot-top-bar.png) -->
<!-- screenshot: launcher and workspace overview (assets/screenshot-launcher.png) -->

Phase 1 implementation notes:

- `shell.qml` owns the bar, dock, launcher, and visual composition.
- `services/Workspace.qml` reads active workspace and clients from `hyprctl`and dispatches workspace changes.
- `services/NetworkStatus.qml` reads the active connection from `nmcli`.
- Desktop entries come from Quickshell's `DesktopEntries` model and launch via `DesktopEntry.execute()`.

## Phase 2 service layer

Phase 2 wrappers live in `services/`. They use asynchronous Quickshell
`Process` adapters and expose `available`/`error` state when an optional
backend is missing. `SessionBus.qml` is the shared session-bus boundary for
DBus calls; wrappers do not create private bus connections.

The locked architectural decisions are:

- Wallpaper: native QML wallpaper surfaces. No wallpaper daemon is owned by
	this project; `Wallpaper.qml` provides the state boundary for the later
	layer-shell implementation.
- Notifications: delegate to an existing `swaync` or `mako` installation.
	`Notifications.qml` detects the available owner, and the shell will not
	start a second notification server.

## Phase 3 menu bar

The menu bar includes Wi-Fi, volume, battery, Bluetooth, input layout,
notification ownership, Control Center, and session actions. The right-side
composition is in `modules/MenuBarRight.qml`; each module can be disabled
independently through `settings/MenuBarSettings.qml`. Phase 9 will connect
those properties to validated persistent configuration.

The visual layer uses Qt's generic `Sans` fallback rather than requiring a
proprietary macOS font or a bundled font file. On systems where the fallback
looks incomplete, install a Linux UI font such as `Noto Sans` or `Inter`; the
shell does not download fonts or modify the user's font configuration.

The Control Center volume buttons call `wpctl` through the `Audio` service.
Unavailable backends remain disabled instead of blocking the shell.

The File/Edit/View/Window/Help row is best-effort application-menu emulation.
It uses the active Hyprland window title/class as context and does not claim
native global-menu support from applications that do not expose it.

Run the Phase 2 smoke harness with:

```sh
tests/service-smoke-test.sh
```

## Configuration, setup, and removal

`config/config.example.json` documents the settings schema. The running shell
loads `~/.config/macos-qs/config.json` with safe defaults, validates types, and
writes changes atomically. Menu-bar visibility and dock pinned IDs are
currently persisted. Validate an example (or another JSON file with the same
schema) with:

```sh
tests/config-validation.sh config/config.example.json
```

The validator checks syntax and types without changing files.

Arch users can install and set up the current checkout with
`scripts/install-arch.sh` (add `--install-deps` to let it invoke `pacman`).
`scripts/setup.sh --enable-autostart` is opt-in and backs up an existing
Hyprland config before adding its managed `exec-once` line. Remove the user
install with `scripts/uninstall.sh`; it removes only managed files and keeps
timestamped backups. See [docs/dependencies.md](docs/dependencies.md) and
[docs/troubleshooting.md](docs/troubleshooting.md) for dependency,
diagnostic, and logging details.

## Repository layout

The top-level directories are intentionally structured before feature code is
introduced. The token file in `themes/tokens.json` is not consumed yet.

```text
assets/       Static assets and icon resources
components/   Reusable visual components
modules/      Feature modules
panels/       Layer-shell panels and popups
scripts/      Audited helper scripts
services/     System and compositor adapters
settings/     Settings UI and configuration schema
shell/        Quickshell entrypoints
tests/        Validation and test harnesses
themes/       Theme and metrics tokens
widgets/      Small reusable widgets
```
