#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Boot the BIOS ($BIOS, default build/saturn-open-bios.bin) in Mednafen under a
# virtual display and save a screenshot.
# Usage: tools/run-mednafen.sh [disc image (.cue/.iso)] [out.png]
#        WAIT=seconds before the screenshot (default 12)
# Needs mednafen (1.29 or newer), xvfb, x11-apps, xdotool, imagemagick.
# -ss.bios_sanity 0: Mednafen would otherwise hash-check BIOS files named
# like Sega's (sega_101.bin, mpr-17933.bin, ...) and reject this one.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/tools/headless-shot.sh"
shot_init "$@"
DISC=$(cd "$(dirname "$DISC")" && pwd)/$(basename "$DISC")
BIOS=$(cd "$(dirname "$BIOS")" && pwd)/$(basename "$BIOS")
# Mednafen needs a cue sheet for a plain .iso
case $DISC in
*.[iI][sS][oO])
  printf 'FILE "%s" BINARY\n  TRACK 01 MODE1/2048\n    INDEX 01 00:00:00\n' "$DISC" >"$TMP/disc.cue"
  DISC=$TMP/disc.cue ;;
esac
# A fresh Mednafen home per run: no saves or settings carried over
mkdir "$TMP/home"
# Mednafen centres its window (906x720 NTSC, 1095x768 PAL at the default
# 3x scale): capture the window itself, on a screen both fit on
shot_run 1280x800x24 mednafen "" 'env MEDNAFEN_HOME="$TMP/home" mednafen \
  -force_module ss -filesys.untrusted_fip_check 0 -ss.bios_sanity 0 \
  -ss.bios_jp "$BIOS" -ss.bios_na_eu "$BIOS" -ss.cart auto -sound 0 \
  -video.fs 0 "$DISC"'
