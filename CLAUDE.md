# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## State

Working. The whole tool is one executable file, `demoreel` — Python 3, standard
library only, no build step, no dependency manifest. Runtime dependencies are
`Xvfb`, `ffmpeg` and `xdotool`, plus `xwfb-run` and `cage` for `--gpu`, all
checked at startup against the backend actually in use.

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

The gate covers the `Xvfb` backend only. Touching the `--gpu` path means
recording on it by hand: `--gpu -- vkcube` is the cheap case, and the frame
should show a shaded cube rather than a flat colour. A valid file proves
nothing on its own — a black video passes every check except looking at it.

This file's review history is kept outside it, in
`docs/reviews/claude-md-loop-log.md`.

## What this tool is

One command that records a video of a GUI app running on a **private virtual X
display** (`Xvfb`), so the user's real desktop never appears in frame. Pipeline:
start `Xvfb` → launch the caller's app on it → wait for the window and size it
to the frame → record with `ffmpeg` → optionally replay scripted `xdotool`
actions → tear everything down. The actions run while `ffmpeg` is attached, or
they are not in the video.

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
  backend keeps the same property by a different route: Xwayland picks the
  number inside `xwfb-run`, and demoreel reads it back out. Do not "simplify"
  that to `xwfb-run -n <number>`. The display number is only half of it: every
  file a run writes under the state directory is keyed off `--name`, which
  defaults to `default`. The state file is written only after recording
  starts, and that gap decides what two unnamed runs do. Measured both ways:
  started seconds apart, the second refuses and says to use `--name`; started
  together, both pass the check before either writes, both record, and the
  later overwrites the earlier's state file — leaving it unreachable by
  `demoreel stop` (DEMO-0011). Never collapse those per-name paths to a fixed
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

**Do not report or reason about the line count.** Stated by the user on
2026-08-07: the number of lines is irrelevant as long as the tool does what it
is supposed to do. The earlier "a few hundred lines, finished" wording invited
every session to flag the file's size as if it were a finding; it is not one.
Judge a change by whether it earns its place against the list above, and say
nothing about length.

**Audio was put to the user on 2026-08-07 and stays out**, with the consequence
stated in the README rather than left implied: the file demoreel produces is
silent, and a trailer with sound needs a second step elsewhere. The design that
would have fitted — a per-run null sink, a second `ffmpeg`, one mux — is
recorded there too, so it does not have to be re-derived to be re-declined.

**There are two display backends and there is not a third.** `--gpu` was added
the same day, after the "no Wayland compositor backend" line was tested against
a Vulkan app and lost: `Xvfb` has no DRI, so a GPU app records black on it, and
no flag changes that. `Xvfb` remains the default.

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
  This was broken from the start and fixed on 2026-08-07; `subprocess.Popen`
  inherits the parent's stdout unless told not to, so the way to reintroduce
  the bug is to drop the `stdout=` argument, not to add anything.
- **`--settle` and the blank check are the same test**, `display_is_blank`, in
  two roles: a gate before recording and an assertion after it. That is
  deliberate — one definition of "nothing is on this display" — and it means
  the 0.999 threshold is written once, in `display_is_blank`, and serves both
  roles. Everywhere else is a copy: the literal `ci.sh` asserts against, and the
  prose in `README.md` and in the blank-recording trap below. Move every copy
  with the definition, or the gate stops testing what the tool does. It also
  sets `--settle`'s honest limit: it waits for any pixel variation, not for the
  app to be ready, so a startup screen with a cursor on it counts as drawn (a
  real `xterm` measures 0.977). Do not tune the threshold for one of the two
  roles alone.
- **A blank recording is an error, deliberately.** After the duration, one
  frame is sampled and the run fails if more than 99.9% of it is a single
  colour. The sample is skipped when the app has already exited: it left an
  empty display behind, and that video is fine. The check exists because the
  failure it catches is silent: a valid file, exit 0, and nothing in the
  picture. Do not downgrade it to a warning.
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
  about the app.
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

`xwfb-run -c cage` puts a real Xwayland server on a headless `cage` compositor,
which reaches the GPU where `Xvfb` cannot. Both packages are now installed.
Three details are load-bearing and none is obvious:

- **`-geometry` is what sets the size**, passed as `-s '\-geometry' -s WxH`.
  The dash must be escaped and the value must be a separate `-s`, because
  `xwfb-run` forwards each `-s` as one argument — `-s '-geometry 1280x800'`
  reaches Xwayland as a single unknown option and it refuses to start. Without
  it you get Xwayland's rootful default of 640x480 and `-s` looks broken.
- **The app still has to be pushed to X11 inside the compositor.** `cage`
  speaks Wayland, so an app left to choose renders natively on it — and a
  native Wayland surface is not in the X root window, so `x11grab` records
  nothing. `vkcube` picks `wayland` there unless told otherwise.
- **Xwayland demands an auth cookie**, which `Xvfb` does not. So `ffmpeg` and
  the blank-frame sample take the run's `env` rather than inheriting the
  session's — otherwise they fail with `Cannot open display`, or silently
  sample an empty frame.

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
headless compositor *without* Xwayland in the way — but recording it then needs
a compositor-side capture path, not `x11grab`, which is a different tool from
this one. This note exists so a future session meeting such an app reaches for
the known option instead of concluding the whole design was a mistake.
