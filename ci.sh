#!/usr/bin/env bash
# The whole CI gate for demoreel.
#
# .github/workflows/ci.yml runs this script and nothing else, so a local run and
# a GitHub run cannot drift apart. Add a check here, never in the workflow.
#
# Run it by hand any time: ./ci.sh
#
# ./ci.sh --docs runs the documentation checks only. The pre-push hook selects
# it on a documentation-only push; it is not a skip, and it is not for you to
# pass by hand to get past a red gate.
set -euo pipefail
cd "$(dirname "$0")"

# The one definition of what counts as documentation here. The pre-push hook
# and the GitHub workflow both classify a push against THIS value, so there is
# no second copy to drift: `./ci.sh --docs-glob` is what each of them reads.
DOCS_GLOB='docs/*|*.md|LICENSE|.github/FUNDING.yml'

if [ "${1:-}" = "--docs-glob" ]; then
    printf '%s\n' "$DOCS_GLOB"
    exit 0
fi

DOCS_ONLY=false
[ "${1:-}" = "--docs" ] && DOCS_ONLY=true

step() { printf '\n=== %s ===\n' "$1"; }

if $DOCS_ONLY; then
    step "documented flags exist"
    # README.md is this project's design contract, so a flag it documents and
    # the tool does not have is a defect in the contract.
    help=$(./demoreel record --help; ./demoreel --help)
    undocumented=0
    for flag in $(grep -oE '`--[a-z-]+`' README.md | tr -d '`' | sort -u); do
        case "$flag" in --socket|--nosocket|--filesystem|--version) continue ;; esac
        if ! printf '%s' "$help" | grep -qF -- "$flag"; then
            echo "README documents $flag, which demoreel does not accept" >&2
            undocumented=$((undocumented + 1))
        fi
    done
    [ "$undocumented" -eq 0 ] || exit 1
    echo "every flag README documents is one demoreel accepts"

    step "roadmap and standards are readable"
    for f in README.md CLAUDE.md ROADMAP.md docs/standards/versioning-overrides.md; do
        [ -s "$f" ] || { echo "missing or empty: $f" >&2; exit 1; }
        python3 -c "import sys; open(sys.argv[1], encoding='utf-8').read()" "$f"
    done
    echo "all present and valid UTF-8"

    printf '\n=== documentation checks passed ===\n'
    exit 0
fi

step "gate wiring"
# The local hook reads this from git config. If that copy has drifted from the
# definition above, a documentation-only push is classified differently here
# and on GitHub -- which is the one thing this script exists to prevent.
configured=$(git config --get ants.gate.docsGlob 2>/dev/null || true)
if [ -n "$configured" ] && [ "$configured" != "$DOCS_GLOB" ]; then
    echo "ants.gate.docsGlob is '$configured' but ci.sh says '$DOCS_GLOB'" >&2
    echo "re-run: git config ants.gate.docsGlob \"\$(./ci.sh --docs-glob)\"" >&2
    exit 1
fi
echo "docs glob: $DOCS_GLOB"

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
