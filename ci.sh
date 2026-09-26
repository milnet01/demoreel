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
RUFF_VERSION='0.16.8'

if [ "${1:-}" = "--docs-glob" ]; then
    printf '%s\n' "$DOCS_GLOB"
    exit 0
fi

if [ "${1:-}" = "--ruff-version" ]; then
    printf '%s\n' "$RUFF_VERSION"
    exit 0
fi

if [ "${1:-}" = "--version-lockstep" ]; then
    # The post_check for .claude/bump.json, run after a version bump: every
    # place the version is written has to say the same thing. Same shape as
    # --ruff-version and --docs-glob above -- the caller asks this script
    # rather than restating what it would have to keep in step by hand.
    tool=$(sed -n 's/^__version__ = "\(.*\)"$/\1/p' demoreel)
    # The newest DATED section. `[Unreleased]` cannot match: the pattern needs
    # a digit first, and that is what keeps this from passing on an uncut
    # changelog.
    notes=$(sed -n 's/^## \[\([0-9][^]]*\)\].*/\1/p' CHANGELOG.md | head -1)
    if [ -z "$tool" ]; then
        echo "could not read __version__ from demoreel" >&2
        exit 1
    fi
    if [ "$tool" != "$notes" ]; then
        echo "version drift: demoreel says '$tool', CHANGELOG's newest" >&2
        echo "dated section says '${notes:-<none>}'" >&2
        exit 1
    fi
    printf 'version lockstep: %s\n' "$tool"
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
help=$(./demoreel record --help; ./demoreel shot --help; ./demoreel stop --help;
      ./demoreel --help)
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

# DEMO-0044. And the other direction, which is where the drift actually was:
# six long forms were accepted and written down nowhere. The command line is a
# protected surface (docs/standards/versioning-overrides.md), so a spelling
# nobody documented is still one a caller's script can depend on, and still a
# break to remove -- a break nobody could have seen coming from the contract.
#
# -h and --help are argparse's own, added to every parser whether we ask or not.
unmentioned=0
for flag in $(printf '%s' "$help" | grep -oE '(^|[ ,])--?[a-z][a-z-]+' \
              | tr -d ' ,' | sort -u); do
    case "$flag" in -h|--help) continue ;; esac
    # Not grep -F: a bare `-o` matches inside a word, so the check would pass
    # on any README that happens to contain "read-only".
    grep -qE -- "(^|[^A-Za-z0-9_-])$flag([^A-Za-z0-9_-]|\$)" README.md || {
        echo "demoreel accepts $flag, which README.md never mentions" >&2
        unmentioned=$((unmentioned + 1))
    }
done
[ "$unmentioned" -eq 0 ] || exit 1
echo "every flag demoreel accepts is one README mentions"

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
for prog in ruff python3 ffmpeg Xvfb xauth xdotool xclock xterm xprop; do
    command -v "$prog" >/dev/null || missing+=("$prog")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "missing: ${missing[*]}" >&2
    echo "xclock comes from x11-apps, xterm from its own package and xprop" >&2
    echo "from x11-utils; the gate uses them to build its targets. The rest" >&2
    echo "are named in README.md." >&2
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
# The tree AND the source file by name. `ruff check .` alone selects nothing
# here: the file is called `demoreel` with no extension, and ruff's default
# include list is *.py -- so for the whole history before this line the gate
# reported "All checks passed!" about a config file. Naming the tree as well
# keeps any *.py added later covered without a second edit.
ruff check . demoreel
# Prove ruff opened the source rather than trusting that it did. Without this
# the hollow gate is one rename away from coming back, and it comes back green.
selected=$(ruff check --show-files . demoreel)
if [[ $'\n'$selected$'\n' != *$'\n'$PWD/demoreel$'\n'* ]]; then
    echo "ruff did not select demoreel, so the lint step checked nothing." >&2
    echo "it selected:" >&2
    printf '%s\n' "$selected" >&2
    exit 1
fi
echo "ruff analysed demoreel"

step "parse"
python3 -c 'import ast, pathlib; ast.parse(pathlib.Path("demoreel").read_text())'
echo "demoreel parses"

step "smoke: record an app and prove it reached the frame"
# The check that matters. A valid video file proves nothing on its own -- a
# black recording passes every other test, so sample a frame and measure it.
tmp=$(mktemp -d)

