# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## State

Working. The whole tool is one executable file, `demoreel` — Python 3, standard
library only, no build step, no dependency manifest. Runtime dependencies are
`Xvfb`, `xauth`, `ffmpeg` and `xdotool`, plus `cage`, `Xwayland`,
`wf-recorder` and `wlr-randr` for `--gpu`, all checked at startup against the
backend actually in use.

`ROADMAP.md` is generated from the roadmap store. Do not hand-edit it — use the
roadmap verbs, or the next write reverts your edit.

There is no spec and none is wanted; `README.md` is the design contract. The
sections below are the parts a session is most likely to break by accident.

Verify a change by running `./ci.sh`. Among its steps: the linter, a parse, a
check that every flag `README.md` documents is one the tool accepts, and a
smoke recording that samples a frame and fails if the app never reached the
picture. It is the same script CI runs, and it runs before a push. Add a check
there, never to the workflow. `./ci.sh --docs` is the documentation-only
subset, which a documentation-only push selects.

The gate records on `--gpu` and on a real Flatpak as well, but only where
the machine has what those steps need — both skip on GitHub, so CI still covers
`Xvfb` alone. Touching the `--gpu` path still means looking at a frame:
`--gpu -- vkcube` is the cheap case, and it should show a shaded cube rather
than a flat colour. A valid file proves nothing on its own, and the automatic
check only knows flat from not-flat — a garbled picture passes it.

This file's review history is kept outside it, in
`docs/reviews/claude-md-loop-log.md`. `README.md` is gated too, as the design
contract it is, and its history is in `docs/reviews/readme-loop-log.md` for the
same reason: a review table is not what a README's readers came for.

## What this tool is

One command that records a video of a GUI app running on a **private virtual X
display** (`Xvfb`), so the user's real desktop never appears in frame. Pipeline:
start `Xvfb` → launch the caller's app on it → wait for the window and size it
to the frame → record with `ffmpeg` (`wf-recorder` on `--gpu`) → optionally
replay scripted `xdotool` actions → tear everything down. The actions run while
the recorder is attached, or they are not in the video.

The virtual display is not an implementation detail, it is the reason the tool
exists. Recording the real screen catches private windows and catches KWin's
Magnifier lens, which the user cannot turn off because it is what makes the
screen readable.

## Non-negotiable requirements

Any change that breaks one of these is wrong, even if it makes the tool simpler:

- **Callable from any Claude Code session, in any project.** Absolute paths;
  nothing the tool needs is found relative to the caller's working directory;
  nothing about any specific app hardcoded — the caller passes the command to
  run. Paths the caller passes are the deliberate exception: a relative `-o` or
  `--app-log` resolves against their directory, and an `-o`-less run writes its
  file there.
- **Concurrency-safe.** Two sessions may record simultaneously. `Xvfb
  -displayfd` picks the display number and reports it back, so there is no gap
  between "looks free" and "is ours" for a second run to lose. Never replace
  this with a scan for a free number, and never hardcode `:99`. The `--gpu`
  backend keeps the same property twice over: Xwayland reports its number
  through its own `-displayfd`, and `cage` picks its own Wayland socket name,
  which demoreel reads back from the environment `cage` gives its child. Never
  pass either one a name or number chosen in advance. The display number is
  only half of it: every
  file a run writes under the state directory is keyed off `--name`, which
  defaults to `default`. A run holds an `flock` on `<name>.lock` for its whole
  life (`claim_name`), and that lock — not the state file — is the duplicate
  check. Checking the state file and writing it later let two runs started
  together both record, one of them unreachable by `demoreel stop`
  (DEMO-0011). Never replace the lock with a check on the state file, never
  unlink the lock file, and never collapse the per-name paths to a fixed
  filename.
- **Non-interactive.** No prompts, no portal dialogs, no "pick a window" step.
  Needing a human click is what made Kooha and OBS unusable here.
- **Cleanup on every exit path, including failure.** A leaked `Xvfb` holds its
  display number and poisons the pool for later runs.

## Scope ceiling

The ceiling is what the tool *does*, not how long it is. Permanently out of
scope: audio, webcam, overlays, captions, cursor highlighting, editing/trimming,
a GUI, a daemon, a config file format, plugins, per-app profiles, and recording
the real screen. Anything needing more than "record this app doing these few
things" wants OBS instead.

