# Omarchy Shell Fork — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace end4 `ii` with omarchy 4.0's Quickshell shell, vendored as a frozen fork inside the stow-managed `~/.dotfiles`, wired via uwsm, themed gruvbox-material, delivered as a PR into `main`.

**Architecture:** Vendor a trimmed copy of `~/omarchy` into a new `omarchy-shell` stow package deployed to `~/.local/share/omarchy-shell` (= `OMARCHY_PATH`). Author `~/.config/omarchy/shell.json` and a gruvbox-material theme as stow packages. Move session launch to uwsm (env from `~/.config/uwsm/env.d`), swap autostart from `ii` to the omarchy shell, and repoint launcher/menu/clipboard/emoji keybinds. System bits (sddm theme, systemd user services, small tweaks, lock PAM) applied with sudo. Keep vanilla `hyprland` session + commented `ii` execs as rollback.

**Tech Stack:** GNU stow, Hyprland (Lua config), Quickshell, uwsm, systemd --user, SDDM, bash.

**Spec:** `docs/superpowers/specs/2026-07-19-omarchy-shell-fork-design.md`

**Worktree:** `~/.dotfiles-omarchy` on branch `feat/omarchy-shell-fork` (off `main`).

## Global Constraints

- Fork is **frozen & vendored**: keep omarchy naming, `OMARCHY_PATH`, and `omarchy-*` script names verbatim. No renaming/de-omarchy surgery.
- **Do not touch** terminal (ghostty/kitty/foot), editor (nvim), tmux, fish, btop, yazi, starship, lazygit configs.
- **Wallpaper stays on waypaper-engine.** omarchy background plugin disabled; never call `omarchy-theme-bg-*`.
- **Shell-only theming:** never run full `omarchy-theme-set` (it rewrites app configs). Set the `current/theme` state symlink directly.
- Source of vendored files: `~/omarchy` (version `4.0.0.alpha`).
- All repo edits happen in the worktree `~/.dotfiles-omarchy`; stow is run from there.
- Rollback must remain one-step at every point: old `ii`/swaync/hypridle/vicinae execs stay **commented, not deleted**; vanilla `hyprland` SDDM session stays available.
- **Confirmation gates:** Tasks that mutate the live system with sudo or switch the SDDM session (Tasks 7, 8) and the push/PR (Task 9) require explicit user confirmation before running.

---

### Task 1: Preflight — quickshell compatibility gate + dependency inventory

**Files:**
- Create: `~/.dotfiles-omarchy/docs/superpowers/plans/preflight-notes.md` (findings log)

**Interfaces:**
- Produces: a go/no-go decision and a concrete list of missing packages consumed by Task 7.

- [ ] **Step 1: Record installed quickshell version and available services**

Run:
```bash
quickshell --version
qmldir=$(quickshell --help 2>&1 | head -1); echo "$qmldir"
```
Expected: a version prints (any). Record it.

- [ ] **Step 2: Smoke-test that the vendored shell renders with this quickshell**

Run (does NOT replace ii; just checks the shell parses/loads for ~5s in the current session, then kills it):
```bash
OMARCHY_PATH="$HOME/omarchy" timeout 5 quickshell -n -p "$HOME/omarchy/shell" 2>&1 | tee /tmp/omarchy-shell-smoke.log; echo "exit: ${PIPESTATUS[0]}"
```
Expected: a bar/overlay attempts to render; log shows no fatal `module "Quickshell.Services.*" is not installed` / QML type errors for Polkit, WlSessionLock, DesktopEntries. A timeout kill (exit 124) after rendering is success.

- [ ] **Step 3: Decide go/no-go**

If the log shows missing Quickshell modules/services, STOP and update quickshell (`sudo pacman -S quickshell` or the git/AUR build omarchy expects) before continuing. Record the outcome in `preflight-notes.md`.

- [ ] **Step 4: Inventory dependencies actually present vs needed**

