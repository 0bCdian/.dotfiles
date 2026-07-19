# Spec 1 — Fork omarchy's Quickshell shell into the dotfiles

**Status:** Approved design (2026-07-19)
**Author:** Diego (0bCdian) + Claude
**Branch:** `feat/omarchy-shell-fork` (off `main`) → PR into `main`
**Follow-up:** Spec 2 — reproducible bootstrap installer (out of scope here)

---

## 1. Goal

Replace the end4 / illogical-impulse (`ii`) Quickshell shell with **omarchy 4.0's**
Quickshell shell, vendored as a **frozen, self-owned fork** inside the existing
**GNU stow**-managed `~/.dotfiles` repository.

Preserve, untouched:

- The live **Lua-based Hyprland** config and all existing keybinds/muscle memory.
- Terminal(s) (ghostty/kitty/foot), editor (nvim/LazyVim), tmux, fish, btop, yazi,
  starship, lazygit — all current dotfiles.

Change deliberately:

- Shell layer: `ii` → omarchy shell (bar, launcher, notifications, lock, idle,
  OSD, clipboard, emoji, polkit agent, command menu).
- Launcher: **retire vicinae**, use omarchy's native `omarchy.launcher`.
- Theming: curated **gruvbox-material** (omarchy theme system), decoupled from wallpaper.
- Session: adopt **uwsm** (with vanilla `hyprland` session kept as fallback).

Wallpaper stays on the user's own **waypaper-engine** (omarchy's background plugin
is disabled).

### Non-goals (this spec)

- The bootstrap/installer script (that is Spec 2).
- Omarchy's web-app system.
- Rewriting/renaming omarchy internals ("de-omarchy" surgery). This is a *frozen
  vendored fork*: omarchy naming, `OMARCHY_PATH`, and `omarchy-*` script names are
  kept intact. Future upstream features are ported **manually**, by choice.
- Touching terminal/editor/tmux/fish/btop configs.

---

## 2. Context / current state

| Concern | Current | Target |
|---|---|---|
| Shell/bar/widgets | end4 `ii` (`qs -c ii`) | omarchy shell (`quickshell -p $OMARCHY_PATH/shell`) |
| Launcher | vicinae (`Super+Space`) | `omarchy.launcher` |
| Notifications | swaync | `omarchy.notifications` |
| Idle | hypridle | `omarchy.idle` (timings in `shell.json`) |
| Lock | hyprlock | `omarchy.lock` (hyprlock kept as fallback) |
| OSD / clipboard / emoji | ii / copyq / fuzzel | omarchy plugins |
| Polkit agent | current | `omarchy.polkit` |
| Colors | matugen/wal (dynamic) | curated gruvbox-material |
| Wallpaper | waypaper-engine | **unchanged** (waypaper-engine) |
| Session | SDDM → bare `hyprland` + `exec-once` | SDDM → `hyprland-uwsm` (uwsm) |
| Config mgmt | GNU stow | **unchanged** (GNU stow) |

Source of the fork: the existing checkout at `~/omarchy` (version `4.0.0.alpha`).
`uwsm` is **not yet installed**; a `hyprland-uwsm.desktop` session already exists.

Repo notes:

- `~/.dotfiles` uses stow: each top-level dir is a package holding `.config/<app>/…`,
  stowed into `$HOME`.
- Branch `end4` holds current WIP (uncommitted); `main` is the older `.conf`-based
  state. This work branches off `main`.