**Do not report or reason about the line count.** Judge a change by whether it
earns its place against the list above, and say nothing about length.

**Audio stays out**, and the consequence is stated in `README.md` rather than
left implied: the file demoreel produces is silent, and a trailer with sound
needs a second step elsewhere. The design that would have fitted is recorded
there too, so it does not have to be re-derived to be re-declined.

**There are two display backends and there is not a third.** `Xvfb` has no DRI,
so a GPU app records black on it, and no flag changes that. That is what `--gpu`
exists for, and `Xvfb` remains the default.

## Verified environment facts

Checked by running them on this machine — do not re-derive, but do re-verify if
something behaves unexpectedly:

- `Xvfb`, `xdotool`, `wmctrl`, `ffmpeg` are installed. `xvfb-run` is **not**.
- `Xvfb :99 -screen 0 1600x1000x24` starts; `xdotool getdisplaygeometry` against
  it returns `1600 1000`.
- `xdotool` is reliable *inside* Xvfb. The common warning that it fails under
  Wayland applies to the user's real session, not to a virtual X display where
  every client is an X client.
- `/run/user/1000/wayland-0` exists on this session, and that is what makes
  clearing `WAYLAND_DISPLAY` useless — see the trap below. Measured with GTK4:
  inherited → no window on Xvfb; unset → no window on Xvfb; set to an
  unresolvable name → window appears.
- An empty 1280x800 Xvfb is 99.994% one grey level; a 200x100 window drops that
  to 98%. That gap is what the blank-recording check is calibrated against.
- **demoreel's process name is `python3`, not `demoreel`.** It is a script run
  through its shebang, so the kernel takes the name from the interpreter.
  `pgrep -x demoreel` therefore matches nothing and always reports success,
  whatever is running. Checking for a leaked run means the Xvfb it started, or
  the pid the caller already holds. Not its state file: every run leaves that
  behind, so `stop` can read how the run ended.
- `-a` actions reach the app on the `--gpu` path as well as under Xvfb —
  measured with a click and a keystroke against `gtk4-demo` on the compositor,
  both landing. No auth or DISPLAY difference for xdotool beyond the run's env,
  which it already gets.

## Traps

- **`WAYLAND_DISPLAY` is set to a name that cannot resolve, not unset — and
  that is the whole fix, not a stylistic choice.** `wl_display_connect(NULL)`
  falls back to the hardcoded `$XDG_RUNTIME_DIR/wayland-0` when the variable is
  absent, so `env.pop()` sends the app straight to the user's real compositor;
  `Xvfb` then records black, `ffmpeg` exits 0 and every signal says success.
  Do not "tidy" it back to a `pop()`. Do not neutralise `XDG_RUNTIME_DIR`
  instead: that variable also carries the D-Bus and PipeWire socket paths.
  Do not reach for `QT_QPA_PLATFORM=xcb` — same objection as the Flatpak note
  below, it is Qt-only.
- **stdout carries the finished path and nothing else.** The app's own output
  goes to our stderr, or to `--app-log`, never to stdout — a caller writing
  `out=$(demoreel record ...)` collects whatever the app printed otherwise.
  `subprocess.Popen` inherits the parent's stdout unless told not to, so the
  way to reintroduce the bug is to drop the `stdout=` argument, not to add
  anything.
- **`--settle` and the blank check are the same test**, `display_is_blank`, in
  two roles: a gate before recording and an assertion during and after it. That
  is deliberate — one definition of "nothing is on this display" — and it means
  the threshold and its comparator are written once, as `BLANK_THRESHOLD` and
  `frame_is_flat`, and serve both roles. `ci.sh` imports them rather than
  restating them, so it is not a copy to keep in step. The remaining copies
  are prose: `README.md` and the blank-recording trap below. Move them
  with the definition, or the docs stop describing what the tool does. It also
  sets `--settle`'s honest limit: it waits for any pixel variation, not for the
  app to be ready, so a startup screen with a cursor on it counts as drawn (a
  real `xterm` measures 0.977). Do not tune the threshold for one of the two
  roles alone.