Run:
```bash
for p in uwsm hyprsunset hyprpicker hyprlock gpu-screen-recorder satty grim slurp wl-clipboard localsend gum; do
  printf '%-22s ' "$p"; command -v "$p" >/dev/null && echo present || echo MISSING
done
```
Expected: a table. Write the MISSING list into `preflight-notes.md` for Task 7.

- [ ] **Step 5: Commit the findings log**

```bash
cd ~/.dotfiles-omarchy
git add docs/superpowers/plans/preflight-notes.md
git commit -m "chore: preflight notes (quickshell compat + dep inventory)"
```

---

### Task 2: Vendor the omarchy tree into the `omarchy-shell` stow package

**Files:**
- Create: `omarchy-shell/.local/share/omarchy-shell/{version,shell,bin,config/omarchy,default/omarchy,default/themed,default/fonts,default/hypr,themes}` (copied from `~/omarchy`)

**Interfaces:**
- Produces: `OMARCHY_PATH` tree at stow-deploy target `~/.local/share/omarchy-shell`. Consumed by every later task (scripts, shell, themes).

- [ ] **Step 1: Create the package skeleton**

```bash
cd ~/.dotfiles-omarchy
mkdir -p omarchy-shell/.local/share/omarchy-shell
```

- [ ] **Step 2: Copy the in-scope subtrees (trim system-install dirs)**

```bash
SRC="$HOME/omarchy"; DST=~/.dotfiles-omarchy/omarchy-shell/.local/share/omarchy-shell
cp "$SRC/version" "$DST/"
cp -r "$SRC/shell" "$SRC/bin" "$SRC/themes" "$DST/"
mkdir -p "$DST/config" "$DST/default"
cp -r "$SRC/config/omarchy" "$DST/config/"
cp -r "$SRC/default/omarchy" "$SRC/default/themed" "$SRC/default/fonts" "$SRC/default/hypr" "$DST/default/"
```

- [ ] **Step 3: Verify the tree and that excluded dirs are absent**

Run:
```bash
DST=~/.dotfiles-omarchy/omarchy-shell/.local/share/omarchy-shell
ls "$DST"; echo "---default---"; ls "$DST/default"
test ! -e "$DST/default/limine" && test ! -e "$DST/default/bash" && echo "EXCLUDED OK"
test -f "$DST/shell/shell.qml" && test -f "$DST/default/omarchy/omarchy-menu.jsonc" && echo "CORE OK"
```
Expected: `EXCLUDED OK` and `CORE OK` both print.

- [ ] **Step 4: Dry-run stow to confirm no conflicts, then verify target**

Run:
```bash
cd ~/.dotfiles-omarchy && stow -n -v -t "$HOME" omarchy-shell 2>&1 | head
```
Expected: stow reports planned `LINK` for `.local/share/omarchy-shell` with no conflicts.

- [ ] **Step 5: Commit**

```bash
cd ~/.dotfiles-omarchy
git add omarchy-shell
git commit -m "feat(omarchy-shell): vendor frozen omarchy shell fork (trimmed)"
```

---

### Task 3: uwsm env package

**Files:**
- Create: `uwsm/.config/uwsm/env.d/10-omarchy-shell.conf`
- Create: `uwsm/.config/uwsm/env` (login-time env, sourced by uwsm)

**Interfaces:**
- Consumes: `OMARCHY_PATH` target from Task 2.
- Produces: `OMARCHY_PATH` and `PATH` on the graphical session env. Consumed by shell + menu actions.

- [ ] **Step 1: Write the env.d fragment**

Create `uwsm/.config/uwsm/env.d/10-omarchy-shell.conf`:
```sh
# Omarchy shell fork — session environment (sourced by uwsm as shell).
export OMARCHY_PATH="$HOME/.local/share/omarchy-shell"
export PATH="$OMARCHY_PATH/bin:$PATH"
```

- [ ] **Step 2: Write the uwsm env defaults (terminal/browser/editor)**

