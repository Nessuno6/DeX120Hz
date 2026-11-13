#!/system/bin/sh
# Only runs if root is active at boot; with temporary root use the Action button instead.
MODDIR=$(dirname "$(readlink -f "$0")")
. "$MODDIR/common.sh"
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 5; done
sleep 15
start