- **A blank recording is an error, deliberately.** One frame is sampled halfway
  through the `-d` countdown and one after it, and the run fails if either is
  more than 99.9% one colour. Blank at halfway means at least half the
  countdown is empty, and the run stops there (DEMO-0008). A `-d 0` run has no
  halfway point. Each sample is skipped when the app has already exited: it
  left an empty display behind, and that video is fine. The check exists
  because the failure it catches is silent: a valid file, exit 0, and nothing
  in the picture. Do not downgrade it to a warning. A sample that fails is a
  third answer, "could not tell", and it fails the run too (`SampleError`).
  Never fold it into "not blank": that is the success path, and it is how the
  guard once passed everything whenever its own measurement broke (DEMO-0033).
- **A single-instance app will not start on the virtual display.** If a copy is
  already running on the real desktop, the new launch hands over to it and exits
  **0** — a successful process that never shows a window. finbreak behaves this
  way (FIBR-0204). The error message must name this, or it reads as a demoreel
  bug.
- **The window to record is the biggest one, and that is deliberate.** An app
  with a modal startup dialog has two windows; picking by search order gets the
  dialog about as often as not, and it then gets stretched to fill the frame
  while the real window sits untouched behind it. finbreak's unlock dialog hit
  exactly this. Do not restore `ids[-1]` — xdotool's output is not ordered by
  id, so it was never even picking the newest window. Do not add a
  `--window-name` filter either: that is per-app configuration wearing a
  different hat, and size separates the two windows without knowing anything
  about the app. The candidates are visible windows with a title under either
  title property (`named_windows`). Do not narrow that back to
  `xdotool search --name .`, which reads only WM_NAME and never finds vkcube
  (DEMO-0043). Do not widen it to every visible window either: that list holds
  a nameless display-sized window that would win on size.
- **No window manager runs on the virtual display**, and none should be added —
  one app needs no WM. So `xdotool windowactivate` is skipped; the only window
  already has focus. An app whose dialogs need stacking or positioning may
  misbehave; the answer would be a minimal WM, not more code here.

## Flatpak targets need three extra flags

A Flatpak does not inherit an arbitrary `DISPLAY`: a manifest's
`--socket=fallback-x11` binds the *session's* X socket, not one named later, so
the app starts with an empty `DISPLAY` and Qt aborts with
`qt.qpa.xcb: could not connect to display`. The caller passes the override:

    demoreel record -o demo.mp4 -- \
      flatpak run --socket=x11 --nosocket=wayland --filesystem=/tmp/.X11-unix <app-id>

Verified working. `--filesystem=/tmp/.X11-unix` is what lets the sandbox see
the socket itself. `--nosocket=wayland` is load-bearing, not belt-and-braces:
finbreak's manifest is `sockets=fallback-x11;wayland`, and *fallback*-x11 means
X11 is bound only when Wayland is absent. With the Wayland socket present the
app never looks at X11, so the virtual display goes unused.

**Do not swap it for `QT_QPA_PLATFORM=xcb`**, which is the fix most search
results suggest. Two reasons, and the first is the one that matters here: it is
Qt-only, so a GTK target ignores it and the tool would need to know each app's
toolkit — per-app knowledge this tool exists not to carry. It is also unstable
across Flatpak releases (OBS issue #11847: works on 30.2.3, fails on 31.0.1,
closed *not planned*). Denying the socket removes the escape route; the env var
merely asks the toolkit not to take it.

The flags belong to the caller's command, not to demoreel. A `--flatpak`
convenience flag would be the first step into the per-app profile registry the
README rules out.

## The `--gpu` backend

demoreel starts a headless `cage` compositor (`WLR_BACKENDS=headless`) and a
full-screen, rootful `Xwayland` on it, which reaches the GPU where `Xvfb`
cannot. It records the compositor's output with `wf-recorder`, not the X side
with `x11grab`. Under a busy 3D app the X side's copy of the picture goes stale:
`x11grab` got 156 new frames of 588 where `wf-recorder` got 643 of 643, over
the same run (DEMO-0109). All four programs are installed. The details below
are load-bearing and none is obvious:

