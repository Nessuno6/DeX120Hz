#!/system/bin/sh
# Action button: turns the 120 Hz watcher on or off. Works with temporary root (no boot needed).
MODDIR=$(dirname "$(readlink -f "$0")")
. "$MODDIR/common.sh"
if running; then
  stop
  echo "- Off. Refresh rate is back under system control (60 Hz while DeX is on)."
else
  start
  if running; then echo "- On: $RATE Hz on the built-in screen while DeX is on."; else echo "! watcher didn't start, see $LOG"; exit 1; fi
  if dex_on; then sleep 3; echo "- built-in screen now: $(current_rate) Hz"; else echo "- DeX is off right now; it kicks in when DeX starts."; fi
fi
