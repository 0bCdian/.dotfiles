# My Linux Environment Dotfiles ⚙️🐧

Here's where I will store all of my relevant configurations for things like fish,
nvim, kitty, hyprland etc. To use this dotfiles follow the instructions:

1. Clone this repo into your `$HOME` directory:

```bash
git clone git@github.com:0bCdian/.dotfiles.git
```

2. Install [stow](https://www.gnu.org/software/stow/) if you haven't already:

```bash
  sudo pacman -S stow
```

Or

```bash
yay stow
```

> [!NOTE]
> Go to the gnu stow link for more information on how to install on distros.

3. CD into the downloaded .dotfiles directory:

```bash
cd .dotfiles
```

4. Stow what you want, for example:

```bash
# This copies the contents of the hypr directory in $HOME/.config/hypr
stow hypr
```

---

## Desktop shell — omarchy fork 🐚

The Hyprland desktop shell is a **frozen fork of [omarchy](https://github.com/basecamp/omarchy) 4.0's Quickshell shell** (bar, launcher, notifications, lock, idle, OSD, clipboard, emoji, polkit agent, and the `omarchy-menu` command palette). It replaces the old end4/illogical-impulse (`ii`) shell. Wallpaper stays on my own **waypaper-engine**; theming is curated **gruvbox-material**; the session runs under **uwsm**.

This is a *frozen* fork: omarchy naming/paths are kept intact, and future upstream features are ported manually — not tracked from a remote.

### Packages this adds

| Package | Deploys to | Purpose |
|---|---|---|
| `omarchy-shell` | `~/.local/share/omarchy-shell` (`OMARCHY_PATH`) | vendored shell + `omarchy-*` scripts (theme wallpapers stripped) |
| `omarchy-config` | `~/.config/omarchy` | `shell.json` bar layout, `gruvbox-material` theme, menu overrides |
| `uwsm` | `~/.config/uwsm` | session env: exports `OMARCHY_PATH` and prepends its `bin/` to `PATH` |
| `hypr` | `~/.config/hypr` | launches the shell under uwsm; launcher/menu/clipboard/emoji/restart binds |

`waybar` and `swaync` are retired (no longer stowed).

### Install order (fresh machine)

```bash
# 1. system deps (Arch): uwsm gpu-screen-recorder gum + AUR localsend, plus
#    hyprsunset hyprpicker hyprlock satty grim slurp wl-clipboard, nerd fonts.
# 2. stow the packages
stow omarchy-shell uwsm omarchy-config hypr
# 3. shell theme (runtime state, not stowed):
ln -sfn ~/.config/omarchy/themes/gruvbox-material ~/.local/state/omarchy/current/theme
# 4. lock PAM (sudo): /etc/pam.d/omarchy-lock-password  (see the plan)
# 5. log in via the "hyprland-uwsm" session at the greeter
```

> The full step-by-step (system integration + cutover) lives in
> `docs/superpowers/plans/2026-07-19-omarchy-shell-fork.md`; the design rationale
> is in `docs/superpowers/specs/2026-07-19-omarchy-shell-fork-design.md`.

### Rollback to `ii`

Every swap keeps the old line commented with a `ROLLBACK` note. To revert:
uncomment the `qs -c ii`, `hypridle`, cliphist, and `vicinae server` lines in
`hypr/.config/hypr/hyprland/execs.lua`, restore the old binds, and pick the plain
`hyprland` session at the greeter. The `ii` config is left untouched on disk.

---

> [!IMPORTANT]
> Please before opening an issue, read how gnu stow works.
> Also please only install what you know how to use,
> I don't have the time to help debug other's configs.
