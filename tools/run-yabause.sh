#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Boot the BIOS ($BIOS, default build/saturn-open-bios.bin) in Yabause under a
# virtual display and save a screenshot.
# Usage: tools/run-yabause.sh [disc image (.iso/.cue)] [out.png]
#        WAIT=seconds before the screenshot (default 12)
# Needs yabause, xvfb, x11-apps, imagemagick.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/tools/headless-shot.sh"
shot_init "$@"
# The window sits at the top left; the crop drops its menu bar
shot_run 800x600x24 "" 640x426+0+54 'yabause -a -ns -b "$BIOS" -i "$DISC"'
