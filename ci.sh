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

# The linter version, owned here and installed from here by the workflow. A
# version pinned only in the workflow is a second copy: this script would accept
# whatever ruff happened to be on PATH, so the same commit could lint clean in
# one place and red in the other. That is the drift this file exists to prevent.
RUFF_VERSION='0.16.6'

if [ "${1:-}" = "--docs-glob" ]; then
    printf '%s\n' "$DOCS_GLOB"
    exit 0
fi

if [ "${1:-}" = "--ruff-version" ]; then
    printf '%s\n' "$RUFF_VERSION"
    exit 0
fi

if [ "${1:-}" = "--docs-mode" ]; then
    # The decision itself, not just the glob it turns on. Callers pipe the
    # changed paths in and run ./ci.sh with whatever comes out, so nobody
    # reimplements the matching. Empty input prints nothing: a change set we
    # cannot see gets the full gate.
    IFS='|' read -r -a globs <<<"$DOCS_GLOB"
    seen=false
    while IFS= read -r path; do
        [ -z "$path" ] && continue
        seen=true
        matched=false
        for g in "${globs[@]}"; do
            # shellcheck disable=SC2053  # $g is a glob here, deliberately
            [[ $path == $g ]] && { matched=true; break; }
        done
        if ! $matched; then
            exit 0
        fi
    done
    if $seen; then
        printf '%s\n' '--docs'
    fi
    exit 0
fi

DOCS_ONLY=false
[ "${1:-}" = "--docs" ] && DOCS_ONLY=true

step() { printf '\n=== %s ===\n' "$1"; }

step "gate wiring"
# Runs in BOTH modes, and before the --docs exit on purpose: this is the check
# that catches the local glob having drifted, and the glob is what decides which
# mode we are in. Behind that exit it could never fire in the mode it guards.
configured=$(git config --get ants.gate.docsGlob 2>/dev/null || true)
if [ -n "$configured" ] && [ "$configured" != "$DOCS_GLOB" ]; then
    echo "ants.gate.docsGlob is '$configured' but ci.sh says '$DOCS_GLOB'" >&2
    echo "re-run: git config ants.gate.docsGlob \"\$(./ci.sh --docs-glob)\"" >&2
    exit 1
fi
echo "docs glob: $DOCS_GLOB"

step "documented flags exist"
# Also runs in both modes. README.md is this project's design contract, so a
# flag it documents and the tool does not accept is a defect in the contract --
# and a commit that breaks it necessarily touches code, which is exactly the
# push a documentation-only check would never see.
help=$(./demoreel record --help; ./demoreel --help)
undocumented=0
for flag in $(grep -oE '`-{1,2}[a-z-]+`' README.md | tr -d '`' | sort -u); do
    # Flags belonging to other programs the caller invokes THROUGH demoreel:
    # flatpak's sockets, and the -geometry demoreel forwards to Xwayland.
    case "$flag" in --socket|--nosocket|--filesystem|-geometry) continue ;; esac
    if ! printf '%s' "$help" | grep -qF -- "$flag"; then
        echo "README documents $flag, which demoreel does not accept" >&2
        undocumented=$((undocumented + 1))
    fi
done
[ "$undocumented" -eq 0 ] || exit 1
echo "every flag README documents is one demoreel accepts"

step "documents are readable"
for f in README.md CLAUDE.md ROADMAP.md CHANGELOG.md SECURITY.md \
         docs/standards/README.md docs/standards/versioning-overrides.md; do
    [ -s "$f" ] || { echo "missing or empty: $f" >&2; exit 1; }
    python3 -c "import sys; open(sys.argv[1], encoding='utf-8').read()" "$f"
done
echo "all present and valid UTF-8"

if $DOCS_ONLY; then
    printf '\n=== documentation checks passed ===\n'
    exit 0
fi

step "required programs"
missing=()
for prog in ruff python3 ffmpeg Xvfb xdotool xclock xterm; do
    command -v "$prog" >/dev/null || missing+=("$prog")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "missing: ${missing[*]}" >&2
    echo "xclock comes from x11-apps and xterm from its own package; the" >&2
    echo "gate uses both as targets. The rest are named in README.md." >&2
    exit 1
fi
actual=$(ruff --version | awk '{print $2}')
if [ "$actual" != "$RUFF_VERSION" ]; then
    echo "ruff $actual is installed but this gate is pinned to $RUFF_VERSION" >&2
    echo "a different linter version is drift: install $RUFF_VERSION, or change" >&2
    echo "RUFF_VERSION in ci.sh and the two will move together." >&2
    exit 1