- **The order is fixed: `cage`, then resize, then `Xwayland`, then the app.**
  `cage`'s headless output is always 1280x720 at start. `wlr-randr --output
  HEADLESS-1 --custom-mode WxH` resizes it, but an `Xwayland` already running
  keeps its first size and is scaled into the output. So `cage`'s one child is
  a step that resizes the output, then `exec`s `Xwayland -geometry WxH`. The app
  starts afterwards, as on the `Xvfb` path, so pointer parking happens before
  the app exists. Do not go back to `xwfb-run`: it starts `cage` and `Xwayland`
  as one step, with no place for the resize.
- **The app still has to be pushed to X11 inside the compositor.** `cage`
  speaks Wayland, so an app left to choose renders natively on it. The recorder
  would see that window, but finding the window, sizing it, the scripted steps
  and the blank check all work through X. `vkcube` picks `wayland` there unless
  told otherwise. The app gets the same unresolvable `WAYLAND_DISPLAY` as on
  the `Xvfb` path.
- **`wf-recorder` needs `-D`, `-y`, `-r`, `-c libx264` and `-x yuv420p`.**
  Without `-D` it asks for a frame only when the screen changes, and ignores
  `SIGINT` while the screen is still. Without `-y` it asks before overwriting,
  which is a prompt. It reaches `cage` through the socket name read back, never
  the session's `WAYLAND_DISPLAY`. The finished file must match the `Xvfb`
  path's: H.264, `yuv420p`, `+faststart`. `wf-recorder` has no muxer-flag
  option, so if its file lacks faststart, a stream-copy remux adds it.
- **The countdown starts when `wf-recorder` is capturing, never after a
  guessed delay** (DEMO-0012). It prints no progress reports like `ffmpeg`'s,
  so the signal is its own start-up output. Which line proves capture has
  begun is for the build to confirm against the video's first frame.
- **`--cursor` is refused with `--gpu`.** `wf-recorder` has no pointer option,
  and with the pointer parked mid-screen no recorded frame showed it.
- **Only the recording moves to the compositor.** `--settle`, the blank check
  and `demoreel shot` still read the X side with `x11grab`. A stale-by-a-moment
  picture answers "is anything drawn?" correctly, and one still frame shows no
  stutter.
- **Both displays are behind an auth cookie, so the X-side readers take the
  run's `env` rather than inheriting the session's** — otherwise they fail with
  `Cannot open display`, or silently sample an empty frame. Without a cookie a
  client with no credential can read the display, and socket permissions are no
  substitute, because `Xvfb` also listens on an abstract socket. The cookie is
  installed after `-displayfd` reports the number, since the cookie is keyed to
  it: start with an empty auth file, then write the cookie. `Xvfb` is then sent
  `SIGHUP` to re-read; do not "simplify" that ordering away. `Xwayland` re-reads
  the changed file with no signal (measured: a client with no credential got in
  before the cookie and was refused after). So on `--gpu` the lock is proven in
  force by a client *without* the cookie being refused. A client with it
  connects before the lock too, so its success proves nothing.

`weston` is also installed, from testing this. Its headless backend falls back
to software rendering here (`Failed to initialize glamor`,
`amdgpu_query_info(ACCEL_WORKING) failed`), so it is not an alternative to
`cage` — it can be removed if it is not wanted for anything else.

## Wayland-only apps: the limit of this design

An app that cannot speak X11 at all will not run on `Xvfb`, and
`--nosocket=wayland` breaks it rather than redirecting it. `--gpu` does not
help either — that backend pushes the app to X11 for the reason above. This is
a real limit of the approach, not a bug to fix in the code.

If one turns up, the option is `wlheadless-run`, which runs a client against a
headless compositor *without* Xwayland in the way. `--gpu`'s recorder could
capture such a client. Finding, sizing and driving it could not: all of that is
`xdotool`, which is X-only. So it is a different tool from this one. This note
exists so a future session meeting such an app reaches for
the known option instead of concluding the whole design was a mistake.

## Rule history

This file states what is true now and what a breach looks like. The dated
decisions behind a rule, the wording a rule replaced, and the argument that
settled one are in [`docs/history/claude-md.md`](docs/history/claude-md.md).
Read it to question a rule; you do not need it to follow one.