Create `uwsm/.config/uwsm/env`:
```sh
# Adjust to taste; omarchy defaults shown.
export TERMINAL=ghostty
export BROWSER=omarchy-launch-browser
export EDITOR="nvim"
```

- [ ] **Step 3: Verify the fragment sources cleanly**

Run:
```bash
( set -e; HOME="$HOME"; . ~/.dotfiles-omarchy/uwsm/.config/uwsm/env.d/10-omarchy-shell.conf; echo "OMARCHY_PATH=$OMARCHY_PATH"; echo "PATH head=${PATH%%:*}" )
```
Expected: prints `OMARCHY_PATH=/home/obsy/.local/share/omarchy-shell` and PATH head = that `/bin`.

- [ ] **Step 4: Dry-run stow + commit**

```bash
cd ~/.dotfiles-omarchy && stow -n -v -t "$HOME" uwsm 2>&1 | head
git add uwsm && git commit -m "feat(uwsm): session env for omarchy shell (OMARCHY_PATH, PATH)"
```

---

### Task 4: `omarchy-config` — shell.json (bar layout + plugins + idle)

**Files:**
- Create: `omarchy-config/.config/omarchy/shell.json`
- Create: `omarchy-config/.config/omarchy/extensions/omarchy-menu.jsonc` (prune web-app rows)

**Interfaces:**
- Consumes: widget ids from the vendored `plugins/README.md`.
- Produces: the authored bar/plugin config the shell reads at startup.

- [ ] **Step 1: Read current idle timings to mirror them**

Run:
```bash
grep -iE "timeout|screensaver|lock" ~/.config/hypr/hypridle.conf 2>/dev/null || echo "(defaults 150/300)"
```
Record the two values (fallback 150 / 300).

- [ ] **Step 2: Write shell.json** (background plugin absent = disabled; web-app widgets omitted; tailscale/weather/model-usage added)

Create `omarchy-config/.config/omarchy/shell.json`:
```json
{
  "version": 1,
  "idle": { "screensaver": 150, "lock": 300 },
  "bar": {
    "id": "omarchy.bar",
    "position": "top",
    "transparent": false,
    "centerAnchor": "omarchy.clock",
    "layout": {
      "left": [
        { "id": "omarchy.menu" },
        { "id": "omarchy.workspaces" }
      ],
      "center": [
        { "id": "omarchy.clock", "format": "ddd HH:mm" },
        { "id": "omarchy.weather" }
      ],
      "right": [
        { "id": "omarchy.tray" },
        { "id": "omarchy.model-usage" },
        { "id": "omarchy.tailscale" },
        { "id": "omarchy.bluetooth" },
        { "id": "omarchy.network" },
        { "id": "omarchy.audio" },
        { "id": "omarchy.notifications" },
        { "id": "omarchy.power" }
      ]
    }
  },
  "plugins": []
}
```
(Replace the two idle integers with the values from Step 1 if different.)

- [ ] **Step 3: Validate JSON**

Run:
```bash
python -c "import json,sys;json.load(open(sys.argv[1]));print('valid')" ~/.dotfiles-omarchy/omarchy-config/.config/omarchy/shell.json
```
Expected: `valid`.

- [ ] **Step 4: Write menu extension pruning web-app rows**

Create `omarchy-config/.config/omarchy/extensions/omarchy-menu.jsonc`:
```jsonc
{
  // User overrides layered on default/omarchy/omarchy-menu.jsonc.
  // Web-app system is out of scope for this fork; hide those rows.
  "install.webapp": { "when": "false" },
  "remove.webapp":  { "when": "false" }
}
```
(If those exact ids differ in the vendored `omarchy-menu.jsonc`, adjust to match; verify with `grep -n webapp ~/.dotfiles-omarchy/omarchy-shell/.local/share/omarchy-shell/default/omarchy/omarchy-menu.jsonc`.)

- [ ] **Step 5: Dry-run stow + commit**

