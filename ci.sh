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

# The one definition of what counts as documentation here. The machine-wide
# pre-push hook reads it with `./ci.sh --docs-glob` and does its own matching.
# The GitHub workflow does not: it pipes the changed paths into
# `./ci.sh --docs-mode` below, so the decision has one home as well as its
# value.
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
for prog in ruff python3 ffmpeg Xvfb xauth xdotool xclock xterm; do
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

step "the virtual display refuses a client with no cookie"
# The display is private or the tool has no point. Measured before this guard
# existed: a client with no credential at all read the geometry and grabbed a
# frame of whatever was on screen. Socket permissions cannot fix it, because
# Xvfb also listens on an abstract socket, which has none.
./demoreel record -o "$tmp/cookie.mp4" -d 0 -n gatecookie -s 640x480 \
    -- xclock >/dev/null 2>"$tmp/cookie.err" &
cookie_rec=$!
disp=""
for _ in $(seq 1 100); do
    # sed, not grep: this script runs under pipefail, and grep exits 1 when it
    # matches nothing, which kills the run silently while we are still waiting
    # for the line to appear. sed exits 0 either way.
    disp=$(sed -n 's/.*recording \(:[0-9][0-9]*\).*/\1/p' "$tmp/cookie.err" | head -1)
    [ -n "$disp" ] && break
    sleep 0.2
done
if [ -z "$disp" ]; then
    # Stop the run before failing, or it outlives the gate holding a display,
    # and the next run refuses the name it is still using.
    ./demoreel stop gatecookie >/dev/null 2>&1 || kill "$cookie_rec" 2>/dev/null || true
    echo "the run never reported its display:" >&2
    cat "$tmp/cookie.err" >&2
    exit 1
fi
set +e
XAUTHORITY=/dev/null DISPLAY="$disp" xdotool getdisplaygeometry >/dev/null 2>&1
uncredentialed=$?
set -e
./demoreel stop gatecookie >/dev/null
wait "$cookie_rec" || true
[ "$uncredentialed" -ne 0 ] || {
    echo "a client with no cookie read $disp -- the display is not private" >&2
    exit 1
}
echo "a client with no cookie cannot reach the display"

step "a Flatpak target missing its flags is warned about"
# Without the flags a Flatpak renders on the real compositor and the run fails
# the blank check with a message naming two possible causes. Saying which one it
# is costs nothing and saves the recording.
#
# A stub named flatpak stands in for the real one: what is under test is the
# reading of the caller's command line, not flatpak itself, and the stub keeps
# the step working on a runner with no Flatpak installed.
mkdir -p "$tmp/bin"
printf '#!/bin/sh\nexec xclock\n' > "$tmp/bin/flatpak"
chmod +x "$tmp/bin/flatpak"
PATH="$tmp/bin:$PATH" ./demoreel record -o "$tmp/fp.mp4" -d 3 -s 640x480 \
    -- flatpak run org.example.App >/dev/null 2>"$tmp/fp.err"
grep -q -- '--nosocket=wayland' "$tmp/fp.err" || {
    echo "an under-flagged Flatpak target drew no warning:" >&2
    cat "$tmp/fp.err" >&2
    exit 1
}
# And a fully-flagged one must stay quiet, or the warning is noise.
PATH="$tmp/bin:$PATH" ./demoreel record -o "$tmp/fp-ok.mp4" -d 3 -s 640x480 \
    -- flatpak run --socket=x11 --nosocket=wayland --filesystem=/tmp/.X11-unix \
    org.example.App >/dev/null 2>"$tmp/fp-ok.err"
! grep -q 'is missing' "$tmp/fp-ok.err" || {
    echo "a correctly-flagged Flatpak target was warned about anyway" >&2
    exit 1
}
echo "the missing flags are named, and a complete command is left alone"

step "the state directory must be one we own"
# The run-state directory's name is predictable, so on a shared machine another
# user can create it first and demoreel would adopt it. The check is exercised
# inside $tmp with XDG_RUNTIME_DIR pointed at it, so nothing outside this run's
# own scratch directory is touched -- planting the real name under /tmp would
# collide with any other recording on the machine.
mkdir -p "$tmp/fakerun"
ln -s /tmp "$tmp/fakerun/demoreel-$(id -u)"
set +e
XDG_RUNTIME_DIR="$tmp/fakerun" ./demoreel record -o "$tmp/planted.mp4" \
    -d 3 -s 640x480 -- xclock >"$tmp/planted.out" 2>"$tmp/planted.err"
planted_status=$?
set -e
[ "$planted_status" -ne 0 ] || { echo "demoreel used a planted symlink" >&2; exit 1; }
grep -q 'not a directory you own' "$tmp/planted.err" || {
    echo "the run failed, but not on the state-directory guard:" >&2
    cat "$tmp/planted.err" >&2
    exit 1
}
echo "a state directory we do not own is refused"

step "default output name"
# -o is optional; without it the file is named from the app and a timestamp.
( cd "$tmp" && "$OLDPWD/demoreel" record -d 3 -s 640x480 -- xclock >/dev/null )
ls "$tmp"/xclock-*.mp4 >/dev/null

printf '\n=== all checks passed ===\n'
