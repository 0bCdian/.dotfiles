# Hyprland config — Lua edition

Since **Hyprland 0.55**, the old `hyprlang` (`.conf`) syntax is **deprecated in
favour of Lua**. Hyprland now looks for `~/.config/hypr/hyprland.lua` and, if it
exists, loads it *instead of* `hyprland.conf`.

This repo still contains the original working `.conf` files **and** a full Lua
translation of them under [`lua/`](./lua). The Lua version is in a subfolder on
purpose, so nothing changes until you choose to activate it.

> You said you know programming but not Lua. This README is built for exactly
> that: a quick Lua-syntax primer, then how Hyprland plugs Lua in, then how to
> drive *this* config.

---

## Table of contents

1. [Lua in 5 minutes (for programmers)](#1-lua-in-5-minutes-for-programmers)
2. [How Hyprland uses Lua](#2-how-hyprland-uses-lua)
3. [The `hl` API you'll actually use](#3-the-hl-api-youll-actually-use)
4. [This repo's layout](#4-this-repos-layout)
5. [Activating the Lua config (and reverting)](#5-activating-the-lua-config-and-reverting)
6. [conf → Lua cheat sheet](#6-conf--lua-cheat-sheet)
7. [How to make common changes](#7-how-to-make-common-changes)
8. [Caveats / things to verify](#8-caveats--things-to-verify)
9. [Reference links](#9-reference-links)

---

## 1. Lua in 5 minutes (for programmers)

Lua is small. Here is essentially everything you need for config files.

### Comments
```lua
-- single line comment
--[[ multi
     line comment ]]
```

### Variables
```lua
local x = 10          -- file/block scoped. Use `local` 99% of the time.
y = 20                -- no `local` = GLOBAL (every required file can see it)
```
There is no `let`/`var`/`const`. Just `local` (scoped) or nothing (global).

### Types
```lua
local n   = 42          -- number  (no int/float split; 42 and 42.0 are numbers)
local s   = "hello"     -- string  (double or single quotes both fine)
local b   = true        -- boolean (true / false)
local nope = nil        -- nil = "no value" (like null/None/undefined)
```

### Strings join with `..`
There is **no `+` for strings**. Concatenation uses two dots:
```lua
local home = os.getenv("HOME")
local path = home .. "/.config/hypr"   -- "/home/you/.config/hypr"
```
This matters a lot below: the old `.conf` auto-expanded `$HOME` and `~`. Lua
does **not**, so we read `os.getenv("HOME")` and `..` it onto the string.

### Tables — the ONE data structure
A table is Lua's array, dictionary, and object all in one. `{ ... }`.

```lua
-- As a dictionary / record (key = value). This is what configs are made of:
local general = {
    gaps_in = 4,
    border_size = 1,
    col = {                       -- tables nest freely
        active_border = "rgba(0DB7D455)",
    },
}

-- As an array (1-indexed!). Lua arrays start at 1, not 0:
local dirs = { "left", "right", "up" }
print(dirs[1])   -- "left"
```

Two things programmers trip on:
- **Indexes start at `1`.**
- In a key=value table, **`=` not `:`** (it's not JSON). String keys with weird
  characters use brackets: `["col.active"] = ...`.

### Functions
```lua
local function add(a, b)
    return a + b
end

-- Anonymous function (a "lambda"), passed as a value:
local cb = function() print("clicked") end
```
Hyprland lets you bind a key to a function — that's how you run several actions
on one key (see ALT+TAB in `custom/keybinds.lua`).

### Loops
```lua
for i = 1, 10 do                 -- numeric: 1,2,...,10 inclusive
    print(i)
end

for index, value in ipairs(mylist) do   -- iterate an array in order
    print(index, value)
end
```
We use a numeric loop to generate the 10 workspace binds instead of typing 20
near-identical lines.

### Calling a function with a single table argument
This is the **most important Lua idiom for Hyprland**. When a function's only
argument is a table, you can drop the parentheses:

```lua
hl.monitor({ output = "DP-1" })   -- normal call
hl.monitor   { output = "DP-1" }  -- identical, parentheses optional
```
Both appear in the wild. This config uses the explicit-parentheses form
everywhere for consistency.

That's the whole language for our purposes.

---

## 2. How Hyprland uses Lua

- Hyprland loads **`~/.config/hypr/hyprland.lua`** at startup and on every
  reload. That single file is your entry point.
- It injects a global table called **`hl`** (think "Hyprland"). Every setting,
  bind, rule, monitor, etc. is a call on `hl`. You never `require` it — it's
  just there.
- Your config is **real Lua code that runs top to bottom.** Order matters:
  later `hl.config{}` calls override earlier ones, exactly like sourcing order
  did in `.conf`.
- **Splitting into files** uses Lua's built-in `require`:
  ```lua
  require("hyprland.env")   -- runs ~/.config/hypr/hyprland/env.lua, once
  require("custom.keybinds")-- runs ~/.config/hypr/custom/keybinds.lua
  ```
  A dot `.` in `require` is a path separator, so `"a.b"` → `a/b.lua`. Hyprland
  puts your config dir on Lua's search path, so this "just works" once the
  files sit under `~/.config/hypr/`.
- Because it's a real language, you also get loops, functions, variables, and
  even live queries (`hl.get_active_window()` etc.) — things the old `.conf`
  could never do.

---

## 3. The `hl` API you'll actually use

| Function | What it does | Old `.conf` equivalent |
|---|---|---|
| `hl.config({ section = { ... } })` | Set variables/keywords | `section { key = val }` |
| `hl.monitor({ output=..., mode=... })` | Configure a monitor | `monitor = ...` |
| `hl.env("NAME", "VALUE")` | Environment variable | `env = NAME,VALUE` |
| `hl.exec_cmd("cmd")` | Run a command now / on reload | `exec = cmd` |
| `hl.on("hyprland.start", fn)` | Run `fn` once at login | `exec-once = cmd` |
| `hl.bind("MODS + KEY", dsp, opts)` | Keybind | `bind = MODS,KEY,...` |
| `hl.dsp.*` | Dispatchers (the action a bind runs) | `killactive`, `exec`, … |
| `hl.window_rule({ match={...}, ... })` | Window rule | `windowrule = ...` |
| `hl.layer_rule({ match={...}, ... })` | Layer rule | `layerrule = ...` |
| `hl.workspace_rule({ workspace=..., ... })` | Workspace rule | `workspace = ...` |
| `hl.gesture({ fingers=, direction=, action= })` | Touchpad gesture | `gesture = ...` |
| `hl.curve(name, {...})` / `hl.animation({...})` | Animation curves/tracks | `bezier=` / `animation=` |

**Dispatchers** (`hl.dsp.*`) are the verbs. Instead of `bind = SUPER,Q,killactive`
you write `hl.bind("SUPER + Q", hl.dsp.window.close())`. They're grouped:
`hl.dsp.window.*`, `hl.dsp.workspace.*`, `hl.dsp.group.*`, `hl.dsp.focus(...)`,
`hl.dsp.exec_cmd(...)`, `hl.dsp.global(...)`, `hl.dsp.submap(...)`.

---

## 4. This repo's layout

The Lua tree under [`lua/`](./lua) mirrors the original `.conf` structure
one-to-one:

```
lua/
├── hyprland.lua        ← ENTRY POINT (requires everything else)
├── monitors.lua        ← monitors.conf
├── workspaces.lua      ← workspaces.conf
├── hyprland/           ← the "Defaults" folder
│   ├── env.lua
│   ├── execs.lua
│   ├── general.lua     ← the big one: general/decoration/input/animations/…
│   ├── rules.lua       ← window + layer + workspace rules
│   ├── colors.lua
│   └── keybinds.lua    ← only the 2 binds you had active
└── custom/             ← YOUR overrides (edit these)
    ├── env.lua
    ├── execs.lua
    ├── general.lua
    ├── rules.lua
    └── keybinds.lua    ← your real keybinds
```

Each `.lua` file starts with a comment naming the `.conf` file it came from and
the mapping rules it used, so you can diff them side by side.

---

## 5. Activating the Lua config (and reverting)

Nothing is live yet — `lua/hyprland.lua` is not where Hyprland looks. To switch:

**Activate**
```bash
cd ~/.config/hypr

# 1. Back up the .conf entry point so Hyprland stops using it.
#    (Hyprland prefers hyprland.lua over hyprland.conf when both exist, but
#     renaming makes your intent obvious and avoids confusion.)
mv hyprland.conf hyprland.conf.bak

# 2. Copy the Lua tree up into the config root.
cp -r lua/. .

# 3. Reload (or relog). If something is wrong, check the logs:
hyprctl reload
#    journalctl --user -u hyprland  (or run `Hyprland` from a TTY to see errors)
```
After step 2 you'll have `hyprland.lua` plus `hyprland/*.lua` and `custom/*.lua`
sitting next to the old `.conf` files. The `.lua` files win.

**Revert**
```bash
cd ~/.config/hypr
rm -f hyprland.lua                       # stop loading Lua
mv hyprland.conf.bak hyprland.conf       # restore the conf entry point
hyprctl reload
# (the *.lua modules can stay; without hyprland.lua they're never loaded)
```

> Tip: test in a throwaway TTY session first. Run `Hyprland` from a TTY — any
> Lua error prints to the terminal instead of silently failing.

---

## 6. conf → Lua cheat sheet

| Old `.conf` | Lua |
|---|---|
| `# comment` | `-- comment` |
| `$main_mod = SUPER` | `local mod = "SUPER"` |
| `general { gaps_in = 4 }` | `hl.config({ general = { gaps_in = 4 } })` |
| `key = true` / `yes` / `on` | `key = true` |
| `col.active_border = rgba(...)` | `col = { active_border = "rgba(...)" }` |
| `env = NAME,VALUE` | `hl.env("NAME", "VALUE")` |
| `$HOME` / `~` in a value | `os.getenv("HOME") .. "/..."` |
| `exec-once = cmd` | `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` |
| `exec = cmd` | `hl.exec_cmd("cmd")` |
| `bind = SUPER,Q,killactive` | `hl.bind("SUPER + Q", hl.dsp.window.close())` |
| `bind = SUPER,E,exec,kitty` | `hl.bind("SUPER + E", hl.dsp.exec_cmd("kitty"))` |
| `bindm = SUPER,mouse:272,movewindow` | `hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })` |
| `binde` (repeat) | `{ repeating = true }` option |
| `bindl` (works locked) | `{ locked = true }` option |
| `bindr` (on release) | `{ release = true }` option |
| `bindd = ...,"Desc",...` | `{ description = "Desc" }` option |
| `windowrule = match:class ^(X)$, float on` | `hl.window_rule({ match = { class = "^(X)$" }, float = true })` |
| `layerrule = match:namespace X, blur on` | `hl.layer_rule({ match = { namespace = "X" }, blur = true })` |
| `workspace = special:s, gapsout:30` | `hl.workspace_rule({ workspace = "special:s", gaps_out = 30 })` |
| `monitor = DP-1,2560x1440@240,1920x0,1,vrr,0` | `hl.monitor({ output="DP-1", mode="2560x1440@240", position="1920x0", scale=1, vrr=0 })` |
| `gesture = 3,horizontal,workspace` | `hl.gesture({ fingers=3, direction="horizontal", action="workspace" })` |
| `bezier = name,a,b,c,d` | `hl.curve("name", { type="bezier", points={ {a,b},{c,d} } })` |
| `animation = leaf,1,SPEED,curve,style` | `hl.animation({ leaf="leaf", enabled=true, speed=SPEED, bezier="curve", style="style" })` |

**Common dispatchers:**

| Old | Lua |
|---|---|
| `killactive` | `hl.dsp.window.close()` |
| `togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| `fullscreen` | `hl.dsp.window.fullscreen()` |
| `pin` | `hl.dsp.window.pin()` |
| `movewindow, l` | `hl.dsp.window.move({ direction = "left" })` |
| `resizeactive, 50 0` | `hl.dsp.window.resize({ x = 50, y = 0, relative = true })` |
| `movefocus, l` | `hl.dsp.focus({ direction = "left" })` |
| `workspace, r+1` | `hl.dsp.focus({ workspace = "r+1" })` |
| `movetoworkspace, 3` | `hl.dsp.window.move({ workspace = 3 })` |
| `movetoworkspacesilent, 3` | `hl.dsp.window.move({ workspace = 3, follow = false })` |
| `togglespecialworkspace, magic` | `hl.dsp.workspace.toggle_special("magic")` |
| `togglegroup` | `hl.dsp.group.toggle()` |
| `exec, foo` | `hl.dsp.exec_cmd("foo")` |
| `global, quickshell:x` | `hl.dsp.global("quickshell:x")` |

---

## 7. How to make common changes

**Add a keybind** → edit `custom/keybinds.lua`:
```lua
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))
```

**Run several actions on one key** → bind a function:
```lua
hl.bind("SUPER + X", function()
    hl.dispatch(hl.dsp.window.center())
    hl.dispatch(hl.dsp.window.pin())
end)
```

**Change a setting** → edit `custom/general.lua` (runs last, so it wins):
```lua
hl.config({ general = { gaps_in = 10, border_size = 2 } })
```

**Add a window rule** → edit `custom/rules.lua`:
```lua
hl.window_rule({ match = { class = "^(mpv)$" }, float = true, pin = true })
```

**Autostart an app** → edit `custom/execs.lua`:
```lua
hl.on("hyprland.start", function() hl.exec_cmd("nm-applet") end)
```

---

## 8. Caveats / things to verify

This is a faithful translation, but a few spots depend on details the official
example doesn't fully pin down. They're flagged in-line with `NOTE:` comments:

- **The `submap = global` catch-all was flattened.** Your old config opened a
  "global" submap so illogical-impulse's Super-key *search* binds could work.
  You have all of those binds commented out, so every bind here is defined at
  the top level instead — equivalent for your active set. If you re-enable ii's
  search binds, recreate the submap with `hl.define_submap("global", fn)`.
- **`hyprbars` plugin config** (in `hyprland/colors.lua`) is left **commented
  out.** Configuring third-party plugins from Lua isn't demonstrated by the
  official example, and the `hyprbars-button = ...` lines have no obvious table
  form yet. Enable only after checking the plugin's docs.
- **Legacy `gestures { workspace_swipe_* }`** knobs are translated under
  `hl.config({ gestures = {...} })`. Recent Hyprland leans on the new
  `gesture =` system; if it warns these keys are unknown, delete that block.
- **Window-rule effect names** (`no_blur`, `keep_aspect_ratio`, `immediate`, …)
  follow the wiki's rule names in snake_case. If Hyprland rejects one, check the
  exact token on the [Window Rules](https://wiki.hypr.land/Configuring/Window-Rules/)
  page.
- **Mouse-drag binds** use `{ mouse = true }`, matching the official
  `example/hyprland.lua`. (The reference docs also mention `{ drag = true }`;
  use whichever your Hyprland version accepts.)
- **`size`/`move` with math** (e.g. `(monitor_w*.45) (monitor_h*.45)`) are kept
  as strings, exactly as written in the conf.

The Lua loads without errors under a stubbed `hl` (syntax + require chain
verified), but only a real Hyprland reload confirms every keyword name. Keep
your `.conf.bak` until you're happy.

---

## 9. Reference links

- Start here / language style: <https://wiki.hypr.land/Configuring/Start/>
- Official example config: <https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua>
- `hl` API reference: <https://vinitlee.github.io/hl-docs/reference/hl/HL.API.html>
- Binds: <https://wiki.hypr.land/Configuring/Binds/>
- Window rules: <https://wiki.hypr.land/Configuring/Window-Rules/>
- Variables: <https://wiki.hypr.land/Configuring/Variables/>
- Lua 5.x manual (the language itself): <https://www.lua.org/manual/5.4/>
