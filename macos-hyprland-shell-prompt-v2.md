# macOS-Inspired Quickshell Desktop Shell for Hyprland — Build Prompt (v2)

You are a senior Linux desktop-shell engineer specializing in Quickshell, QtQuick/QML, Wayland, and Hyprland.

Build a complete macOS-inspired desktop shell for Linux using Quickshell and QML. The target compositor is Hyprland.

## Reference repository

Use this repository as an architectural and implementation reference:

`https://github.com/end-4/dots-hyprland/`

Study its modular Quickshell organization, Hyprland IPC integration, service abstractions, configuration handling, reactive QML patterns, and separation between common components and feature modules. Do not copy its visual design. Do not copy code unless its license allows it, and preserve required license notices. The final design must be visually original and strongly inspired by the classic, non-glassy macOS desktop experience.

## Quickshell version policy (critical)

Quickshell is pre-1.0 (current stable packaging is in the 0.2–0.3 range as of late 2026) and its QML API can and does break between releases. Before writing any code:

- Identify and pin the exact Quickshell version/tag you are targeting.
- Document the minimum required Qt6 version (Quickshell requires at least Qt 6.6; private headers for `qt6declarative` and, on Qt < 6.10, `qt6wayland` are needed at build time).
- Isolate every API you are not 100% certain of behind a small adapter component, clearly marked `// VERIFY:`.
- Never invent Quickshell APIs. If unsure whether something exists, say so and propose the adapter instead of guessing.

## Project goals

- Create a cohesive macOS-inspired Linux desktop shell.
- Use Quickshell with Qt 6 and QML.
- Target Hyprland on Wayland.
- Prefer stable, opaque, lightweight UI over glassmorphism.
- Do not use excessive blur, translucency, gradients, neon colors, oversized rounded cards, or Material Design styling.
- Use original icons and assets. Do not bundle Apple logos, proprietary Apple assets, or copyrighted system artwork. Decide up front whether icons are a bespoke SVG set or a restyled open icon font (e.g. Tabler Icons, Phosphor, Material Symbols) normalized to one stroke weight and size grid — this is its own sub-scope, plan for it explicitly.
- Make the interface functional, modular, configurable, keyboard-accessible, and responsive.
- Support multiple monitors and different scale factors.
- Make sensible Linux fallbacks when a service is unavailable.

## Visual direction

- Classic macOS-like desktop composition.
- Thin opaque top menu bar.
- Light neutral surfaces, subtle borders, restrained shadows, small corner radii.
- System font fallback chain using available Linux fonts (SF-compatible or system UI fonts), without bundling proprietary fonts.
- Familiar macOS-style spacing, hierarchy, alignment, menus, sidebars, toggles, sliders, dialogs, sheets, context menus.
- Avoid the modern glass-heavy appearance.
- Light and dark themes, with accent color support.
- Coherent icon stroke and size system.
- Smooth but restrained, disableable animations.

## Required components

### 1. Top menu bar

- Left: system/application menu, active application title, application menus (File/Edit/View/Window/Help) **where possible**. Note: most Linux applications expose no native global-menu protocol, so this is best-effort per app-id/window-title heuristics, not a guaranteed feature — document it as such rather than promising full parity.
- Center: optional clock and date.
- Right: Wi-Fi/network, volume, battery/charging, Bluetooth, input layout, notification indicator, Control Center button, user/session menu.
- Reserve bar space from maximized windows via Hyprland config or the appropriate Wayland layer-shell exclusive zone.
- Every module individually configurable/disableable.

### 2. Dock

- Bottom-centered, configurable size/magnification/visibility/monitor placement.
- Pinned apps, running apps, separators, trash shortcut, running indicators.
- Launch via `.desktop` files; discover apps via standard XDG data dirs, not a hardcoded list.
- Context menus: new window, close, quit, pin/unpin, open file location.
- Autohide, intelligent hiding, no interference with fullscreen apps.

### 3. Application launcher

- Search `.desktop` entries with fuzzy matching, categories, recents, full keyboard navigation, configurable shortcut.
- Optional providers: calculator, command execution, web search, **clipboard history (cliphist)**.
- Fast and fully usable without a mouse.

### 4. Control Center

Compact panel from the top-right menu bar, backed by explicit service wrappers:

- Network: NetworkManager (DBus).
- Bluetooth: BlueZ (DBus).
- Volume/mic: PipeWire/WirePlumber (native Quickshell PipeWire integration where available, else `wpctl`).
- Brightness: `brightnessctl` or sysfs backlight.
- Dark/light mode toggle.
- Do Not Disturb (own state; gates the notification service in section 6).
- Battery info: UPower (native Quickshell integration).
- VPN status: NetworkManager DBus.
- Media controls: see section 10.
- Never execute unsanitized user input directly in a shell command.

### 5. Settings application

Sidebar + searchable sections: Appearance, Wallpaper, Dock, Menu bar, Notifications, Sound, Displays, Keyboard, Mouse and touchpad, Trackpad gestures, Workspaces, Window behavior, Hyprland keybindings, Startup applications, Power and battery, Network, Bluetooth, Privacy-related local settings, Accessibility, About.

Backed by a structured JSON or TOML config file. Shell updates reactively on change where possible. Writes are validated, written to a temp file, then atomically replaced.

### 6. Notification center

**Pick one path and document the choice — the two are mutually exclusive, do not run both:**

- (a) Quickshell registers its own `org.freedesktop.Notifications` DBus service and owns notifications end-to-end, or
- (b) delegate to an external daemon (`mako` or `swaync`) and have Quickshell render only its history/UI on top.

