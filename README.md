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

1. Start an X virtual framebuffer (`Xvfb`) at a chosen size — or, with
   `--gpu`, a real X server on a headless compositor that can reach the
   graphics card.
2. Launch the target app on that display.
3. Wait for its window, and size it to fill the frame.
4. Optionally run a short list of scripted actions (click, type, wait) so the
   video shows the app being *used*, not just sitting there.
5. Record the display with `ffmpeg` for the duration.
6. Refuse to hand back a blank recording — if nothing was ever drawn on the
   display, that is an error, not a video file.
7. Kill the app, stop the display, leave one video file behind.

## Using it

```sh
# record an app for 20 seconds
/mnt/Games/Scripts/Linux/demoreel/demoreel record -o demo.mp4 -d 20 -- kate

# show it being used: scripted steps run in order while recording
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# record until told to stop, from another session
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &
demoreel stop mydemo
```

It prints the path of the finished video and nothing else. `-s` sets the frame
size (default `1600x1000`, even numbers only), `-r` the framerate, `--cursor`
draws the mouse pointer — off by default, since with no scripted clicks it just
parks in the middle of the picture. `-n` names a run so concurrent recordings
can be told apart; the display number is picked by `Xvfb` itself, so two runs
never collide.

**An app that needs the graphics card needs `--gpu`:**

```sh
demoreel record -o demo.mp4 -d 20 -s 1280x800 --gpu -- vkcube
```

`Xvfb` is a software X server with no DRI, so an OpenGL or Vulkan app cannot
render on it at all — the recording comes out black, which is why demoreel now
refuses to hand one back. `--gpu` swaps the display for a real Xwayland server
running on a headless `cage` compositor, which does reach the card. Everything
else is the same: same window sizing, same scripted actions, same one file out.

It is a *second* backend, not a replacement. `Xvfb` stays the default because
it is lighter and needs no compositor, and most apps do not touch the GPU. The
privacy property is unchanged either way — `cage` is a kiosk compositor showing
one client, started fresh for the run, with nothing of the user's session on it.

Needs `xwfb-run` (the `xwayland-run` package) and `cage` installed; demoreel
says so plainly if they are missing.

**A Flatpak target needs three extra flags**, and it is not obvious why:

```sh
demoreel record -o demo.mp4 -d 20 -- \
  flatpak run --socket=x11 --nosocket=wayland --filesystem=/tmp/.X11-unix \
  io.github.milnet01.finbreak
```

Without them the app starts with an **empty** `DISPLAY` inside the sandbox and
Qt aborts with `qt.qpa.xcb: could not connect to display`. A manifest's
`--socket=fallback-x11` binds the *session's* X socket, not one named later, so
the virtual display never reaches the sandbox; `--socket=x11` on the command
line overrides that, and `--filesystem=/tmp/.X11-unix` lets the socket itself be
seen. `--nosocket=wayland` is what makes the fallback fire: an app whose
manifest also lists `wayland` prefers it and never looks at X11 at all.

Prefer `--nosocket=wayland` to the more commonly cited `QT_QPA_PLATFORM=xcb`.
That variable is Qt-only — a GTK app ignores it, so relying on it would mean
knowing each target's toolkit, which is exactly the per-app knowledge this tool
refuses to carry. It is also unreliable across Flatpak versions: OBS issue
#11847 reports it working on 30.2.3 and failing on 31.0.1, closed as *not
planned*. Removing the escape route beats asking the toolkit not to take it.

This is the case the whole tool was built for — Flathub wants to see the Flatpak
running, not a source checkout.

**A non-Flatpak target needs the same escape, and demoreel does it for you.** On
a Wayland session every toolkit prefers Wayland, and simply clearing
`WAYLAND_DISPLAY` does not stop it: the client then falls back to the hardcoded
`$XDG_RUNTIME_DIR/wayland-0`, which is exactly the user's real compositor. So
demoreel sets `WAYLAND_DISPLAY` to a socket name that cannot exist. The Wayland
connection fails, the toolkit falls back to X11, and the app lands on the
virtual display. Nothing to pass on the command line — it applies to every
target that is not sandboxed away from the environment.

## Any Claude Code session must be able to drive it

This is not a finbreak tool. It is a machine-wide one, and **any Claude Code
session, working in any project, must be able to record with it** — that is the
whole reason it lives in its own directory rather than inside the app that
first needed it.

Three consequences, and they are requirements rather than nice-to-haves:

- **Callable from anywhere.** An absolute path that works regardless of the
  caller's working directory, and no assumption that the current project is
  finbreak. Nothing about a target app is hardcoded; the caller passes the
  command to run.
- **Safe to run concurrently.** Two sessions may record at the same moment, and
  neither should know about the other. So the display number is *found*, never
  fixed — a hardcoded `:99` is a collision waiting to happen, where the second
  run either fails or, worse, quietly records the first run's app. Every
  per-run artifact (display, temp files) is unique to that run.
