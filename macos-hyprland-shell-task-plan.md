# macOS-Inspired Quickshell Shell — Task-Based Implementation Plan

Companion to `macos-hyprland-shell-prompt-v2.md`. Same scope, restructured as sequential phases with exit criteria, so it can be executed (or handed to an agent) one phase at a time instead of as one monolithic build.

Rule for every phase: nothing in a later phase starts until the current phase's exit criteria are met and committed.

---

## Phase 0 — Environment & Reference Audit

**Goal:** ground the build in real, current facts before any architecture decisions.

- [x] Clone/inspect `end-4/dots-hyprland` current tree; note its module layout and which Quickshell APIs it actually calls.
- [x] Identify the exact Quickshell version/tag to target; confirm installed Qt6 version meets the minimum.
- [x] Audit the target machine: Hyprland version, existing `hyprland.conf`, existing lock/idle/portal setup. Do not touch any of it yet.
- [x] Create repo skeleton: `shell/ modules/ services/ components/ panels/ widgets/ settings/ themes/ assets/ scripts/ tests/`.
- [x] Define the theme/metrics token file: colors (light/dark/accent), typography, spacing scale, corner radii, shadow tokens, animation durations, icon size grid.

**Exit criteria:** empty-but-structured repo, pinned Quickshell version documented in README, theme tokens file exists and is referenced nowhere yet (no consumers).

---

## Phase 1 — Vertical Slice

**Goal:** one thing that actually runs, per the prompt's own deliverable #2.

- [x] Top bar: left app menu/title placeholder, center clock, right = one status module only.
- [x] Dock: pinned + running apps, click to launch/focus, no magnification yet.
- [x] Launcher: `.desktop` search, basic substring match, keyboard nav, no extra providers yet.
- [x] One system status module end-to-end (network).
- [x] Hyprland workspace IPC: bar reflects active workspace live.

**Exit criteria:** `quickshell -p path/to/project` launches; bar reserves its space against a maximized window; dock opens an app; launcher searches and opens an app; switching workspaces in Hyprland updates the bar without restarting Quickshell.

---

## Phase 2 — Core Services Layer

**Goal:** every backend integration exists as an isolated, testable wrapper before any more UI is built on top of it.

- [ ] Hyprland IPC wrapper
- [ ] DBus session wrapper (shared connection, reused by everything below)
- [ ] NetworkManager wrapper
- [ ] BlueZ wrapper
- [ ] PipeWire/WirePlumber wrapper (native Quickshell integration first, `wpctl` fallback)
- [ ] UPower wrapper
- [ ] MPRIS client aggregator (DBus name-watching, optional `playerctld`)
- [ ] Brightness wrapper (`brightnessctl`/sysfs)
- [ ] Desktop-entry discovery wrapper (XDG data dirs)
- [ ] Session-actions wrapper (`loginctl`)
- [ ] Wallpaper manager — decide native-QML vs. `hyprpaper`/`swaybg`/`mpvpaper` here, document the decision
- [ ] Notification service — decide native DBus server vs. delegate to `mako`/`swaync` here, document the decision

Each wrapper: async, event/signal-driven (no polling where a signal or watcher exists), returns an explicit "unavailable" state instead of throwing when the backend service is missing.

**Exit criteria:** each service has a minimal test harness (script or QML test page) proving connect → receive live update → disconnect cleanly; disabled-state fallback verified by stopping the backing service.

---

## Phase 3 — Menu Bar Completion

- [ ] Remaining right-side modules: Wi-Fi, volume, battery, Bluetooth, input layout, notification indicator, Control Center button, user/session menu.
- [ ] Application menu emulation (File/Edit/View/Window/Help) via app-id/window-title heuristics, explicitly marked best-effort/optional per app.
- [ ] Each module independently disableable via settings.

**Exit criteria:** every right-side module reflects live state from its Phase 2 wrapper; disabling any one module in config removes it cleanly with no layout gaps.

---

## Phase 4 — Dock Completion

- [ ] Magnification, autohide, intelligent hiding.
- [ ] Context menus: new window, close, quit, pin/unpin, open file location.
- [ ] Trash shortcut.
- [ ] Fullscreen-aware hiding (dock never covers a fullscreen app).

**Exit criteria:** dock behaves correctly with a fullscreen app open; context-menu actions work against real running apps.

---

## Phase 5 — Control Center

