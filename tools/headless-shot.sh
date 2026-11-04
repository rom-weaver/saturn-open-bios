# SPDX-License-Identifier: GPL-2.0-or-later
# Shared by run-yabause.sh and run-mednafen.sh (sourced, not run): start an
# emulator under a virtual display, take a screenshot after $WAIT seconds
# and save it as a PNG. The caller sets ROOT, calls shot_init "$@", adjusts
# DISC and BIOS if needed, then calls shot_run.

# shot_init [disc image] [out.png]: defaults, and a temp dir ($TMP) that is
# removed on exit and on Ctrl-C.
shot_init() {
  DISC=${1:-$ROOT/build/testdisc.iso}
  OUT=${2:-$ROOT/build/screen.png}
  WAIT=${WAIT:-12}
  BIOS=${BIOS:-$ROOT/build/saturn-open-bios.bin}
  test -f "$DISC" || { echo "no disc image: $DISC" >&2; exit 1; }
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  trap 'exit 1' INT TERM HUP
}

# shot_run SCREEN CLASS CROP COMMAND: run COMMAND (sh syntax; DISC, BIOS and
# TMP are exported) on an Xvfb screen of size SCREEN (WxHxD). Capture the
# window of X class CLASS, or the whole screen when CLASS is empty, then
# crop to CROP (a convert geometry) unless it is empty. Fails with the
# emulator's last log lines when it has already quit.
shot_run() {
  SHOT_CLASS=$2 SHOT_CMD=$4
  export DISC BIOS TMP SHOT_CLASS SHOT_CMD
  timeout $((WAIT + 28)) xvfb-run -a -s "-screen 0 $1" sh -c '
    sh -c "exec $SHOT_CMD" >"$TMP/log" 2>&1 &
    sleep '"$WAIT"'
    kill -0 $! 2>/dev/null || { tail -5 "$TMP/log" >&2; exit 1; }
    if [ -n "$SHOT_CLASS" ]; then
      xwd -id "$(xdotool search --class "$SHOT_CLASS" | head -1)" -silent >"$TMP/shot.xwd"
    else
      xwd -root -silent >"$TMP/shot.xwd"
    fi
    # Stop it and wait until it has (Mednafen writes saves while it quits);
    # Yabause ignores SIGTERM, so kill it after 5 s
    kill $! 2>/dev/null
    for i in 1 2 3 4 5; do kill -0 $! 2>/dev/null || break; sleep 1; done
    kill -9 $! 2>/dev/null; wait $! 2>/dev/null || true'
  if [ -n "$3" ]; then
    convert "$TMP/shot.xwd" -crop "$3" +repage "$OUT"
  else
    convert "$TMP/shot.xwd" "$OUT"
  fi
  echo "screenshot: $OUT"
  convert "$OUT" -format "%c" histogram:info:- | sort -rn | head -3
}