# One teardown for the whole gate, not one per step.
#
# A -d 0 recording never ends by itself, so a step that fails between starting
# one and stopping it leaves the recorder alive. The next run then refuses that
# name, and the failure it reports is the leftover rather than the defect --
# measured during development, at a cost of two cycles to recognise. Per-step
# cleanup does not cover it: the branch most likely to fire is the assertion
# that gives up on finding the run, and that is before the step's own stop.
#
# Each step that launches a recorder appends its pid here. demoreel handles
# SIGTERM by finishing the video and running its own cleanup, so a leftover
# ends the same way `demoreel stop` would end it -- including the window before
# the run has written its state file, where stopping it by name cannot work.
gate_pids=""
cleanup() {
    for pid in $gate_pids; do
        kill "$pid" 2>/dev/null || true
    done
    # Give each one a bounded chance to run its own teardown, which is what
    # takes its Xvfb down with it.
    for pid in $gate_pids; do
        for _ in $(seq 1 50); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
        done
        kill -KILL "$pid" 2>/dev/null || true
    done
    # Then sweep. A recorder signalled before it installed its handlers dies
    # without tearing anything down, and a leaked Xvfb holds its display number
    # and poisons the pool for later runs.
    #
    # Match on the auth file, which carries the run's name, and only for the
    # gate's own `gate*` runs. Two sessions may record at once, so killing
    # every Xvfb this user owns would end someone else's recording. Never
    # widen this to the process name.
    for xv in $(pgrep -u "$(id -u)" -x Xvfb 2>/dev/null); do
        if tr '\0' ' ' < "/proc/$xv/cmdline" 2>/dev/null \
           | grep -q "demoreel-$(id -u)/gate"; then
            kill "$xv" 2>/dev/null || true
        fi
    done
    rm -rf "$tmp"
}
trap cleanup EXIT

# One definition of "sample a frame and prove something was drawn in it", used
# by every step that records something: this smoke test, the --gpu backend and
# the real Flatpak target. The threshold and its comparator still live in
# demoreel; this decides which frame to look at and what to say when it is flat.
assert_frame_drawn() {
    local video=$1 frame=$2 what=$3
    ffmpeg -v error -i "$video" -vf "select=eq(n\\,$frame)" -vframes 1 \
        "$tmp/sample.png" -y
    python3 - "$tmp/sample.png" "$what" <<'PY'
import importlib.machinery, importlib.util, subprocess, sys

# Ask the tool rather than restating its test. The threshold and its comparator
# both live in demoreel, so there is nothing here to keep in step -- the same
# answer this project reached for `ci.sh --ruff-version` and `--docs-glob`,
# pointing the other way. demoreel has no .py extension, so it is loaded by
# path; everything at its module level is imports and constants, and main() is
# behind an __name__ guard, so importing it runs nothing.
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)

raw = subprocess.run(
    ["ffmpeg", "-v", "error", "-i", sys.argv[1], "-f", "rawvideo", "-pix_fmt", "gray", "-"],
    capture_output=True, check=True).stdout
if not raw:
    sys.exit("could not decode the sampled frame")
print(f"dominant grey level: {demoreel.dominant_fraction(raw):.4f}"
      f" (blank above {demoreel.BLANK_THRESHOLD})")
if demoreel.frame_is_flat(raw):
    sys.exit(f"the frame is a flat colour -- {sys.argv[2]}")
PY
}

out=$(./demoreel record -o "$tmp/smoke.mp4" -d 5 -s 640x480 -- xclock)
[ -s "$out" ] || { echo "no video written" >&2; exit 1; }
echo "wrote $out"

# -d means what it says (DEMO-0012). Blind sleeps and a sample taken while
# still recording made -d 5 a 6.17 second video; it measures 5.2 now. The
# 0.5 upper bound is room for that remainder, not for the old overshoot.
length=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out")
python3 -c 'import sys; n = float(sys.argv[1]); sys.exit(not 5.0 <= n <= 5.5)' "$length" || {
    echo "-d 5 produced a ${length}s video" >&2; exit 1; }
echo "-d 5 produced ${length}s"

assert_frame_drawn "$out" 60 "the app never reached the recording"
echo "the app is in the frame"

step "smoke: a blank recording is refused"
# The counterpart to the step above. That one proves a good recording succeeds;
# nothing proved a bad one fails. The behaviour is protected by
# docs/standards/versioning-overrides.md, and CLAUDE.md says not to downgrade it
# to a warning -- someone could, and the gate would have stayed green.
#
# The app maps a window and then kills it while the shell that owns it stays
# alive. That leaves the display blank with the run still going, which is the
# branch that fails; a run whose app exits first skips the check by design.
#
# The kill comes AFTER the halfway sample and before the end, so this is the
# end-of-run check alone. With -d 6 the halfway look lands about 3.5s in and
# the end about 6.5s in, a second and a half either side of the kill at 5s.
set +e
# shellcheck disable=SC2016  # $! and $p belong to the inner sh, not to us
blank_out=$(./demoreel record -o "$tmp/blank.mp4" -d 6 -s 640x480 \
    -- sh -c 'xclock & p=$!; sleep 5; kill $p; sleep 10' 2>"$tmp/blank.err")
