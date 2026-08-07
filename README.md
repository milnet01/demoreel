# demoreel

Record a short video of a GUI app, driven by Claude Code, without filming the
user's desktop.

## Why this exists

Some places want a video of an app actually running — Flathub's submission
checklist is the case that prompted this, and it will not be the last.

Recording the real screen is the obvious approach and it is the wrong one here,
for two reasons found the hard way:

1. **It films the user's desktop.** Whatever else is open, and whatever is
   private, goes into a file that ends up on a public pull request.
2. **It films the user's accessibility tools.** This machine runs KWin's
   Magnifier. It is drawn onto the screen output, so every screen or region
   recording catches the lens sliding around. Turning it off is not an answer:
   it is what makes the screen readable in the first place, so without it the
   app cannot be operated for the recording at all.

Window capture avoids both — it reads the window's own buffer, before the
compositor paints its effects. But the recorder has to *ask* the desktop for a
window source, and Kooha 2.3.2 does not: its portal dialog offers screen,
virtual screen and region only. OBS does ask, but driving OBS by hand defeats
the point of Claude Code doing the recording.

So: run the app on a **private virtual display** that has no desktop and no
magnifier on it, and record that. Nothing of the user's session is in frame
because the user's session is not there.

## What it does

One command. Give it an app and get back a video file.

1. Start an X virtual framebuffer (`Xvfb`) at a chosen size.
2. Launch the target app on that display.
3. Wait for its window, and size it to fill the frame.
4. Optionally run a short list of scripted actions (click, type, wait) so the
   video shows the app being *used*, not just sitting there.
5. Record the display with `ffmpeg` for the duration.
6. Kill the app, stop the display, leave one video file behind.

## What it is NOT

**This is a small tool and it stays a small tool.** The temptation with
something like this is to grow it into a general screen-recording suite —
editing, transitions, overlays, a config format, a GUI, per-app profiles,
audio, webcam, upload integrations. It should not grow any of those. If a job
needs more than "record this app doing these few things", that job wants OBS,
not this.

Specifically out of scope, permanently:

- No audio, no webcam, no overlays, no captions, no cursor highlighting.
- No editing, trimming, or post-production.
- No GUI, no daemon, no config file format — arguments on the command line.
- No plugin system, no per-app profile registry.
- No Wayland compositor backend while X and `Xvfb` do the job.
- No recording of the user's real screen. That is the entire thing it exists to
  avoid, and adding it back would make every other decision here pointless.

A reasonable finished size is a few hundred lines. If it is heading past that,
something has been added that should not have been.

## Constraints already verified on this machine

Checked by running them, not assumed:

- `Xvfb`, `xdotool`, `wmctrl` and `ffmpeg` are installed. `xvfb-run` is not.
- `Xvfb :99 -screen 0 1600x1000x24` starts, and `xdotool getdisplaygeometry`
  against it returns `1600 1000`. The virtual display works.
- X11 automation is reliable *inside* Xvfb. The usual warning that `xdotool`
  hangs or silently fails under Wayland applies to the user's real session, not
  to a virtual X display, where every client is an X client.

## The known obstacle, unsolved

**A Flatpak app does not inherit an arbitrary `DISPLAY`.** Launching
`io.github.milnet01.finbreak` with `DISPLAY=:99` set in the outer environment
and `WAYLAND_DISPLAY` unset gives an **empty** `DISPLAY` inside the sandbox, and
Qt aborts with `qt.qpa.xcb: could not connect to display`. The host has the
socket (`/tmp/.X11-unix/X99` exists); the sandbox is not given it, because
`--socket=fallback-x11` binds the session's X socket, not one chosen later.

Untried leads, in order of promise:

1. `flatpak run --socket=x11 …` — an explicit runtime override rather than the
   manifest's `fallback-x11`.
2. `--filesystem=/tmp/.X11-unix` alongside it, if the socket still is not
   visible.
3. Run the app **unsandboxed** for recording (`python -m finbreak` from a
   source checkout). Simplest, and enough whenever the video only needs to show
   the app — but it does not prove the *Flatpak* runs, which is exactly what
   Flathub is asking to see.

Lead 3 is a real trade-off, not a shortcut: check what the video is being asked
to demonstrate before taking it.

## Status

Outline only. Nothing is built yet.
