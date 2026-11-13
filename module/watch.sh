#!/system/bin/sh
# Re-applies the rate every 3 s while DeX is on and the screen is awake.
MODDIR=$(dirname "$(readlink -f "$0")")
. "$MODDIR/common.sh"
echo $$ > "$PIDF"
# Only remove the PID file if it is still ours: a stop is handled after the current sleep,
# by which time a quick re-toggle may already have started a new watcher.
trap '[ "$(cat "$PIDF" 2>/dev/null)" = "$$" ] && rm -f "$PIDF"; exit 0' TERM INT
log "- watcher started: $RATE Hz on the built-in screen while DeX is on"
forced=0; fails=0
while :; do
  if dex_on && screen_on; then
    r=$(current_rate)
    if [ "$r" != "$RATE" ]; then
      if force "$RATE"; then
        [ $forced = 1 ] || log "- DeX on: built-in screen $r -> $RATE Hz"
        forced=1; fails=0
      else
        fails=$((fails + 1))
        [ $fails -ge 5 ] && { log "! giving up after 5 failures"; rm -f "$PIDF"; exit 1; }
      fi
    fi
  elif [ $forced = 1 ] && ! dex_on; then
    release; log "- DeX off: Motion smoothness setting applies again"; forced=0
  fi
  sleep 3
done