blank_status=$?
set -e
[ "$blank_status" -ne 0 ] || { echo "a blank recording exited 0" >&2; exit 1; }
# The reason matters: a run that failed for some other cause is not this check
# passing. Any exit is non-zero, but only one of them is the guard firing.
grep -q 'was blank at the end' "$tmp/blank.err" || {
    echo "the run failed, but not on the end-of-run blank check:" >&2
    cat "$tmp/blank.err" >&2
    exit 1
}
[ -z "$blank_out" ] || { echo "a failed run printed '$blank_out' on stdout" >&2; exit 1; }
# Protected by the versioning overrides: the video already written stays.
[ -s "$tmp/blank.mp4" ] || { echo "the partial video was not left on disk" >&2; exit 1; }
echo "a blank recording exits non-zero, prints no path, and leaves its file"

step "a recording blank until its second half is refused"
# DEMO-0008. The end sample alone passed an app that drew only in the final
# moments, handing back a video mostly empty. The window goes away at 1s and
# comes back at 7s; with -d 8 the halfway look lands about 4.5s in, and the
# end about 8.5s in with the clock drawn again -- so only the halfway sample
# can fail this run. 0.1.1 returns it with exit 0.
set +e
# shellcheck disable=SC2016  # $! and $p belong to the inner sh, not to us
late_out=$(./demoreel record -o "$tmp/late.mp4" -d 8 -s 640x480 \
    -- sh -c 'xclock & p=$!; sleep 1; kill $p; sleep 6; exec xclock' 2>"$tmp/late.err")
late_status=$?
set -e
[ "$late_status" -ne 0 ] || { echo "a recording blank until its second half exited 0" >&2; exit 1; }
grep -q 'was blank halfway' "$tmp/late.err" || {
    echo "the run failed, but not on the halfway blank check:" >&2
    cat "$tmp/late.err" >&2
    exit 1
}
[ -z "$late_out" ] || { echo "a failed run printed '$late_out' on stdout" >&2; exit 1; }
echo "a recording blank at halfway fails there"

step "the blank check says when it could not look"
# DEMO-0033. A failed sample used to read as "not blank", which is the success
# path, so the guard passed everything the moment its own measurement broke.
# The realistic way it breaks is the run's environment losing the display's
# cookie, so that is the case exercised: a real, empty display, sampled once
# with the cookie and once without. The first must be blank; the second must
# raise rather than answer.
python3 - <<'SAMPLEPY'
import importlib.machinery, importlib.util, os

loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)

# The name starts with "gate" so the teardown's Xvfb sweep covers it.
displaylog = demoreel.state_dir() / "gatesample.display.log"
proc, display, auth = demoreel.start_xvfb(320, 240, "gatesample", displaylog)
try:
    env = dict(os.environ, DISPLAY=display, XAUTHORITY=str(auth))
    if demoreel.display_is_blank(env, display, 320, 240) is not True:
        raise SystemExit("an empty display did not measure as blank")
    try:
        demoreel.display_is_blank(dict(env, XAUTHORITY="/dev/null"),
                                  display, 320, 240)
    except demoreel.SampleError as exc:
        print(f"could not tell, and said why: {str(exc).splitlines()[0]}")
    else:
        raise SystemExit("a display it could not sample was given a verdict")
finally:
    proc.kill()
    proc.wait()
    auth.unlink(missing_ok=True)
    displaylog.unlink(missing_ok=True)
SAMPLEPY

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
# The text carries both quote marks, an apostrophe and a double space, because
# `type` types the rest of its step exactly. Splitting it like a shell command
# dropped the quotes, collapsed the spaces and died on the apostrophe
# (DEMO-0101).
typed="it's \"quoted\" 'twice'  here"
./demoreel record -o "$tmp/actions.mp4" -d 12 -s 640x480 \
    -a 'wait 2' -a "type $typed" -a 'key Return' \
    -- xterm -e sh -c "read line; printf '%s' \"\$line\" > $tmp/typed.txt" >/dev/null
got=$(cat "$tmp/typed.txt" 2>/dev/null || true)
[ "$got" = "$typed" ] || {
    echo "the app received '$got', not '$typed' -- scripted actions did not land" >&2
    exit 1
}
echo "wait, type and key all reached the app"

step "a window titled only by _NET_WM_NAME is found"
# DEMO-0043. The window search read only the old WM_NAME, so an app setting
# nothing but _NET_WM_NAME -- vkcube is one -- was never found: every run
# waited out the startup timeout and recorded the window unresized. This
# builds such a window without needing Vulkan: an xterm with an empty title,
# whose own shell then sets _NET_WM_NAME. 0.1.1 says "no window appeared".
# shellcheck disable=SC2016  # $WINDOWID belongs to xterm's shell, not to us
./demoreel record -o "$tmp/netwm.mp4" -d 2 -s 640x480 --startup-timeout 5 \
    -- xterm -T '' -e sh -c \
    'xprop -id "$WINDOWID" -f _NET_WM_NAME 8u -set _NET_WM_NAME gatewin; sleep 30' \
    >/dev/null 2>"$tmp/netwm.err"
