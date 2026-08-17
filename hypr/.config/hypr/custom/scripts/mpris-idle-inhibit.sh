#!/bin/bash
# Hold a systemd idle inhibitor for as long as any MPRIS player is Playing.
#
# Window rules can only see windows, so they cannot tell a YouTube tab that is
# playing from one that is paused, and they lose track entirely once the tab is
# backgrounded. MPRIS is the actual signal: it reports playback state directly,
# for the browser and for real music players alike.
#
# hypridle honours systemd idle inhibitors (general:ignore_systemd_inhibit
# defaults to false), so holding one here is enough to reach it — the same
# mechanism omarchy-toggle-idle uses for stay-awake.

set -uo pipefail

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/mpris-idle-inhibit.pid"
INTERVAL="${MPRIS_IDLE_POLL_SECONDS:-15}"

hold() {
  if [[ -f $PIDFILE ]] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
    return
  fi
  systemd-inhibit --what=idle --who="mpris-idle-inhibit" \
    --why="Media is playing" --mode=block sleep infinity &
  echo $! >"$PIDFILE"
  disown
}

release() {
  if [[ -f $PIDFILE ]]; then
    kill "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null
    rm -f "$PIDFILE"
  fi
}

# Never leave the inhibitor behind on stop/restart — a stray `sleep infinity`
# under systemd-inhibit would keep the machine awake forever with nothing
# playing and no obvious culprit.
trap 'release; exit 0' TERM INT
trap 'release' EXIT

# ponytail: polls instead of using `playerctl --follow`. --follow tracks one
# player and needs re-plumbing whenever players appear or disappear, while a
# poll answers "is anything playing right now" in one line. The shortest idle
# timeout is 150s, so 15s granularity costs nothing. Switch to --follow only
# if the wakeups ever show up in a power profile.
while true; do
  if playerctl --all-players status 2>/dev/null | grep -qx "Playing"; then
    hold
  else
    release
  fi
  sleep "$INTERVAL"
done
