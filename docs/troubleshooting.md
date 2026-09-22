# Troubleshooting and logging

## Start in the foreground

Run `macos-qs` (or `./scripts/start-quickshell.sh`) from a terminal inside the
Hyprland session. This keeps Quickshell diagnostics visible and confirms that
the checkout and QML entrypoint can be found.

For a clean service report, run:

```sh
./tests/service-smoke-test.sh
```

The script treats missing optional commands as expected fallback states. A
missing `hyprctl` or `quickshell` is not a fallback: install the required
runtime and ensure the command is on `PATH`.

## Common problems

- **No bar appears:** verify `quickshell -p ~/.local/share/macos-qs` starts
  without errors and that the process is running inside Hyprland.
- **No network/audio/battery state:** install and start the corresponding
  backend (`NetworkManager`, PipeWire/WirePlumber, or UPower), then rerun the
  smoke test.
- **Autostart does not run:** inspect
  `~/.config/hypr/hyprland.conf` for `exec-once = macos-qs`; start a new
  Hyprland session after changing it.
- **A stale installation is being launched:** check `command -v macos-qs` and
  remove old copies from `PATH`, or invoke the absolute launcher path.

## Logging

Quickshell writes diagnostics to the terminal that launched it. Preserve that
output when reporting a problem:

```sh
macos-qs 2>&1 | tee "$HOME/macos-qs-quickshell.log"
```

Do not put logs in the repository or commit them: they may include window
titles and backend details. The project does not create a daemon, rotate logs,
or collect telemetry. The example configuration in
`config/config.example.json` documents the planned logging levels; it is
validated but is not yet consumed by the shell.