if grep -q 'no window appeared' "$tmp/netwm.err"; then
    echo "a window titled only by _NET_WM_NAME was not found" >&2
    exit 1
fi
echo "found the window by its _NET_WM_NAME title"
if grep -q 'resized its window' "$tmp/netwm.err"; then
    echo "a window that kept its size was reported as resized" >&2
    exit 1
fi

step "an app that resizes itself after demoreel sizes it is warned about"
# DEMO-0099. The window is sized once, before recording; an app that then
# picks its own size records cropped or off to one side, the picture is not
# flat, and every check passed. This xterm keeps shrinking itself, as Vestige
# did. 0.2.1 records it without a word.
# shellcheck disable=SC2016  # $WINDOWID belongs to xterm's shell, not to us
./demoreel record -o "$tmp/resized.mp4" -d 2 -s 640x480 -- xterm -e sh -c \
    'while :; do sleep 0.3; xdotool windowsize "$WINDOWID" 300 200; done' \
    >/dev/null 2>"$tmp/resized.err"
if ! grep -q 'resized its window to 300x200' "$tmp/resized.err"; then
    echo "a window that resized itself was not reported:" >&2
    cat "$tmp/resized.err" >&2
    exit 1
fi
echo "the self-resized window was reported, with the size to record at"

step "the stutter measure tells a stuttering video from a smooth one"
# DEMO-0109. On --gpu a busy 3D app records as runs of repeated frames, and
# changed_share is what notices. Two made-up videos pin it without a card: a
# moving pattern made at 3 frames a second and stored at 30, and the same
# pattern at a full 30. The note's own threshold decides both, so this checks
# the measure and the line together rather than restating either.
ffmpeg -v error -f lavfi -i testsrc=size=320x240:rate=3 -t 12 -r 30 \
    -c:v libx264 -pix_fmt yuv420p -y "$tmp/stutter.mp4"
ffmpeg -v error -f lavfi -i testsrc=size=320x240:rate=30 -t 12 \
    -c:v libx264 -pix_fmt yuv420p -y "$tmp/smooth.mp4"
python3 - "$tmp/stutter.mp4" "$tmp/smooth.mp4" <<'CHANGEDPY'
import importlib.machinery, importlib.util, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)
stutter = demoreel.changed_share(sys.argv[1], 30)
smooth = demoreel.changed_share(sys.argv[2], 30)
print(f"stuttering video {stutter}, smooth video {smooth}, "
      f"note below {demoreel.CHANGED_NOTE_BELOW}")
if stutter is None or smooth is None:
    sys.exit("the measure could not read one of the videos")
if not stutter < demoreel.CHANGED_NOTE_BELOW <= smooth:
    sys.exit("the measure does not separate a stuttering video from a smooth one")
CHANGEDPY
echo "the stutter measure separates the two"

step "the --gpu backend records an app that needs the card"
# DEMO-0006. Xvfb has no DRI, so a GPU app records black on it whatever flags it
# is given; --gpu puts a real Xwayland on a headless cage compositor instead.
# The gate had never recorded on that backend at all, so a regression there
# reached a user before any check saw it, and the only cover was recording
# vkcube by hand and looking at the frame.
#
# It runs where the machine can reach a card and skips where it cannot: an
# ordinary GitHub runner has neither cage nor wf-recorder installed and no render
# node to open. A skip prints why. It is not a pass, and it is not a licence to
# change this path without recording on it.
gpu_missing=()
for prog in cage Xwayland wlr-randr wf-recorder vkcube; do
    command -v "$prog" >/dev/null || gpu_missing+=("$prog")
