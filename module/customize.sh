ui_print " "
ui_print "*********************************"
ui_print "  DeX 120 Hz"
ui_print "*********************************"
MODDIR=$MODPATH
. "$MODPATH/common.sh"
if [ -z "$(sf_mode "$RATE")" ]; then
  ui_print "! The built-in screen has no $RATE Hz mode on $(getprop ro.product.model)"
else
  ui_print "- Built-in screen supports $RATE Hz"
fi
set_perm_recursive "$MODPATH" 0 0 0755 0644
for f in action.sh service.sh watch.sh uninstall.sh; do set_perm "$MODPATH/$f" 0 0 0755; done
ui_print "- Tap Action in KernelSU to turn it on (no reboot needed)"
ui_print "- Change the rate by editing $MODPATH/rate (120 or 80)"