Show grouped notifications, timestamps, app icons, actions, dismissal, Do Not Disturb, and history either way.

### 7. Workspace and window overview

- macOS-Mission-Control-style overview: open windows with thumbnails/previews where the compositor supports it (Hyprland toplevel export / screencopy), graceful icon+title fallback where it doesn't.
- Workspaces with drag-and-drop or keyboard-based window movement.
- Driven by Hyprland IPC. Open/close shortcuts.

### 8. Desktop and wallpaper layer

**Pick one path and document the choice:**

- (a) Quickshell renders wallpaper natively (QML `Image`/`ShaderEffect`) for full control over transitions, or
- (b) shell out to `hyprpaper`/`swaybg` for static images and `mpvpaper` for video wallpapers.

Support per-monitor wallpapers, cycling, and transitions either way. Keep this layer separate from shell UI. No forced blur or color extraction; wallpaper-based accent color is optional and disableable.

### 9. Session controls

- Lock, logout, suspend, reboot, shutdown, switch-user, all with confirmation for destructive actions.
- Lock surface: Hyprlock (or Quickshell's own PAM-based lock surface if you choose to build one — document which).
- Idle policy (screen-off / auto-lock / auto-suspend triggers): **hypridle**, paired with the lock surface above.
- Privilege-escalation dialogs: **hyprpolkitagent** (Qt/QML-native — avoids pulling a second toolkit's runtime just for auth dialogs).
- Never implement password handling inside QML; delegate to PAM/hyprlock/hyprpolkitagent.

### 10. Media controls

MPRIS is a DBus **interface** implemented by player applications — it is not a daemon you run. Build a client-side aggregator service that watches DBus for `org.mpris.MediaPlayer2.*` names appearing and disappearing (optionally via `playerctld` as an aggregation helper). Show current player, album art when available, playback state, prev/next, play/pause, volume.

### 11. Hardware and system integration

Centralized, audited service wrappers for:

- Hyprland IPC (native Quickshell integration)
- DBus (native)
- NetworkManager (DBus)
- BlueZ (DBus)
- PipeWire/WirePlumber (native where available, else `wpctl`)
- UPower (native Quickshell integration)
- MPRIS client aggregation (DBus name-watching / `playerctld`)
- Brightness control (`brightnessctl` / sysfs)
- Notification service (native or delegated — see section 6)
- Desktop application discovery (`.desktop` parsing, XDG data dirs)
- Wallpaper management (native QML or `hyprpaper`/`swaybg`/`mpvpaper` — see section 8)
- System session actions (`loginctl` / systemd-logind DBus)
- Screen capture: `grim`+`slurp` (or `hyprshot`) for screenshots, `wf-recorder` or `gpu-screen-recorder` for recording — both invoked through the portal below, never bypassing it
- Portal backend: `xdg-desktop-portal-hyprland`, with `xdg-desktop-portal-gtk` as file-chooser fallback
- Idle policy: `hypridle`
- Polkit agent: `hyprpolkitagent`

If a service is missing, show a useful disabled state instead of crashing.

## Architecture requirements

- Modules: `shell/`, `modules/`, `services/`, `components/`, `panels/`, `widgets/`, `settings/`, `themes/`, `assets/`, `scripts/`, `tests/`.
- Reusable components; no duplicated QML.
- Visual components stay separate from system-service logic.
- All external commands live in audited service wrappers.
- Prefer async; never block the QML UI thread.
- Avoid polling when DBus signals, Hyprland events, or file watchers can be used instead.
- One theme/metrics system: colors, typography, spacing, radii, shadows, animation durations, icon sizes.
- Every major feature independently disableable.
- No hardcoded screen dimensions; support multi-monitor and dynamic monitor changes.
- Handle Quickshell API version differences explicitly; pin and document the tested version (see policy above).

## Hyprland integration

- Use Hyprland IPC or Quickshell's supported Hyprland integration.
- Provide example Hyprland config snippets for: reserved top-bar/dock space, keybindings, overview, launcher, control center, settings, notifications, lock screen, and `exec-once` entries for `hypridle` and `hyprpolkitagent`.
- Never overwrite the user's existing Hyprland config automatically — provide snippets or a clearly documented manual integration method.

## Deliverables

1. Complete repository structure.
2. Working minimal vertical slice first: top bar, dock, launcher, one system status module, Hyprland workspace integration.
3. Remaining components implemented incrementally after that.
4. Complete QML source files, not pseudocode.
5. Install instructions for Arch Linux first, then Fedora and other distros.
6. Full runtime dependency list.
7. Transparent, non-destructive first-run setup script.
8. Back up configuration files before modifying them.
9. Clean uninstall procedure.
10. Configuration examples.
11. Troubleshooting instructions and logging.
12. README with screenshot placeholders and a feature-status table.
13. Basic tests/validation scripts for config parsing and service availability.

## Development process

- Before writing large amounts of code, inspect the reference repository's current structure and identify the Quickshell APIs it uses.
- Explain the proposed architecture and dependency choices first.
- Generate the project in small, testable stages. Each stage includes: files created/modified, complete code, commands to run, expected behavior, common failure modes.
- Never silently replace existing user configuration.
- Never invent Quickshell APIs; isolate uncertain ones behind a marked adapter.
- The project must be launchable with `quickshell -p path/to/project`.
- Fail gracefully; log actionable errors.
- Prioritize correctness, maintainability, and working Linux integration over visual polish.