done
if [ ${#gpu_missing[@]} -gt 0 ]; then
    echo "skipped: this machine has no ${gpu_missing[*]}"
elif ! compgen -G '/dev/dri/renderD*' >/dev/null; then
    echo "skipped: no render node under /dev/dri, so there is no card to reach"
else
    gpu_started=$SECONDS
    ./demoreel record --gpu -n gategpu -o "$tmp/gpu.mp4" -d 3 -s 640x480 \
        -- vkcube >/dev/null 2>"$tmp/gpu.err" || { cat "$tmp/gpu.err" >&2; exit 1; }
    gpu_elapsed=$((SECONDS - gpu_started))
    # vkcube moves every frame and is light, so its video must not draw the
    # stutter note (DEMO-0109). A note here means the measure calls a smooth
    # video stuttering, and would cry wolf on every --gpu run.
    ! grep -q "frames in the middle" "$tmp/gpu.err" || {
        cat "$tmp/gpu.err" >&2
        echo "a smooth vkcube recording drew the stutter note" >&2; exit 1; }
    [ -s "$tmp/gpu.mp4" ] || {
        echo "no video written on the --gpu backend" >&2; exit 1; }
    # A shaded cube is not one colour; a display with nothing on it is. This is
    # the check the backend exists for -- an Xvfb recording of vkcube is a valid
    # file, exit 0 and a black picture.
    assert_frame_drawn "$tmp/gpu.mp4" 30 "vkcube never reached the frame on --gpu"
    # And the run has to have FOUND the window rather than waited out the
    # startup timeout, which is what DEMO-0043 did on this exact app: the
    # recording succeeded, took 24 seconds instead of 4, and framed the window
    # at its own size. Measured after that fix, a -d 3 run of vkcube takes about
    # 4 seconds; the bound separates that from a 20 second timeout without
    # pinning the setup cost.
    [ "$gpu_elapsed" -lt 12 ] || {
        echo "a -d 3 --gpu run took ${gpu_elapsed}s, which is startup-timeout" >&2
        echo "shaped: the window search is probably not finding vkcube." >&2
        exit 1
    }
    echo "vkcube is in the frame, and the window was found in ${gpu_elapsed}s"
    # DEMO-0111. record --gpu records the compositor's picture, which never has
    # the pointer in it, so --cursor must be refused rather than ignored.
    if ./demoreel record --gpu --cursor -n gategpu -o "$tmp/gpucur.mp4" -d 1 \
            -- vkcube >/dev/null 2>"$tmp/gpucur.err"; then
        echo "record --gpu --cursor recorded instead of refusing" >&2; exit 1
    fi
    grep -q "not available with record --gpu" "$tmp/gpucur.err" || {
        cat "$tmp/gpucur.err" >&2
        echo "record --gpu --cursor failed without saying why" >&2; exit 1; }
    echo "record --gpu refuses --cursor"
    # DEMO-0110. A blank --gpu run was told to "record it with --gpu instead".
    # Its advice must fit the backend that ran.
    if ./demoreel record --gpu -n gategpu -o "$tmp/gpublank.mp4" -d 2 \
            -s 320x240 --startup-timeout 1 -- sleep 10 \
            >/dev/null 2>"$tmp/gpublank.err"; then
        echo "a blank --gpu recording was accepted" >&2; exit 1
    fi
    if grep -q "record it with --gpu instead" "$tmp/gpublank.err" \
            || ! grep -q -- "--settle waits" "$tmp/gpublank.err"; then
        cat "$tmp/gpublank.err" >&2
        echo "a blank --gpu run was given the Xvfb advice" >&2; exit 1
    fi
    echo "a blank --gpu run gets advice for --gpu"
fi

step "the pointer starts in the corner, not over the app"
# DEMO-0103. A fresh display puts the pointer at the centre, where it lights
# up whatever the app draws under it before any step runs, drawn or not. The
# app itself reads where the pointer is as it starts. Xvfb once reset on its
# last client leaving, which put a parked pointer straight back.
./demoreel record -o "$tmp/pointer.mp4" -d 2 -s 400x300 \
    -- sh -c "xdotool getmouselocation --shell > $tmp/pointer.txt; exec xterm -e sleep 10" >/dev/null
where=$(grep -E '^[XY]=' "$tmp/pointer.txt" 2>/dev/null | tr '\n' ' ')
[ "$where" = "X=399 Y=299 " ] || {
    echo "the pointer started at '$where', not in the bottom-right corner" >&2
    exit 1
}
echo "the pointer started in the corner"

step "--cursor draws the pointer, and the default leaves it out"
# Two recordings of the same static app, one with --cursor and one without.
# Measured while writing this: two runs WITHOUT it are byte-identical in the
# sampled frame, and adding it changes about 150 bytes of 120000 -- the pointer.
# Both runs move it to the middle first: it starts parked in the bottom-right
# corner (DEMO-0103), where most of it is off the picture.
#
# xterm running `sleep`, not xclock: a clock has a moving second hand, and a
# test that compares two frames cannot tell a moving hand from a drawn pointer.
#
# The upper bound earns its place. "The frames differ" alone would pass if the
# two recordings differed for any unrelated reason; a pointer is a small local
# change, so a large difference means something else moved and the test has
# stopped measuring what it claims to.
./demoreel record -o "$tmp/nocursor.mp4" -d 3 -s 400x300 -a 'move 200 150' \
    -- xterm -e sleep 10 >/dev/null
./demoreel record -o "$tmp/cursor.mp4" -d 3 -s 400x300 --cursor -a 'move 200 150' \
    -- xterm -e sleep 10 >/dev/null
for f in nocursor cursor; do
    ffmpeg -v error -i "$tmp/$f.mp4" -vf 'select=eq(n\,30)' -vframes 1 \
        -f rawvideo -pix_fmt gray "$tmp/$f.raw" -y
done
python3 - "$tmp/nocursor.raw" "$tmp/cursor.raw" <<'CURSORPY'
import pathlib, sys
off = pathlib.Path(sys.argv[1]).read_bytes()
on = pathlib.Path(sys.argv[2]).read_bytes()
if not off or len(off) != len(on):
    sys.exit(f"could not compare the frames ({len(off)} and {len(on)} bytes)")
differing = sum(1 for a, b in zip(off, on) if a != b)
share = differing / len(off)
print(f"--cursor changed {differing} of {len(off)} bytes ({share * 100:.3f}%)")
if differing == 0:
    sys.exit("--cursor changed nothing -- the pointer was not drawn")
if share > 0.01:
    sys.exit("the frames differ too much to attribute to a pointer")
print("--cursor draws the pointer, and the default leaves it out")
CURSORPY

step "an app that makes the display chatter does not freeze it"
# DEMO-0049. Xvfb's stderr was a pipe demoreel stopped reading after startup.
# Each keymap an app loads makes the server write xkbcomp's warnings there,
# and once the pipe filled the server blocked mid-write: the display froze,
# and so did demoreel, with no timeout reaching it. GIMP hit this in this gate.
# Sixty keymap loads fill the pipe several times over.
timeout 60 ./demoreel record -o "$tmp/chatter.mp4" -d 1 -s 320x240 \
    -n gatechatter -- sh -c \
    'i=0; while [ $i -lt 60 ]; do setxkbmap us; i=$((i+1)); done; exec xclock' \
    >/dev/null 2>&1 || {
    echo "a run whose app loads many keymaps froze or failed (exit $?)" >&2
    exit 1; }
echo "sixty keymap loads, and the display kept answering"

step "a display that stops answering fails the run instead of hanging it"
# DEMO-0079. Nothing bounded a single xdotool or frame-sample call, so a
# display that froze for any other reason hung the run with no timeout. This
# freezes the Xvfb with SIGSTOP once recording starts; the next call at the
# halfway point has to give up and fail the run. 0.2.1 hangs until `timeout`.
./demoreel record -o "$tmp/frozen.mp4" -d 6 -s 320x240 -n gatefrozen \
    -- xclock >/dev/null 2>"$tmp/frozen.err" &
frozen_run=$!
for _ in $(seq 100); do
    grep -q recording "$tmp/frozen.err" 2>/dev/null && break
    sleep 0.1
done
frozen_xvfb=$(pgrep -P "$frozen_run" -x Xvfb)
kill -STOP "$frozen_xvfb"
rc=0
timeout 60 tail --pid="$frozen_run" -f /dev/null || rc=$?
kill -CONT "$frozen_xvfb" 2>/dev/null || true
if [ "$rc" -ne 0 ]; then
    kill "$frozen_run" 2>/dev/null || true
    echo "a run on a frozen display was still hanging after 60s" >&2
    exit 1
fi
if wait "$frozen_run"; then
    echo "a run on a frozen display reported success" >&2
    exit 1
fi
grep -q 'stopped answering' "$tmp/frozen.err" || {
    echo "a run on a frozen display failed without saying the display stopped:" >&2
    cat "$tmp/frozen.err" >&2; exit 1; }
echo "the frozen display was given up on, and the run failed saying why"

step "stop ends a run started with -d 0"
# record -d 0 runs until told to stop, and stop is the only way to end it. It
# is documented, and nothing proved either half worked.
./demoreel record -o "$tmp/stopped.mp4" -d 0 -n gatestop -s 640x480 \
    --app-log "$tmp/app.log" -- xclock >/dev/null 2>&1 &
recorder=$!
gate_pids="$gate_pids $recorder"
# Straight after launching it, with no retry. DEMO-0034: a run used to be
# unreachable until it was already recording, so this line said "no recording
# named gatestop" while the run carried on. stop now finds a starting run and
# waits for it to record.
stopped=$(./demoreel stop gatestop) || {
    echo "stop could not find a run launched just before it" >&2; exit 1; }
[ "$stopped" = "$tmp/stopped.mp4" ] || {
    echo "stop printed '$stopped', not the output path" >&2; exit 1; }
# Before waiting on the recorder: the path stop prints must already be a
# finished video. It used to print as soon as it signalled, while ffmpeg was
# still writing the file (DEMO-0047).
ffprobe -v error "$tmp/stopped.mp4" || {
    echo "stop returned before the video was finished" >&2; exit 1; }
wait "$recorder" || { echo "the stopped run exited non-zero" >&2; exit 1; }
[ -s "$tmp/stopped.mp4" ] || { echo "stop left no video" >&2; exit 1; }
# --app-log rode along: same run, and it is documented too.
[ -f "$tmp/app.log" ] || { echo "--app-log wrote no file" >&2; exit 1; }
echo "stop ended the run, and --app-log wrote its file"

step "stop fails when the run it stopped fails"
# DEMO-0047. A -d 0 run that is blank when stopped fails its end-of-run check,
# and stop used to print its path anyway, so `out=$(demoreel stop ...)` held a
# path for a failed run. sleep opens no window, so the display stays blank.
./demoreel record -o "$tmp/blankstop.mp4" -d 0 -n gateblankstop -s 320x240 \
    --startup-timeout 1 -- sleep 60 >/dev/null 2>&1 &
recorder=$!
gate_pids="$gate_pids $recorder"
if blankpath=$(./demoreel stop gateblankstop 2>/dev/null); then
    echo "stop succeeded for a run that failed, printing '$blankpath'" >&2
    exit 1
fi
[ -z "$blankpath" ] || {
    echo "stop printed '$blankpath' for a run that failed" >&2; exit 1; }
if wait "$recorder"; then
    echo "the blank run succeeded, so this step tested nothing" >&2; exit 1
fi
echo "stop failed with the run, and printed no path"

step "two runs started together under one name: one records, one is refused"
# DEMO-0011. The duplicate-name check used to read the state file and write it
# much later, so two runs launched together both passed it, both recorded, and
# the later one's state file hid the earlier one from `stop`. Measured at the
# time. A lock now makes the check atomic.
./demoreel record -o "$tmp/race1.mp4" -d 3 -n gaterace -s 320x240 \
    -- xclock >/dev/null 2>"$tmp/race1.err" &
race1=$!
./demoreel record -o "$tmp/race2.mp4" -d 3 -n gaterace -s 320x240 \
    -- xclock >/dev/null 2>"$tmp/race2.err" &
race2=$!
gate_pids="$gate_pids $race1 $race2"
set +e
wait "$race1"; s1=$?
wait "$race2"; s2=$?
set -e
refused=$(cat "$tmp/race1.err" "$tmp/race2.err" | sed -n '/already running/p')
if [ $((s1 + s2)) -ne 1 ] || [ -z "$refused" ]; then
    echo "expected one run to record and one to be refused; exits were $s1 and $s2" >&2
    cat "$tmp/race1.err" "$tmp/race2.err" >&2
    exit 1
fi
echo "one recorded, and the other said: ${refused#demoreel: }"

step "stop refuses a state file whose process is not ours"
# A run killed with SIGKILL never reaches the cleanup in its `finally` block,
# so its state file outlives it -- and Linux recycles pids. Before the run's
# start time was recorded alongside the pid, stop asked only whether SOME
# process held that number and sent it SIGUSR1, whose default action is to
# terminate. Demonstrated at the time against a plain `sleep`, which died
# reporting "User defined signal 1", while stop printed a path and exited 0.
statedir="${XDG_RUNTIME_DIR:-/tmp}/demoreel-$(id -u)"
mkdir -p "$statedir" && chmod 700 "$statedir"
sleep 60 &
victim=$!
# A start time of 1 belongs to no real process: the field counts clock ticks
# since boot, so anything running now is far past it. That is the recycled-pid
# case -- right pid, wrong incarnation.
printf '{"name":"gatestale","pid":%d,"starttime":"1","display":":9","output":"%s"}\n' \
    "$victim" "$tmp/never.mp4" > "$statedir/gatestale.json"
if ./demoreel stop gatestale >/dev/null 2>&1; then
    kill "$victim" 2>/dev/null || true
    echo "stop acted on a state file whose recorded start time does not match" >&2
    exit 1
fi
if ! kill -0 "$victim" 2>/dev/null; then
    echo "stop signalled a process it never started" >&2
    exit 1
fi
kill "$victim" 2>/dev/null || true
wait "$victim" 2>/dev/null || true
rm -f "$statedir/gatestale.json"
echo "stop left the unrelated process alone"

step "the virtual display refuses a client with no cookie"
# The display is private or the tool has no point. Measured before this guard
# existed: a client with no credential at all read the geometry and grabbed a
# frame of whatever was on screen. Socket permissions cannot fix it, because
# Xvfb also listens on an abstract socket, which has none.
./demoreel record -o "$tmp/cookie.mp4" -d 0 -n gatecookie -s 640x480 \
    -- xclock >/dev/null 2>"$tmp/cookie.err" &
cookie_rec=$!
gate_pids="$gate_pids $cookie_rec"
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

step "a real Flatpak records with the three flags README documents"
# DEMO-0007. The step above tests demoreel's reading of a Flatpak command line,
# against a stub that is not Flatpak at all. Nothing tested the recipe itself,
# so the three flags README prints could stop working -- a Flatpak release
# changing what `--socket=x11` binds would do it -- and the gate would stay
# green.
#
# GIMP, deliberately not finbreak: a startup dialog and single-instance handover
# are the two traps README names, and a gate step is the wrong place to meet
# them. It is a plain GTK application, installed from Flathub, and it reaches
# the private display in about five seconds.
#
# What this proves is that a real Flatpak draws on the private display through
# those three flags. It is NOT a check that GIMP finished starting: at three
# seconds the window in frame is its splash, which is what a recording that
# short honestly shows.
#
# The negative case -- the same app WITHOUT --nosocket=wayland -- is deliberately
# not run here. Without it the app reaches the user's real compositor, which
# means opening a window on their desktop, and a gate that runs before every
# push must not do that. The stub step above covers the warning.
flatpak_app=org.gimp.GIMP
if ! command -v flatpak >/dev/null; then
    echo "skipped: this machine has no flatpak"
elif ! flatpak info "$flatpak_app" >/dev/null 2>&1; then
    echo "skipped: $flatpak_app is not installed"
elif flatpak ps --columns=application 2>/dev/null | grep -qx "$flatpak_app"; then
    # A running copy takes the launch over on the real desktop and the private
    # display stays empty, so the step would fail for a reason that is not
    # demoreel's. Skipping says which it is.
    echo "skipped: $flatpak_app is already running, so a launch would hand over"
else
    ./demoreel record -n gateflatpak -o "$tmp/real-fp.mp4" -d 3 -s 800x600 \
        --startup-timeout 60 \
        -- flatpak run --socket=x11 --nosocket=wayland \
           --filesystem=/tmp/.X11-unix "$flatpak_app" >/dev/null
    [ -s "$tmp/real-fp.mp4" ] || {
        echo "no video written for $flatpak_app" >&2; exit 1; }
    assert_frame_drawn "$tmp/real-fp.mp4" 45 \
        "$flatpak_app never reached the private display with the documented flags"
    echo "$flatpak_app drew on the private display with the three flags"
fi

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

step "shot takes one picture, prints its path, and leaves nothing behind"
# DEMO-0100. The picture is checked by reading the saved file back, with the
# same frame_is_flat as a recording. An odd size is allowed: that rule is
# H.264's. A shot writes no state file, so `stop` cannot see one, and its
# private folder goes when it succeeds.
before=$(find "$statedir" -maxdepth 1 -name "shot-*" | wc -l)
shot=$(./demoreel shot -o "$tmp/clock.png" -s 321x241 -- xclock)
[ "$shot" = "$tmp/clock.png" ] || { echo "shot printed '$shot', not its path" >&2; exit 1; }
python3 - "$tmp/clock.png" <<'PY'
import importlib.machinery, importlib.util, subprocess, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
dr = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(dr)
raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", sys.argv[1],
                      "-pix_fmt", "gray", "-f", "rawvideo", "-"],
                     capture_output=True, check=True).stdout
