# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## State

Working. The whole tool is one executable file, `demoreel` — Python 3, standard
library only, no build step, no dependency manifest, no test suite. Runtime
dependencies are `Xvfb`, `ffmpeg` and `xdotool`, checked at startup.

There is no spec and none is wanted; `README.md` is the design contract. The
sections below are the parts a session is most likely to break by accident.

Verify a change by recording something: `./demoreel record -o /tmp/t.mp4 -d 5
-s 640x480 -- xclock`, then `ffprobe` the result and extract a frame to confirm
the app is actually in the picture. A valid file proves nothing on its own — a
black video passes every check except looking at it.

## What this tool is

One command that records a video of a GUI app running on a **private virtual X
display** (`Xvfb`), so the user's real desktop never appears in frame. Pipeline:
start `Xvfb` → launch the caller's app on it → wait for the window and size it
to the frame → optionally replay scripted `xdotool` actions → record with
`ffmpeg` → tear everything down.

The virtual display is not an implementation detail, it is the reason the tool
exists. Recording the real screen catches private windows and catches KWin's
Magnifier lens, which the user cannot turn off because it is what makes the
screen readable.

## Non-negotiable requirements

Any change that breaks one of these is wrong, even if it makes the tool simpler:

- **Callable from any Claude Code session, in any project.** Absolute paths;
  no dependence on the caller's working directory; nothing about any specific
  app hardcoded — the caller passes the command to run.
- **Concurrency-safe.** Two sessions may record simultaneously. `Xvfb
  -displayfd` picks the display number and reports it back, so there is no gap
  between "looks free" and "is ours" for a second run to lose. Never replace
  this with a scan for a free number, and never hardcode `:99`.
- **Non-interactive.** No prompts, no portal dialogs, no "pick a window" step.
  Needing a human click is what made Kooha and OBS unusable here.
- **Cleanup on every exit path, including failure.** A leaked `Xvfb` holds its
  display number and poisons the pool for later runs.

## Scope ceiling

A few hundred lines, finished. Permanently out of scope: audio, webcam,
overlays, captions, cursor highlighting, editing/trimming, a GUI, a daemon, a
config file format, plugins, per-app profiles, a Wayland backend, and recording
the real screen. Anything needing more than "record this app doing these few
things" wants OBS instead.

## Verified environment facts

Checked by running them on this machine — do not re-derive, but do re-verify if
something behaves unexpectedly:

- `Xvfb`, `xdotool`, `wmctrl`, `ffmpeg` are installed. `xvfb-run` is **not**.
- `Xvfb :99 -screen 0 1600x1000x24` starts; `xdotool getdisplaygeometry` against
  it returns `1600 1000`.
- `xdotool` is reliable *inside* Xvfb. The common warning that it fails under
  Wayland applies to the user's real session, not to a virtual X display where
  every client is an X client.

## Two traps

- **A single-instance app will not start on the virtual display.** If a copy is
  already running on the real desktop, the new launch hands over to it and exits
  **0** — a successful process that never shows a window. finbreak behaves this
  way (FIBR-0204). The error message must name this, or it reads as a demoreel
  bug.
- **No window manager runs on the virtual display**, and none should be added —
  one app needs no WM. So `xdotool windowactivate` is skipped; the only window
  already has focus. An app whose dialogs need stacking or positioning may
  misbehave; the answer would be a minimal WM, not more code here.

## Flatpak targets need two extra flags

A Flatpak does not inherit an arbitrary `DISPLAY`: a manifest's
`--socket=fallback-x11` binds the *session's* X socket, not one named later, so
the app starts with an empty `DISPLAY` and Qt aborts with
`qt.qpa.xcb: could not connect to display`. The caller passes the override:

    demoreel record -o demo.mp4 -- \
      flatpak run --socket=x11 --filesystem=/tmp/.X11-unix <app-id>

Verified working. This belongs to the caller's command, not to demoreel —
nothing about Flatpak is hardcoded here, and adding a `--flatpak` convenience
flag would be the first step into the per-app profile registry the README rules
out.
