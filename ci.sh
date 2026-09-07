#!/usr/bin/env bash
# The whole CI gate for demoreel.
#
# .github/workflows/ci.yml runs this script and nothing else, so a local run and
# a GitHub run cannot drift apart. Add a check here, never in the workflow.
#
# Run it by hand any time: ./ci.sh
set -euo pipefail
cd "$(dirname "$0")"

step() { printf '\n=== %s ===\n' "$1"; }

step "required programs"
missing=()
for prog in ruff python3 ffmpeg Xvfb xdotool xclock; do
    command -v "$prog" >/dev/null || missing+=("$prog")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "missing: ${missing[*]}" >&2
    echo "xclock comes from x11-apps; the rest are named in README.md." >&2
    exit 1
fi
ruff --version

step "lint"
ruff check .

step "parse"
python3 -c 'import ast, pathlib; ast.parse(pathlib.Path("demoreel").read_text())'
echo "demoreel parses"

step "smoke: record an app and prove it reached the frame"
# The check that matters. A valid video file proves nothing on its own -- a
# black recording passes every other test, so sample a frame and measure it.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

out=$(./demoreel record -o "$tmp/smoke.mp4" -d 5 -s 640x480 -- xclock)
[ -s "$out" ] || { echo "no video written" >&2; exit 1; }
echo "wrote $out"

ffmpeg -v error -i "$out" -vf 'select=eq(n\,60)' -vframes 1 "$tmp/frame.png" -y
python3 - "$tmp/frame.png" <<'PY'
import collections, subprocess, sys
raw = subprocess.run(
    ["ffmpeg", "-v", "error", "-i", sys.argv[1], "-f", "rawvideo", "-pix_fmt", "gray", "-"],
    capture_output=True, check=True).stdout
if not raw:
    sys.exit("could not decode the sampled frame")
dominant = collections.Counter(raw).most_common(1)[0][1] / len(raw)
print(f"dominant grey level: {dominant:.4f}")
# demoreel calls a display blank above 0.999. An empty Xvfb measures ~0.9999;
# a window on it drops well below. Anything at or above the threshold here means
# the app never reached the picture.
if dominant >= 0.999:
    sys.exit("the frame is a flat colour -- the app never reached the recording")
print("the app is in the frame")
PY

step "default output name"
# -o is optional; without it the file is named from the app and a timestamp.
( cd "$tmp" && "$OLDPWD/demoreel" record -d 3 -s 640x480 -- xclock >/dev/null )
ls "$tmp"/xclock-*.mp4 >/dev/null

printf '\n=== all checks passed ===\n'
