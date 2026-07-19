# Preflight notes — omarchy shell fork (2026-07-19)

## Go/no-go: **GO**

- Quickshell: **0.3.0** (AUR `quickshell-git`, rev 4df562d).
- Smoke test (`quickshell -n -p ~/omarchy/shell`, 5s) rendered successfully (exit 124 = timed out while running).
- **No missing QML modules/services.** `Quickshell.Services.Polkit` loads (only warns "an authentication agent already exists" — the current session's agent; proves the service is present). WlSessionLock/DesktopEntries produced no module errors.

### Benign warnings observed (not blockers)
- `Indicators.qml:211/343` — "Binding loop detected for property implicitWidth". Cosmetic upstream QML warning.
- `IpcHandler ... another handler registered for target omarchy.indicators/system-update` — duplicate-handler warning; non-fatal.
- Many `omarchy-* binary could not be found` — only because `$OMARCHY_PATH/bin` was not on PATH during the isolated test. Fixed by the uwsm env package (Task 3). Scripts referenced: omarchy-reminder, omarchy-toggle-nightlight, omarchy-toggle-idle, omarchy-monitor-state, omarchy-network-status, omarchy-update-available.

## Dependency inventory

| Package | Status |
|---|---|
| uwsm | **MISSING** (install in Task 7) |
| gpu-screen-recorder | **MISSING** (install in Task 7) |
| localsend | **MISSING** (install in Task 7 — AUR) |
| gum | **MISSING** (install in Task 7) |
| hyprsunset | present |
| hyprpicker | present |
| hyprlock | present |
| satty | present |
| grim | present |
| slurp | present |
| wl-clipboard (wl-copy) | present |
| mpvpaper | present |

### Task 7 install list (confirmed MISSING only)
`uwsm gpu-screen-recorder gum` (pacman) + `localsend` (AUR). Plus nerd/omarchy icon font check.
