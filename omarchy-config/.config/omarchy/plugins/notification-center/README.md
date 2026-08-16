# obsy.notification-center

Bar bell with an unread count, a recent-notification list, and a DND toggle.

## Why this exists

Omarchy's own notification bar widget was removed from core in `fc4caf3c` and
republished as [`omacom.notification-center`](https://github.com/omacom-io/omarchy-notification-center-plugin).
That plugin has not been updated since it was extracted on 2026-07-25, and it
binds to `service.pendingModel` / `service.pastModel`, which `ab57ad65`
(2026-08-12) deleted when notification history moved to the last ten entries on
disk. Installing it against quattro gives a bell whose list never populates.

This reads the shape the rewritten service actually exposes:

| what | where |
|------|-------|
| unread (still on screen) | `service.popupModel` |
| recent history | `~/.local/state/omarchy/notifications/history/*.json` |
| DND | `service.doNotDisturb` / `setDoNotDisturb()` |

Live rows win the dedupe against their archived copies: a toast still on screen
is already archived too, and the live copy is the one the service can still act
on.

## Behaviour

- **Left click** the bell — open the list. **Right click** — toggle DND.
- The count is notifications *still on screen*. Once a toast expires it stops
  counting but stays in the list, because that is the only "unread" the
  rewritten service still models.
- Clicking a row dismisses it. There is deliberately no click-to-invoke: an
  archived row has no live actions to invoke, so the click would silently do
  nothing on exactly the rows you are most likely to click.

## Settings

`limit` (default 10) — how many recent notifications to list. The service only
keeps ten on disk, so raising it past 10 shows more only while extra toasts are
live.

## Deploying

Stowed with the rest of `omarchy-config`. Because `~/.config/omarchy/plugins`
is a real directory the shell creates at startup, stow folds a symlink for this
folder inside it rather than linking the whole `plugins` dir.

`omarchy-plugin-validate` rejects any plugin folder that is a symlink, so it
will refuse this one. The shell's own loader is fine with it — its scan globs
`*/` and tests `-f "$sub/manifest.json"`, both of which follow symlinks. The
validator's rule guards against symlink escapes in plugins cloned from the
internet, which does not apply to a plugin tracked in this repo.