```bash
cd ~/.dotfiles-omarchy && stow -n -v -t "$HOME" omarchy-config 2>&1 | head
git add omarchy-config && git commit -m "feat(omarchy-config): shell.json bar layout + menu web-app pruning"
```

---

### Task 5: gruvbox-material theme (shell-only)

**Files:**
- Create: `omarchy-config/.config/omarchy/themes/gruvbox-material/colors.toml` (+ backgrounds omitted — waypaper owns wallpaper)

**Interfaces:**
- Consumes: stock `gruvbox` palette from Task 2's vendored `themes/gruvbox`.
- Produces: a theme dir the `current/theme` state symlink will target (Task 8).

- [ ] **Step 1: Copy stock gruvbox colors as the material base**

```bash
SRC=~/.dotfiles-omarchy/omarchy-shell/.local/share/omarchy-shell/themes/gruvbox
DST=~/.dotfiles-omarchy/omarchy-config/.config/omarchy/themes/gruvbox-material
mkdir -p "$DST"
cp "$SRC/colors.toml" "$DST/colors.toml"
```
(Stock gruvbox already uses the material palette: `fg=#d4be98`, `accent=#7daea3`, `bg=#282828`. Copying is correct; hand-tune only if desired.)

- [ ] **Step 2: Verify colors.toml has the foundational keys the shell needs**

Run:
```bash
grep -E "^(bg|fg|accent|muted|red) " ~/.dotfiles-omarchy/omarchy-config/.config/omarchy/themes/gruvbox-material/colors.toml
```
Expected: all five keys print with hex values.

- [ ] **Step 3: Generate shell.toml from the template (optional per-surface theming)**

Run (only if the template is a plain copy; the shell falls back to colors.toml if shell.toml is absent, so this is best-effort):
```bash
TPL=~/.dotfiles-omarchy/omarchy-shell/.local/share/omarchy-shell/default/themed/shell.toml.tpl
head -5 "$TPL"
```
If the template contains no unresolved `{{...}}` placeholders, copy it to the theme dir as `shell.toml`; if it does, SKIP (colors.toml fallback is sufficient) and note it.

- [ ] **Step 4: Commit**

```bash
cd ~/.dotfiles-omarchy
git add omarchy-config/.config/omarchy/themes/gruvbox-material
git commit -m "feat(theme): add gruvbox-material shell theme (material palette)"
```

---

### Task 6: Capture live Hypr lua config into `hypr` package + wire the shell

**Files:**
- Create/replace: `hypr/.config/hypr/**` (from live `~/.config/hypr`, lua config)
- Modify: `hypr/.config/hypr/hyprland/execs.lua` (autostart swap)
- Modify: `hypr/.config/hypr/custom/keybinds.lua` (launcher/menu/clipboard/emoji/capture/restart)

**Interfaces:**
- Consumes: `OMARCHY_PATH`/`PATH` from Task 3; `omarchy-*` scripts from Task 2.
- Produces: a Hyprland config that launches the omarchy shell under uwsm and summons omarchy overlays.

- [ ] **Step 1: Snapshot the live lua config into the package**

```bash
cd ~/.dotfiles-omarchy
rm -rf hypr/.config/hypr
mkdir -p hypr/.config/hypr
cp -r ~/.config/hypr/. hypr/.config/hypr/
# drop editor/agent cruft and backups
rm -rf hypr/.config/hypr/.claude hypr/.config/hypr/*.bak
```

- [ ] **Step 2: Verify it captured the lua entry point (not the stale .conf)**

Run:
```bash
test -f ~/.dotfiles-omarchy/hypr/.config/hypr/hyprland.lua && echo "LUA OK"
grep -c "qsConfig" ~/.dotfiles-omarchy/hypr/.config/hypr/hyprland.lua
```
Expected: `LUA OK`.

- [ ] **Step 3: Swap the shell autostart** in `hypr/.config/hypr/hyprland/execs.lua`