assert len(raw) == 321 * 241, len(raw)
assert not dr.frame_is_flat(raw), "the picture is flat"
PY
after=$(find "$statedir" -maxdepth 1 -name "shot-*" | wc -l)
[ "$after" -eq "$before" ] || { echo "a successful shot left its folder behind" >&2; exit 1; }
echo "one 321x241 picture of the app, its path on stdout, nothing left over"

step "a flat picture is refused"
if out=$(./demoreel shot -o "$tmp/flat.png" -s 320x240 --settle 1 \
         --startup-timeout 2 -- sleep 30 2>"$tmp/flat.err"); then
    echo "a picture of nothing was accepted" >&2; exit 1
fi
[ -z "$out" ] || { echo "a refused shot still printed a path: $out" >&2; exit 1; }
grep -q 'one flat colour' "$tmp/flat.err" || { cat "$tmp/flat.err" >&2; exit 1; }
rm -rf "$(sed -n 's/.*display log is kept in //p' "$tmp/flat.err")"
echo "a flat picture failed the run and printed no path"

step "a shot that fails early names the folder it kept"
# DEMO-0107. A failed shot keeps its private folder, and that folder lives
# in RAM under /run/user. Only two failure paths said where it was, so one
# failing before the picture left it behind unnamed.
if ./demoreel shot -o "$tmp/none.png" -s 320x240 -- /nonexistent/app \
       >/dev/null 2>"$tmp/early.err"; then
    echo "a shot of an app that cannot start succeeded" >&2; exit 1
fi
kept=$(sed -n 's/.*display log is kept in //p' "$tmp/early.err")
[ -n "$kept" ] && [ -d "$kept" ] || {
    echo "an early shot failure did not name the folder it kept:" >&2
    cat "$tmp/early.err" >&2; exit 1; }
rm -rf "$kept"
echo "the early failure named its folder"

step "default output name"
# -o is optional; without it the file is named from the app and a timestamp.
( cd "$tmp" && "$OLDPWD/demoreel" record -d 3 -s 640x480 -- xclock >/dev/null )
ls "$tmp"/xclock-*.mp4 >/dev/null

printf '\n=== all checks passed ===\n'