fi
echo "ruff $actual (pinned)"

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
# demoreel calls a display blank above 0.999, and this is a copy of that test:
# the comparator must match display_is_blank's, or a frame measuring exactly the
# threshold passes the tool and fails the gate. An empty Xvfb measures ~0.9999;
# a window on it drops well below.
if dominant > 0.999:
    sys.exit("the frame is a flat colour -- the app never reached the recording")
print("the app is in the frame")
PY

step "smoke: a blank recording is refused"
# The counterpart to the step above. That one proves a good recording succeeds;
# nothing proved a bad one fails. The behaviour is protected by
# docs/standards/versioning-overrides.md, and CLAUDE.md says not to downgrade it
# to a warning -- someone could, and the gate would have stayed green.
#
# The app maps a window and then kills it while the shell that owns it stays
# alive. That leaves the display blank with the run still going, which is the
# branch that fails; a run whose app exits first skips the check by design.
set +e
# shellcheck disable=SC2016  # $! and $p belong to the inner sh, not to us
blank_out=$(./demoreel record -o "$tmp/blank.mp4" -d 4 -s 640x480 \
    -- sh -c 'xclock & p=$!; sleep 1; kill $p; sleep 10' 2>"$tmp/blank.err")
blank_status=$?
set -e
[ "$blank_status" -ne 0 ] || { echo "a blank recording exited 0" >&2; exit 1; }
# The reason matters: a run that failed for some other cause is not this check
# passing. Any exit is non-zero, but only one of them is the guard firing.
grep -q 'stayed blank' "$tmp/blank.err" || {
    echo "the run failed, but not on the blank-display guard:" >&2
    cat "$tmp/blank.err" >&2
    exit 1
}
[ -z "$blank_out" ] || { echo "a failed run printed '$blank_out' on stdout" >&2; exit 1; }
# Protected by the versioning overrides: the video already written stays.
[ -s "$tmp/blank.mp4" ] || { echo "the partial video was not left on disk" >&2; exit 1; }
echo "a blank recording exits non-zero, prints no path, and leaves its file"

step "scripted actions reach the app"
# The sharpest gap the gate had: a scripted click or keystroke that quietly
# stops landing still produces a valid-looking video of an app sitting there
# doing nothing. That is the same silent failure the blank check exists to
# catch, one level up, and no video inspection finds it.
#
# xterm runs a shell that reads one line and writes it to a file, so the app
# itself reports what arrived. wait, type and key are all exercised; move and
# click are not, because neither xclock nor xterm reports a click anywhere this
# script can read.
typed="hello from the gate"
./demoreel record -o "$tmp/actions.mp4" -d 12 -s 640x480 \
    -a 'wait 2' -a "type $typed" -a 'key Return' \
    -- xterm -e sh -c "read line; printf '%s' \"\$line\" > $tmp/typed.txt" >/dev/null
got=$(cat "$tmp/typed.txt" 2>/dev/null || true)
[ "$got" = "$typed" ] || {
    echo "the app received '$got', not '$typed' -- scripted actions did not land" >&2
    exit 1
}
echo "wait, type and key all reached the app"

step "stop ends a run started with -d 0"
# record -d 0 runs until told to stop, and stop is the only way to end it. It
# is documented, and nothing proved either half worked.
./demoreel record -o "$tmp/stopped.mp4" -d 0 -n gatestop -s 640x480 \
    --app-log "$tmp/app.log" -- xclock >/dev/null 2>&1 &
recorder=$!
# Retry rather than waiting on the video file. A run becomes addressable when it
# writes its state file, and that happens after ffmpeg starts -- so the .mp4
# exists a moment before stop can find the run by name.
stopped=""
for _ in $(seq 1 100); do
    if stopped=$(./demoreel stop gatestop 2>/dev/null); then break; fi
    sleep 0.2
done
[ -n "$stopped" ] || { echo "stop never found the running recording" >&2; exit 1; }
[ "$stopped" = "$tmp/stopped.mp4" ] || {
    echo "stop printed '$stopped', not the output path" >&2; exit 1; }
wait "$recorder" || { echo "the stopped run exited non-zero" >&2; exit 1; }
[ -s "$tmp/stopped.mp4" ] || { echo "stop left no video" >&2; exit 1; }
# --app-log rode along: same run, and it is documented too.
[ -f "$tmp/app.log" ] || { echo "--app-log wrote no file" >&2; exit 1; }
echo "stop ended the run, and --app-log wrote its file"

step "default output name"
# -o is optional; without it the file is named from the app and a timestamp.
( cd "$tmp" && "$OLDPWD/demoreel" record -d 3 -s 640x480 -- xclock >/dev/null )
ls "$tmp"/xclock-*.mp4 >/dev/null

printf '\n=== all checks passed ===\n'