Replace the `qs -c ii` line and comment the retired daemons. Change:
```lua
    hl.exec_cmd("qs -c " .. qsConfig .. " &")
```
to:
```lua
    -- ROLLBACK: re-enable ii by uncommenting the next line and commenting the omarchy line.
    -- hl.exec_cmd("qs -c " .. qsConfig .. " &")
    hl.exec_cmd("uwsm app -- quickshell -n -p " .. os.getenv("HOME") .. "/.local/share/omarchy-shell/shell")
```
And comment the retired lines (hypridle, vicinae, swaync if present):
```lua
    -- hl.exec_cmd("hypridle")                 -- replaced by omarchy.idle
    -- hl.exec_cmd("vicinae server &")         -- replaced by omarchy.launcher
```
Keep `waypaper-engine daemon`, geoclue, and gnome-keyring lines unchanged.

- [ ] **Step 4: Repoint keybinds** in `hypr/.config/hypr/custom/keybinds.lua`

Replace the vicinae bind:
```lua
hl.bind(mod .. " + space",  hl.dsp.exec_cmd("vicinae toggle"))
```
with the launcher + new binds:
```lua
hl.bind(mod .. " + space",   hl.dsp.exec_cmd("omarchy-shell shell toggle omarchy.launcher"))
hl.bind(mod .. " + escape",  hl.dsp.exec_cmd("omarchy-menu"))
hl.bind(mod .. " + v",       hl.dsp.exec_cmd("omarchy-shell shell toggle omarchy.clipboard"))
hl.bind(mod .. " + period",  hl.dsp.exec_cmd("omarchy-shell shell toggle omarchy.emojis"))
hl.bind("Print",             hl.dsp.exec_cmd("omarchy-capture-screenshot"))
hl.bind("SHIFT + Print",     hl.dsp.exec_cmd("omarchy-capture-screenrecording"))
```
And repoint the restart bind (in `hyprland/keybinds.lua`) from the ii restart to:
```lua
hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("omarchy-restart-shell"))
```
(If `mod`/`Super_L` naming differs, match the file's existing convention — verify the `mod` variable name at the top of the file first.)

- [ ] **Step 5: Remove any OMARCHY_PATH from hypr env (now owned by uwsm)**

Run:
```bash
grep -rn "OMARCHY_PATH" ~/.dotfiles-omarchy/hypr/.config/hypr/ || echo "none in hypr (good)"
```
Expected: `none in hypr (good)` (env lives in the uwsm package). If found, delete those `env =` lines.

- [ ] **Step 6: Lua-lint the two edited files**

Run:
```bash
for f in hyprland/execs.lua custom/keybinds.lua hyprland/keybinds.lua; do
  luac -p ~/.dotfiles-omarchy/hypr/.config/hypr/$f 2>&1 && echo "OK $f"
done
```
Expected: `OK` for each (no syntax errors). If `luac` unavailable, use `lua -e "assert(loadfile('<path>'))"`.

- [ ] **Step 7: Commit**

```bash
cd ~/.dotfiles-omarchy
git add hypr
git commit -m "feat(hypr): launch omarchy shell under uwsm; repoint launcher/menu/clipboard/emoji binds"
```

---

### Task 7: System integration (sudo) — CONFIRMATION GATE

**Files (system, not repo):**
- Create: `/etc/pam.d/omarchy-lock-password`
- Install: sddm greeter theme assets/config; systemd user services; small tweaks
- Install: missing packages from Task 1 Step 4

**Interfaces:**
- Consumes: MISSING package list (Task 1); vendored `default/{sddm,systemd,wireplumber,fontconfig,xdg-terminal-exec}` sources — NOTE these were trimmed from the vendored package, so copy them from `~/omarchy` directly here.

- [ ] **Step 1: Confirm with the user before any sudo action.** Summarize exactly what will be installed/changed. Proceed only on explicit approval.

- [ ] **Step 2: Install missing packages**

```bash
sudo pacman -S --needed uwsm hyprsunset hyprpicker gpu-screen-recorder satty grim slurp wl-clipboard gum
# AUR (yay) as needed: localsend, ttf nerd fonts, omarchy icon font
```
(Use only the entries flagged MISSING in preflight-notes.md.)

- [ ] **Step 3: Create the lock PAM service**

```bash
sudo tee /etc/pam.d/omarchy-lock-password >/dev/null <<'EOF'
auth include system-auth
EOF
```
Verify: `test -f /etc/pam.d/omarchy-lock-password && echo PAM_OK`.

- [ ] **Step 4: Install the SDDM greeter theme**

```bash
sudo cp -r ~/omarchy/default/sddm/omarchy /usr/share/sddm/themes/omarchy 2>/dev/null || true
# point sddm at it
sudo install -d /etc/sddm.conf.d
printf '[Theme]\nCurrent=omarchy\n' | sudo tee /etc/sddm.conf.d/omarchy-theme.conf
```
Verify: `cat /etc/sddm.conf.d/omarchy-theme.conf`. (Do NOT restart sddm now — takes effect next login.)

- [ ] **Step 5: Install cherry-picked systemd user services + sleep hooks**

```bash
install -d ~/.config/systemd/user
cp ~/omarchy/default/systemd/user/bt-agent.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now bt-agent.service
# sleep hooks (system-level)
sudo cp ~/omarchy/default/systemd/system-sleep/keyboard-backlight /usr/lib/systemd/system-sleep/ 2>/dev/null || true
sudo cp ~/omarchy/default/systemd/system-sleep/force-igpu /usr/lib/systemd/system-sleep/ 2>/dev/null || true
sudo chmod +x /usr/lib/systemd/system-sleep/{keyboard-backlight,force-igpu} 2>/dev/null || true
```
Verify: `systemctl --user is-enabled bt-agent.service`.

- [ ] **Step 6: Apply small tweaks**

```bash
sudo cp ~/omarchy/default/fontconfig/conf.avail/50-omarchy.conf /etc/fonts/conf.avail/ 2>/dev/null || true
sudo ln -sf /etc/fonts/conf.avail/50-omarchy.conf /etc/fonts/conf.d/ 2>/dev/null || true
install -d ~/.config/wireplumber/wireplumber.conf.d
cp ~/omarchy/default/wireplumber/wireplumber.conf.d/alsa-soft-mixer.conf ~/.config/wireplumber/wireplumber.conf.d/ 2>/dev/null || true
# install the omarchy icon font so bar glyphs render
install -d ~/.local/share/fonts && cp ~/omarchy/default/fonts/omarchy/omarchy.ttf ~/.local/share/fonts/ && fc-cache -f >/dev/null
```
Verify: `fc-list | grep -i omarchy && echo FONT_OK`.

- [ ] **Step 7: Record what was done**

Append the actions taken to `docs/superpowers/plans/preflight-notes.md` and commit that file.

---

### Task 8: Cutover — stow, uwsm session, launch, verify — CONFIRMATION GATE

**Files:** none new; deploys packages and creates the runtime theme symlink.

**Interfaces:**
- Consumes: all prior packages.
- Produces: a live omarchy-shell session.

- [ ] **Step 1: Confirm with the user.** This unstows nothing destructive but replaces the running shell on next relaunch and changes the default session. Proceed only on approval. Recommend doing this from a TTY or with a second session available.

- [ ] **Step 2: Unstow retired packages, stow new ones**

```bash
cd ~/.dotfiles-omarchy
stow -D -t "$HOME" waybar swaync 2>/dev/null || true
# hypr is currently NOT a symlink (real dir) — back it up before stowing
[ -L "$HOME/.config/hypr" ] || mv "$HOME/.config/hypr" "$HOME/.config/hypr.pre-omarchy.bak"
stow -t "$HOME" omarchy-shell uwsm omarchy-config hypr
```
Verify: `readlink ~/.config/omarchy/shell.json` and `readlink ~/.local/share/omarchy-shell` both point into `~/.dotfiles-omarchy`.

- [ ] **Step 3: Create the runtime theme symlink (gruvbox-material)**

```bash
install -d ~/.local/state/omarchy/current
ln -sfn ~/.config/omarchy/themes/gruvbox-material ~/.local/state/omarchy/current/theme
readlink ~/.local/state/omarchy/current/theme
```
Expected: prints the gruvbox-material path.

- [ ] **Step 4: Validate uwsm env in a subshell**

```bash
uwsm check may-start 2>&1 | head; echo "---"; env -i HOME="$HOME" bash -lc '. ~/.config/uwsm/env.d/10-omarchy-shell.conf; echo $OMARCHY_PATH; command -v omarchy-menu'
```
Expected: `OMARCHY_PATH` set and `omarchy-menu` resolves on PATH.

- [ ] **Step 5: Log out and log back in via the `hyprland-uwsm` session** (manual). If anything fails, pick the vanilla `hyprland` session to fall back.

- [ ] **Step 6: Run the end-to-end verification checklist** (from spec §9)

```bash
# after login, in a terminal:
pgrep -af "quickshell.*omarchy-shell/shell" && echo "SHELL RUNNING"
omarchy-shell shell ping                       # -> ok
notify-send "test" "omarchy notifications"     # -> banner appears
omarchy-shell shell toggle omarchy.launcher    # -> launcher opens
omarchy-menu                                    # -> menu opens
```
Tick each spec §9 item. Note failures for follow-up rather than reverting the whole cutover.

---

### Task 9: README + delivery (push + PR) — CONFIRMATION GATE

**Files:**
- Modify: `README.md`

**Interfaces:**
- Produces: PR into `main`.

- [ ] **Step 1: Update README** — document the new packages (`omarchy-shell`, `omarchy-config`, `uwsm`, updated `hypr`), the stow order, the uwsm session choice at the greeter, and the one-step rollback. Add a short "Shell (omarchy fork)" section.

- [ ] **Step 2: Commit**

```bash
cd ~/.dotfiles-omarchy && git add README.md && git commit -m "docs: document omarchy shell fork packages, stow order, rollback"
```

- [ ] **Step 3: Confirm with the user before pushing.**

- [ ] **Step 4: Push and open the PR**

```bash
cd ~/.dotfiles-omarchy
git push -u origin feat/omarchy-shell-fork
gh pr create --base main --head feat/omarchy-shell-fork \
  --title "Fork omarchy 4.0 Quickshell shell into dotfiles (replaces ii)" \
  --body-file docs/superpowers/specs/2026-07-19-omarchy-shell-fork-design.md
```
Expected: PR URL printed. Leave for the user to review/merge (no auto-merge).

---

## Self-Review

**Spec coverage:**
- §3.1 vendored package → Task 2. §3.2 omarchy-config → Task 4. §3.3 uwsm → Task 3. §3.4 hypr → Task 6. §3.5 retired packages → Task 8 Step 2.
- §4 shell.json scope → Task 4. §5 theming → Tasks 5 + 8 Step 3. §6 system bits → Task 7. §7 risks (quickshell gate, PAM, deps, uwsm env) → Tasks 1, 7, 8. §8 rollback → Tasks 6 (commented execs) + 8 (hypr backup, fallback session). §9 verification → Task 8 Step 6. §10 delivery → Task 9.
- All spec sections map to a task. No gaps.

**Placeholder scan:** No TBD/TODO. Two intentional "verify id/naming matches" checks (Task 4 Step 4, Task 6 Step 4) include the exact grep to resolve them — not placeholders.

**Type/name consistency:** `OMARCHY_PATH=$HOME/.local/share/omarchy-shell` used identically in Tasks 2/3/6/8. Widget ids match the vendored `plugins/README.md`. Package names (`omarchy-shell`, `omarchy-config`, `uwsm`, `hypr`) consistent across stow commands.
