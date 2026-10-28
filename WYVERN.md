# This fork, for the EMAX Wyvern stack

Integration branch: `vrx-sync-151`, on top of OpenIPC/PixelPilot_rk `master`
(`upstream` remote; level with it on 2026-10-28). The VRX image
(sbc-groundstations `package/pixelpilot/pixelpilot.mk`) pins the commit it
builds.

## What it adds

| Change | Where |
|---|---|
| Eachine Sphere Link buttons: per-button bias / active-low, action buttons, configurable long-press, no Enter on right long-press, left/right repeat in KEYBOARD/EDIT | `src/input.cpp`, `pixelpilot.yaml` |
| Restream auto-start (`restream: enabled: true`) | `src/main.cpp` |
| Low-signal glow driven by RSSI (not received Mbps), aligned with pcpilot's halo | `src/osd.cpp`, `config_osd.json` |
| `GADGET ON` shares the recording line on the OSD | `src/osd.cpp` |
| gsmenu fix (brace-less else-if) | `src/gsmenu/colmenu.c` |
| WSL podman build of the arm64 Debian package | `tools/podman_build_deb.sh` |

Seven files against upstream; everything else is upstream's.
