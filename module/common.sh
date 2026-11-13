# Shared by action.sh, service.sh, watch.sh and uninstall.sh. Source with MODDIR set.
#
# While DeX runs on an external monitor, DexController holds a LowRefreshRateToken: a vote at
# priority 24 that caps the built-in screen at 60 Hz. Nothing outside system_server can release
# it, and app or min-limit votes rank lower. SurfaceFlinger's debug call 1035 sets the panel's
# mode directly and makes SurfaceFlinger ignore DisplayManager's policy until the call is made
# again with an invalid mode (release below).
# Adaptive (24-120 Hz) can't work here: with two displays on, SurfaceFlinger only picks a rate
# both can show, and the external monitor offers 60 Hz, so it always lands on 60.
LOG="$MODDIR/refresh120.log"
PIDF=/dev/refresh120.pid
RATE=$(tr -dc 0-9 < "$MODDIR/rate" 2>/dev/null); [ -n "$RATE" ] || RATE=120

log() { echo "$(date '+%m-%d %H:%M:%S') $*" >> "$LOG"; echo "$*"; }

# SurfaceFlinger's physical ID of the built-in panel (the number after "local:" in its uniqueId)
panel_id() { dumpsys display 2>/dev/null | grep -m1 -o 'Built-in Screen": uniqueId="local:[0-9]*' | sed 's/.*local://'; }

# SurfaceFlinger mode ID of the built-in panel's mode at $1 Hz
sf_mode() {
  dumpsys display 2>/dev/null | grep -m1 'DisplayDeviceInfo{"Built-in Screen"' \
    | grep -oE 'sfModeId=[0-9]+, flags=[^,]*, width=[0-9]+, height=[0-9]+, fps=[0-9]+' \
    | grep "fps=$1\$" | head -1 | sed 's/sfModeId=\([0-9]*\).*/\1/'
}

current_rate() { cmd display get-active-mode 0 | grep -o 'Refresh Rate: [0-9]*' | grep -o '[0-9]*$'; }
# A real external monitor (cable, or wireless DeX) attached right now. Only DisplayManager's
# display devices count: a stale desktop display the window manager keeps after an unplug
# (no device behind it) or a virtual display must not turn the override on.
ext_display() { dumpsys display 2>/dev/null | grep 'DisplayDeviceInfo{' | grep -v 'Display device removed' | grep -qE ', type (EXTERNAL|WIFI),'; }
dex_on() { [ "$(settings get system dex_on_external_display 2>/dev/null)" = "1" ] && ext_display; }
screen_on() { dumpsys power 2>/dev/null | grep -q 'mWakefulness=Awake'; }
running() { [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; }

# Sets the built-in panel to $1 Hz through SurfaceFlinger
force() {
  id=$(panel_id); m=$(sf_mode "$1")
  [ -n "$id" ] && [ -n "$m" ] || { log "! built-in screen has no $1 Hz mode"; return 1; }
  service call SurfaceFlinger 1035 i32 "$m" i64 "$id" >/dev/null
}

start() {
  running && return 0
  setsid sh "$MODDIR/watch.sh" < /dev/null > /dev/null 2>&1 &
  sleep 1
}

# Gives the panel back to DisplayManager: clears SurfaceFlinger's override, then briefly changes
# min_refresh_rate (and puts it back) so DisplayManager sends its policy again.
release() {
  id=$(panel_id); [ -n "$id" ] || return 1
  service call SurfaceFlinger 1035 i32 -1 i64 "$id" >/dev/null 2>&1
  old=$(settings get system min_refresh_rate 2>/dev/null)
  settings put system min_refresh_rate 60
  sleep 0.5
  if [ -z "$old" ] || [ "$old" = "null" ]; then settings delete system min_refresh_rate >/dev/null
  else settings put system min_refresh_rate "$old"; fi
}

stop() {
  if running; then kill "$(cat "$PIDF")" 2>/dev/null; rm -f "$PIDF"; fi
  release
  log "- stopped"
}