- **Non-interactive.** No prompts, no dialogs, no "pick a window" step. A
  session invokes it, waits, and gets a file. Anything that needs a human to
  click is a design error here — that is precisely what made the existing tools
  unusable for this.

Clean up after every run, including on failure: a leaked `Xvfb` holds its
display number and slowly poisons the pool for later sessions.

## What it is NOT

**This is a small tool and it stays a small tool.** The temptation with
something like this is to grow it into a general screen-recording suite —
editing, transitions, overlays, a config format, a GUI, per-app profiles,
audio, webcam, upload integrations. It should not grow any of those. If a job
needs more than "record this app doing these few things", that job wants OBS,
not this.

Specifically out of scope, permanently:

- No audio, no webcam, no overlays, no captions, no cursor highlighting.

  **The file demoreel hands back is silent, and it will stay that way.** Worth
  saying outright, because `-d 20` looks like it produces something you could
  put on a website and it does not: a trailer with sound needs a second step
  somewhere else to add it. That is the accepted cost of the tool staying this
  size. Capturing the app's own audio would mean a private sound sink per run,
  a second recorder and a mux at the end — a coherent design, and still a no.

- No editing, trimming, or post-production.
- No GUI, no daemon, no config file format — arguments on the command line.
- No plugin system, no per-app profile registry.
- No third display backend. `Xvfb` covers ordinary apps and `--gpu` covers the
  ones that need the card; a compositor was added because `Xvfb` demonstrably
  could not do the job for Vulkan, not because backends are interesting.
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
- Unsetting `WAYLAND_DISPLAY` does **not** keep a client off the real
  compositor. Measured with GTK4 on this Wayland session: with the variable
  inherited, no window on `Xvfb`; with it unset, still no window on `Xvfb`;
  with it set to a name that cannot resolve, the window appears. `Xvfb` records
  black in the first two cases and the run otherwise looks entirely successful.
- A blank frame is measurable, and the margin is wide. On an empty 1280x800
  `Xvfb`, 99.994% of the frame is one grey level; a window only 200x100 brings
  that to 98%. Refusing above 99.9% separates the two without a threshold that
  needs tuning.
- `xwfb-run` (the `xwayland-run` package) and `cage` are installed, and the
  combination reaches the real GPU: `glxinfo` inside it reports
  `AMD Radeon RX 6600 (radeonsi)` rather than `llvmpipe`, and `vkcube` selects
  the discrete card through the `xcb` surface. `weston`'s headless backend was
  tried and falls back to software here (`Failed to initialize glamor`), so
  `cage` is not an arbitrary pick between the two.
- The `--gpu` display size comes from Xwayland's `-geometry`, not from the
  compositor. Without it, both `cage` and `weston` hand back Xwayland's rootful
  default of 640x480 and `-s` would be silently ignored.

## Things that catch you out

**A single-instance app will not start here.** If a copy is already running on
the real desktop, the launch on the virtual display finds it, hands over, and
exits **0** — so demoreel sees a successful process that never showed a window.
finbreak does exactly this (FIBR-0204). Close the running copy first. The error
message says so rather than leaving it looking like a demoreel bug.

**No window manager runs on the virtual display.** None is needed to record one
app, and adding one is a dependency for no gain. `windowactivate` is therefore
skipped — harmless, since the only window already has focus. An app whose
dialogs need positioning or stacking may misbehave; if that ever comes up the
answer is a minimal WM, not more code here.

**A Wayland-only app cannot run on `Xvfb` at all.** For those, `--nosocket=wayland`
breaks the app rather than redirecting it. `--gpu` does not rescue it either:
that backend also pushes the app to X11, because a client rendering natively on
the compositor is not in the X root window and `x11grab` cannot see it. An app
with no X11 support at all is the honest limit of this design.

**Not every window can be found and sized.** `xdotool` locates the window by
name, and a few apps set none — `vkcube` is one. demoreel says so and records
anyway, so you get the app at its own size on the frame rather than filling it.
Nothing is lost but the sizing.

## Status

Working. One file, `demoreel`, Python 3 and the standard library only.

Verified by recording: a plain app, scripted typing, ending a run early with
`stop`, two concurrent recordings landing on different displays, and every
failure path leaving no stray `Xvfb` behind. Flatpak targets work too, with the
three flags shown above.

`--gpu` verified the same way, by looking at the frames: `vkcube` recorded as a
hardware-rendered spinning cube, an ordinary app sized to fill the frame,
a `--gpu` run and an `Xvfb` run side by side on different displays, and no
`cage` or `Xwayland` left running afterwards.

## License

MIT — see [LICENSE](LICENSE).