- [ ] Compact panel triggered from bar button.
- [ ] Wire in: network, Bluetooth, volume/mic, brightness, dark/light toggle, DND, battery, VPN status, media controls, quick settings — all from Phase 2 wrappers, no new backend logic here.

**Exit criteria:** every toggle/slider in the panel produces a real system-level change (verified against `wpctl`/`nmcli`/`brightnessctl` state, not just UI state).

---

## Phase 6 — Notification Center

- [ ] Implement whichever path was decided in Phase 2 (native DBus server or delegate to mako/swaync).
- [ ] Grouped notifications, timestamps, app icons, actions, dismissal.
- [ ] DND gating from Control Center state.
- [ ] Notification history.

**Exit criteria:** no duplicate notifications appear (verify the alternate path is fully disabled); DND actually suppresses display while still logging to history.

---

## Phase 7 — Workspace & Window Overview

- [ ] Overview trigger (shortcut + UI entry point).
- [ ] Window thumbnails where the compositor supports live preview (Hyprland toplevel export/screencopy); icon+title fallback where it doesn't.
- [ ] Drag-and-drop and keyboard-based window/workspace movement.

**Exit criteria:** overview opens/closes on shortcut; moving a window between workspaces in the overview reflects immediately in Hyprland.

---

## Phase 8 — Desktop & Wallpaper Layer

- [ ] Implement the path chosen in Phase 2 (native QML vs. external wallpaper daemon).
- [ ] Per-monitor wallpaper assignment.
- [ ] Cycling and transitions.
- [ ] Optional, disableable wallpaper-based accent color.

**Exit criteria:** two different monitors can show two different wallpapers; cycling works unattended; feature is fully off when disabled in settings.

---

## Phase 9 — Settings Application

- [ ] Sidebar + all searchable sections from the prompt.
- [ ] Config file (JSON or TOML) with schema validation.
- [ ] Safe write strategy: validate → write temp file → atomic rename.
- [ ] Reactive propagation to the running shell where feasible.

**Exit criteria:** every setting changed in the UI is reflected in the config file and, where applicable, live in the shell without a restart; a malformed manual edit to the config file fails validation without crashing the shell.

---

## Phase 10 — Session Controls & Lock

- [ ] Lock/logout/suspend/reboot/shutdown/switch-user actions with confirmation dialogs on destructive ones.
- [ ] Hyprlock (or documented native lock surface) integration.
- [ ] `hypridle` wiring for idle-triggered lock/DPMS/suspend.
- [ ] `hyprpolkitagent` wiring for privileged actions; confirm no password handling exists inside QML anywhere in the codebase.

**Exit criteria:** idle timeout actually locks the session; a privileged action (e.g. NetworkManager system connection edit) correctly triggers the polkit dialog instead of failing silently.

---

## Phase 11 — Media Controls

- [ ] Bar widget + Control Center panel using the Phase 2 MPRIS aggregator.
- [ ] Album art with graceful fallback when absent.
- [ ] Correct behavior when a player appears/disappears mid-session (e.g. closing a browser tab that was playing audio).

**Exit criteria:** switching between two simultaneously-open MPRIS players (e.g. browser + Spotify) works without stale state.

---

## Phase 12 — Packaging & Documentation

- [ ] Install script for Arch Linux; notes for Fedora and other distros.
- [ ] Full runtime dependency list.
- [ ] Non-destructive first-run setup script; backs up existing configs before touching them.
- [ ] Clean uninstall procedure.
- [ ] Configuration examples.
- [ ] Troubleshooting guide + logging documentation.
- [ ] README with feature-status table and screenshot placeholders.
- [ ] Validation scripts/tests for config parsing and service availability.

**Exit criteria:** a clean Arch VM with only base Hyprland installed can run the setup script end to end and land on a working shell; uninstall script leaves no orphaned files or modified system config behind.

---

## Cross-phase decisions to lock early (don't defer these)

1. Notification ownership: native DBus server vs. mako/swaync (affects Phase 2 and 6).
2. Wallpaper rendering: native QML vs. external daemon (affects Phase 2 and 8).
3. Icon system: bespoke SVG set vs. restyled open icon font (affects every visual phase — resolve before Phase 3).
4. Lock surface: Hyprlock vs. Quickshell-native PAM lock (affects Phase 10).

Each of these is a fork in the architecture, not a detail — deciding late means rework across multiple already-completed phases.
