#!/bin/bash
# Build the PixelPilot_rk Debian package for the VRX (Rockchip arm64) from WSL:
#   bash tools/podman_build_deb.sh [version]      # default version 1.3.0
#
# The upstream recipe (tools/container_build.sh) expects a Debian bookworm
# ARM64 environment: it adds the Radxa rk3566 repos and pulls
# librockchip-mpp-dev, librga-dev and friends, which do not exist for x86.
# So the container is arm64 under qemu - slower, but the same rootfs the
# real build uses, which is what matters for a package that ships to
# hardware.
#
# Two lessons are baked in here, both paid for:
#
#  * FAIL LOUDLY. container_build.sh has no set -e, so when an apt fetch
#    failed once it went on to run dpkg-buildpackage with no build tools,
#    produced nothing, and left the previous run stale .deb sitting there
#    looking current. Every step is checked and a run that produces no
#    fresh package exits non-zero.
#
#  * Fetch over HTTPS. Plain HTTP to deb.debian.org lost the same two
#    packages every single time (libparams-classify-perl,
#    python3-pkg-resources - "Connection failed" against the fastly IPs),
#    which is what killed the tools. But the base image has no CA bundle,
#    so the order matters: HTTP just long enough to install
#    ca-certificates, then switch the sources to HTTPS. Retries and
#    ForceIPv4 on top.
#
# Packages land in $OUT (default: dist/ in this checkout). Always md5-verify a
# package after copying it out of WSL: a 9p copy has corrupted images before.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${OUT:-$SRC/dist}"
VER="${1:-1.3.0}"
IMG="docker.io/library/debian:bookworm"

rm -f "$SRC"/*.deb

echo "== building pixelpilot-rk $VER (emulated arm64: 10-40 min) =="
podman run --rm --platform linux/arm64 \
  -v "$SRC":/usr/src/PixelPilot_rk \
  -w /usr/src/PixelPilot_rk \
  "$IMG" \
  bash -c "set -e
    { echo Acquire::Retries\ 8\;; echo Acquire::ForceIPv4\ true\;; \
      echo Acquire::http::Timeout\ 60\;; } > /etc/apt/apt.conf.d/99net
    apt-get update -qq
    apt-get install -y -qq ca-certificates >/dev/null
    sed -i s#http://deb.debian.org#https://deb.debian.org#g \
        /etc/apt/sources.list.d/debian.sources
    apt-get update -qq
    apt-get install -y -qq curl git devscripts equivs >/dev/null
    command -v mk-build-deps dpkg-buildpackage >/dev/null
    bash tools/container_build.sh \
         --root-dir /usr/src/PixelPilot_rk \
         --build-type deb \
         --pkg-version $VER"

shopt -s nullglob
debs=("$SRC"/*_arm64.deb)
if [ ${#debs[@]} -eq 0 ]; then
  echo "FAILED: no package was produced" >&2
  exit 1
fi
mkdir -p "$OUT"
cp "${debs[@]}" "$OUT"/
echo "== output =="
md5sum "${debs[@]}"
ls -la "$OUT"
