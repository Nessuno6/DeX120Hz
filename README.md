# DeX 120 Hz

A KernelSU / Magisk module that keeps a Samsung device's built-in screen at **120 Hz** while
DeX runs on an external monitor. DeX normally caps the built-in screen at 60 Hz and hides the
Motion smoothness setting while it's connected. Nothing on `/system` is written.

## How it works

While DeX is on an external display, DeX's controller holds a low-refresh-rate vote that caps
the built-in screen at 60 Hz. Nothing outside `system_server` can release it, and app or
minimum-rate votes rank lower. Instead, the module sets the panel's mode directly through
SurfaceFlinger (`service call SurfaceFlinger 1035`), which makes SurfaceFlinger ignore the
display manager's policy until the call is made again with an invalid mode.

A small watcher checks every 3 seconds. It acts only while DeX is on, a real external display
(cable or wireless DeX) is connected, and the screen is awake. When DeX ends, it hands the
refresh rate back to the system, so your Motion smoothness setting applies again.

Adaptive refresh (24–120 Hz) can't work in this state: with two displays on, SurfaceFlinger
only picks a rate both can show, so it always lands on 60. The module therefore holds a
fixed rate.

## Install

Needs root (KernelSU or Magisk) and a built-in screen with a 120 Hz mode.

1. Download `DeX120Hz_vX.Y.zip` from the
   [latest release](https://github.com/Nessuno6/DeX120Hz/releases/latest) and install it in
   KernelSU or Magisk.
2. Tap the module's **Action** button in KernelSU to turn it on (no reboot needed), or reboot:
   it starts at boot when root is active then.

Tap **Action** again to turn it off. The log is `refresh120.log` in the module's folder.

## Settings

The rate is in the module's `rate` file: `120` (default) or `80`, or any other mode the
built-in screen has.

## Updates

`module.prop` points KernelSU / Magisk to [`update.json`](update.json), so the manager offers
new versions in its module list.

## Build

```bash
bash release.sh            # dist/DeX120Hz_vX.Y.zip + update.json
bash release.sh --publish  # also creates the GitHub release; then commit update.json
```

The version comes from the first `## vX.Y` heading in [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE).