- The live `~/.config/hypr` is the **lua** config and is **not** currently a matching
  stow package (the repo's `hypr` package is the stale `.conf` version). Part of this
  work is capturing the live lua config into the `hypr` stow package.

---

## 3. Architecture — stow packages

All new/changed packages live in `~/.dotfiles` on `feat/omarchy-shell-fork`.

### 3.1 `omarchy-shell/` (the vendored fork)

Deploys the frozen omarchy tree to `~/.local/share/omarchy-shell/`, which becomes
`OMARCHY_PATH`.

```
omarchy-shell/.local/share/omarchy-shell/
  version
  shell/                     # the Quickshell shell (QML plugin host)
  bin/                       # omarchy-* scripts (kept whole for interdependencies)
  config/omarchy/            # shipped shell.json default, etc.
  default/omarchy/           # omarchy-menu.jsonc, launcher.hides
  default/themed/            # theme templates incl. shell.toml.tpl
  default/fonts/             # omarchy.ttf icon glyph font
  default/hypr/              # omarchy's own hypr lua — REFERENCE ONLY (not loaded)
  themes/                    # shipped themes (incl. stock gruvbox)
```

**Vendor scope decision:** include the above; exclude clearly system-install /
other-distro dirs not needed by the shell: `default/{bash,pacman,limine,plymouth,
snapper,udev,libalpm,chromium,firefox,voxtype,nautilus-python,omarchy-skill,gpg}`
and terminal `screensaver` snippets. (System pieces that *are* wanted — sddm,
systemd, uwsm, small tweaks — are handled as their own packages / system steps
below, not inside this vendored tree.)

Rationale: keep the shell's runtime world intact ("frozen owned copy") so no menu
action or script breaks from a missing interdependency, while trimming OS-install
files irrelevant to the shell.

### 3.2 `omarchy-config/` (user shell config)

```
omarchy-config/.config/omarchy/
  shell.json                          # bar layout + enabled plugins + idle timings
  themes/gruvbox-material/            # custom theme (colors.toml + shell.toml)
  extensions/omarchy-menu.jsonc       # optional: prune web-app rows, add custom
```

`shell.json` encodes the feature scope (see §4).

### 3.3 `uwsm/` (session env)

```
uwsm/.config/uwsm/
  env.d/10-omarchy-shell.conf   # export OMARCHY_PATH; export PATH="$OMARCHY_PATH/bin:$PATH"
  default (optional)            # TERMINAL/BROWSER/EDITOR overrides (user's choices)
```

`env.d/*` is shell-sourced by uwsm, so `$PATH` expansion works and applies to the
compositor and every launched app. This is the clean solution to the
`OMARCHY_PATH` / `PATH` wiring that Hyprland's `env =` cannot do well.

### 3.4 `hypr/` (updated live lua config)

Capture the live `~/.config/hypr` lua config into the stow package, with these edits:

- **Autostart** (`hyprland/execs.lua`):
  - Replace `qs -c ii &` → launch omarchy shell via `uwsm app -- quickshell -n -p $OMARCHY_PATH/shell` (mirrors omarchy autostart).
  - **Comment out** (do not delete): `ii`, `hypridle`, `vicinae server`, and swaync launch.
  - **Keep**: `waypaper-engine daemon`, geoclue, gnome-keyring.
  - Wrap remaining autostart apps in `uwsm app --` where appropriate.
- **Env** is moved to `uwsm/env.d` (§3.3); remove/relocate any `OMARCHY_PATH` from hypr `env =`.
- **Keybinds** (`custom/keybinds.lua`) — repoint/add (everything else unchanged):

| Key | Was | Becomes |
|---|---|---|
| Super+Space | `vicinae toggle` | `omarchy-shell shell toggle omarchy.launcher` |
| Super+Escape (default; confirm in plan) | — | `omarchy-menu` (toggle root command palette) |
| Super+V | — | `omarchy-shell shell toggle omarchy.clipboard` |
| Super+Period | — | `omarchy-shell shell toggle omarchy.emojis` |
| Print / Shift+Print | — | `omarchy-capture-screenshot` / `omarchy-capture-screenrecording` |
| Ctrl+Super+R | ii restart | `omarchy-restart-shell` |

### 3.5 Retired packages

`waybar/` and `swaync/` are no longer stowed (left in the repo history, unused).

---

## 4. `shell.json` — feature scope

Encodes the agreed feature set.

- **Bar widgets:** workspaces, clock (center), audio, network, bluetooth, battery,
  tray, notifications, menu — **plus** tailscale, weather, model-usage (AI token usage).
- **Overlays/services enabled:** launcher, notifications, lock, idle, osd,
  clipboard, emojis, polkit, reminders.
- **Background plugin:** **disabled** (waypaper-engine owns the wallpaper).
- **Excluded:** web-app system (menu rows that call webapp scripts pruned via the
  `omarchy-menu.jsonc` extension).
- **Baseline behaviors kept:** command menu, Hyprland/system toggles (gaps,
  transparency, tiled-fullscreen, single-square-aspect, workspace-layout, nightlight,
  notification-silencing, idle), launch-or-focus.
- **Capture suite included:** screenshot, screen-recording (+ webcam/desktop-audio/mic),
  OCR text capture, color picker, transcode.
- **Idle timings:** `idle.screensaver` / `idle.lock` mirrored from current hypridle values.

---

## 5. Theming (gruvbox-material, shell-only)

- Stock omarchy ships plain `gruvbox`; create a custom `gruvbox-material` theme under
  `omarchy-config/.config/omarchy/themes/gruvbox-material/`:
  - `colors.toml` — foreground/background/accent/urgent/muted from the gruvbox-material palette.
  - `shell.toml` — generated from `default/themed/shell.toml.tpl`.
- Activate by setting the state symlink **directly**:
  `~/.local/state/omarchy/current/theme -> …/themes/gruvbox-material`.
- **Do NOT** run full `omarchy-theme-set` — it also rewrites browser/vscode/gnome/foot/
  tmux configs, which must stay untouched. Shell-only theming.
- The state symlink is runtime (not stowed); created manually now, scripted in Spec 2.

---

## 6. System integration (needs sudo; done manually now, scripted in Spec 2)

Selected for inclusion in this spec:

- **SDDM greeter theme** — omarchy's themed login (QML + assets) → `/usr/share/…` + sddm conf.
- **systemd user services** — `bt-agent` (bluetooth auto-agent) + sleep hooks
  (keyboard-backlight, force-igpu). **Skip** omarchy-update-notify.
- **Small tweaks** — wireplumber alsa soft-mixer, fontconfig `50-omarchy.conf`,
  xdg-terminal-exec list.
- **Lock PAM** — create `/etc/pam.d/omarchy-lock-password` (and, if fingerprints
  enrolled, `omarchy-lock-fingerprint`). If declined, keep hyprlock bound as lock.
- **Package installs** — `uwsm`, and shell runtime deps: hyprsunset, hyprpicker,
  gpu-screen-recorder, satty/grim, wl-clipboard, localsend, gum, nerd-fonts, the
  omarchy icon font, polkit. (Full manifest formalized in Spec 2.)

### Session model (uwsm)

- SDDM → **`hyprland-uwsm`** session; env from `~/.config/uwsm/env.d`; autostart via
  `uwsm app -- …`.
- **Vanilla `hyprland` session kept** at the greeter as a one-click fallback.

---

## 7. Risks & mitigations (verify at implementation start)

1. **Quickshell version compatibility (go/no-go gate).** omarchy 4.0-alpha uses newer
   Quickshell services (Polkit, WlSessionLock, DesktopEntries). *Mitigation:* first
   implementation step verifies the installed `quickshell` renders the shell and
   exposes those services; if not, update quickshell before proceeding.
2. **Lock PAM missing.** `omarchy.lock` needs `/etc/pam.d/omarchy-lock-password`.
   *Mitigation:* create it; fallback to hyprlock bound to the lock key.
3. **Missing tool deps.** Capture/toggles expect hyprsunset/hyprpicker/gpu-screen-recorder/
   satty/grim/wl-clipboard/localsend/gum. *Mitigation:* dependency check; install or
   disable the affected menu row.
4. **uwsm session env correctness.** A bad `env.d` breaks session env → shell can't find
   scripts. *Mitigation:* keep vanilla `hyprland` session as fallback; validate env in a
   nested/second session before making uwsm the default choice.
5. **Two bars can't overlap.** Can't A/B `ii` and omarchy live. *Mitigation:* clean cutover
   with one-step rollback (§8).

---

## 8. Rollback

- Old `ii` / swaync / hypridle / vicinae autostart lines kept **commented**, not deleted.
- `ii` config remains intact on disk (untouched).
- At the greeter, choosing the vanilla `hyprland` session restores the pre-uwsm launch.
- Revert = uncomment the old execs, comment the omarchy exec, pick `hyprland` session.

---

## 9. Verification (end-to-end, after cutover)

1. Shell process starts; bar renders.
2. Every bar widget live: audio, network, bluetooth, battery, clock, workspaces,
   tailscale, weather, model-usage.
3. `Super+Space` opens launcher and launches an app.
4. `omarchy-menu` opens; a toggle (nightlight) and a screenshot both work.
5. A test notification (`notify-send`) appears via `omarchy.notifications`.
6. Lock works (or hyprlock fallback engages).
7. Clipboard and emoji overlays open and paste/insert.
8. Colors are gruvbox-material across bar/launcher/lock.
9. Reminders fire; capture suite (screenshot/record/OCR) works.
10. Logout/login via `hyprland-uwsm` is clean; fallback `hyprland` session still works.

---

## 10. Delivery

1. Build all packages + this spec on `feat/omarchy-shell-fork` (worktree at
   `~/.dotfiles-omarchy`).
2. Commit incrementally.
3. Update `README.md` (new packages, uwsm session note, stow order).
4. **Confirm with the user** before pushing.
5. Push branch, open PR into `main` via `gh`. The PR is for the user to review/merge
   (no auto-merge).

Live-system application (sudo installs, session switch, stowing over the live config)
is performed with explicit confirmation, separately from producing the branch/PR.
