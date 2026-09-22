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

Phase 1 implementation notes:

- `shell.qml` owns the bar, dock, launcher, and visual composition.
- `services/Workspace.qml` reads active workspace and clients from `hyprctl`and dispatches workspace changes.
- `services/NetworkStatus.qml` reads the active connection from `nmcli`.
- Desktop entries come from Quickshell's `DesktopEntries` model and launch via `DesktopEntry.execute()`.

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
