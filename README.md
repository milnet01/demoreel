# demoreel

**Record a video of an app running, without filming your desktop.**

You give it an app. It gives you back a video file of that app, and nothing
else — no other windows, no notifications, no magnifier lens sliding around.

It is built to be driven by Claude Code, so you can ask for a demo video and get
one without touching a recording tool yourself.

## What you get

One `.mp4` file. Just the app, filling the frame.

The video is **silent**. There is no sound and there never will be — see
[What it will never do](#what-it-will-never-do). If you need a voiceover or
music, that is a second step in something else.

## Quick start

`demoreel` works from any folder, so you can just type it. Its home is
`/mnt/Games/Scripts/Linux/demoreel/`, if you ever need the full path.

```sh
# record Kate for 30 seconds, into a file named after the app
demoreel record -- kate

# choose the filename and how long to record
demoreel record -o demo.mp4 -d 20 -- kate

# show the app being used, not just sitting there
demoreel record -o demo.mp4 -d 20 --cursor \
  -a 'wait 2' -a 'click 400 300' -a 'type hello' -a 'key Return' -- myapp

# record until you say stop, rather than for a set time
demoreel record -o demo.mp4 -d 0 -n mydemo -- myapp &
demoreel stop mydemo
```

Everything after `--` is the command that starts your app, exactly as you would
type it yourself. demoreel knows nothing about any particular app.

When it finishes it prints one line: the path to your video. Nothing else goes
on that line, so you can safely capture it in a script. Anything the app itself
prints goes to the terminal separately, or to a file with `--app-log`.

## How it avoids filming your desktop

This is the whole idea, so it is worth a minute.

The obvious approach is to record the screen. That is the wrong approach here,
for two reasons found the hard way.

**It films everything you have open.** Whatever else is on screen, private or
not, ends up in a file that may go on a public pull request.

**It films your accessibility tools.** This machine runs KDE's Magnifier, a lens
that follows the pointer. It is painted onto the screen itself, so any screen
recording catches it. Turning it off is not an option — it is what makes the
screen readable, so without it the app cannot be driven for the recording at
all.

Recording a single window would dodge both, because it reads that window
directly rather than the screen. But the recorder has to *ask* the desktop for a
window, and Kooha 2.3.2 does not: it only offers whole screen, virtual screen or
a region. OBS does ask, but clicking through OBS by hand defeats the point of
having Claude Code make the recording.

So demoreel does something different. It builds a **second, invisible screen**
that exists only for this recording — with no desktop on it, no notifications
and no magnifier — starts your app there, and films that. Nothing of your real
session can be in the picture, because your real session is not on that screen.

Nobody else can look at that screen either. It is locked with a one-off password
(an "auth cookie") that only this run holds, so another program on the machine
cannot peek at what is being recorded.

### What happens, step by step

1. Create the private screen at the size you asked for.
2. Start your app on it.
3. Wait for the app's window, then resize it to fill the frame.
4. Optionally run your scripted steps — click, type, wait — while recording.
5. Record for the duration you asked for.
6. Check the result is not blank. If nothing was ever drawn, that is an error,
   not a video.
7. Close the app, remove the private screen, leave one video file behind.

Step 6 matters more than it sounds. A recording of nothing is still a perfectly
valid video file that opens, plays, and reports success — so without that check
you would only find out by watching it.

## The options

| Option | What it does |
|---|---|
| `-o` | Where to write the video. Without it, the file lands in the current folder, named after the app and the time. |
| `-d` | How many seconds to record. `-d 0` means "keep going until I say stop". |
| `-s` | The size of the picture, like `1280x800`. Both numbers must be even. |
| `-r` | Frames per second. |
| `-n` | A name for this run, so `demoreel stop` knows which one you mean. |
| `-a` | A scripted step. Repeat it; they run in order. |
| `--cursor` | Draw the mouse pointer. Off by default, because with no scripted clicks it just sits in the middle of the picture. |
| `--app-log` | Save what the app printed to a file. |
| `--settle` | Wait for the app to draw something before starting to record. |
| `--gpu` | For apps that need the graphics card. |
| `--startup-timeout` | How long to wait for the app's window to appear. |
| `--version` | Print the version. |

### Scripted steps

`-a` takes one step at a time, and they run in the order you write them, while
the recording is going:

- `wait 2` — pause for two seconds
- `move 400 300` — move the pointer
- `click 400 300` — click there, or just `click` where it already is
- `type hello there` — type some text
- `key Return` — press a key

**Do not script typing a password on a shared machine.** Anything you put on the
command line can be read by other people using that computer, for as long as the
command runs.

### Running two recordings at once

That is fine, as long as you give them different names with `-n`. They pick
separate private screens on their own; you never have to think about that part.
If you start a second unnamed recording while the first is still going, it
refuses rather than confusing the two.

### `--app-log`: keeping what the app said

Worth using when the app itself tells you whether it drew the *right* thing.

demoreel can tell that *something* was recorded. It cannot tell that an app
quietly fell back to low-detail graphics — that recording is not blank, does not
error, and passes every check here. If your app prints a line proving it loaded
the real thing, keep the log and check it.

The technical logs are kept automatically whenever a run fails, and deleted when
it succeeds.

### `--settle`: skipping a black startup screen

Some apps, especially graphics-heavy ones, sit on a black screen for several
seconds while they warm up. Without this you record that black screen and have
to trim it off afterwards — which is editing, and editing is deliberately not
this tool's job.

`--settle 20` waits up to twenty seconds for the screen to stop being one flat
colour, then starts recording. If nothing is ever drawn it says so and records
anyway, leaving the blank check to fail the run.

It is the same test as the blank check at the end of a run, used as a gate
rather than as a verdict. That is deliberate: one definition of "nothing is on
this screen".

Its honest limit: it waits for *any* change in the picture, not for the app to
be ready. An app that paints a cursor or a border over its black startup screen
counts as drawn. A real `xterm` measures 97.7% uniform, well under the 99.9%
bar, so it is built for a startup screen that is genuinely blank.

## Apps that need the graphics card

Some apps — 3D, games, anything using OpenGL or Vulkan — cannot draw at all on
the ordinary private screen, because it has no graphics card behind it. You get
a black recording, which demoreel refuses to hand back.

For those, add `--gpu`:

```sh
demoreel record -o demo.mp4 -d 20 -s 1280x800 --gpu -- vkcube
```

This swaps in a different kind of private screen, one that can reach the real
graphics card. Everything else is the same: same sizing, same scripted steps,
same single file out. Privacy is unchanged — it is still a screen of its own,
started fresh for this run, with nothing of your session on it.

The ordinary screen stays the default, because it is lighter and most apps do
not need the card. `--gpu` needs `xwfb-run` (the `xwayland-run` package) and
`cage` installed; demoreel says so plainly if they are missing.

## Recording a Flatpak app

A Flatpak needs three extra flags on **its own** command line:

```sh
demoreel record -o demo.mp4 -d 20 -- \
  flatpak run --socket=x11 --nosocket=wayland --filesystem=/tmp/.X11-unix \
  io.github.milnet01.finbreak
```

If you leave one out, demoreel tells you which one before it starts recording,
rather than handing you a blank video afterwards.

Why they are needed, briefly. A Flatpak runs in a sandbox and cannot see the
private screen unless it is told to. `--socket=x11` and
`--filesystem=/tmp/.X11-unix` are what let it through. `--nosocket=wayland` is
the one people miss: given the choice, the app prefers the other display system
and ignores the private screen entirely, so this removes the choice.

It is a warning rather than a refusal, because an app that never offered that
choice does not need `--nosocket=wayland`, and knowing which is which would mean
knowing each app.

You may see `QT_QPA_PLATFORM=xcb` suggested instead. Prefer the flags above.
That setting only works for Qt apps, so a GTK app ignores it — and relying on it
would mean knowing each app's toolkit, which is exactly the per-app knowledge
this tool refuses to carry. It is also unreliable between Flatpak versions: OBS
issue #11847 reports it working on 30.2.3 and failing on 31.0.1, closed as *not
planned*.

This is the case the whole tool was built for. Flathub wants to see the Flatpak
running, not a source checkout.

**An ordinary, non-Flatpak app needs the same nudge, and demoreel does it for
you** — no flags, nothing to remember. It applies to every target that is not
sandboxed away from its environment.

## Any Claude Code session must be able to drive it

This is a machine-wide tool, not part of any one project. **Any Claude Code
session, working in any project, must be able to record with it** — that is why
it lives in its own directory rather than inside the app that first needed it.

Four requirements follow, and they are requirements rather than preferences:

- **Callable from anywhere.** It works regardless of which folder you are in,
  and nothing about any particular app is built in; the caller passes the
  command to run.
- **Discoverable without being told.** A session that has never heard of this
  tool still has to find it. The `record-demo` skill does that job: it is
  machine-wide, so a request to record an app routes here on its own.
- **Safe to run at the same time as itself.** Two sessions may record at the
  same moment and neither should know about the other. So the private screen is
  *found*, never fixed — a hardcoded one is a collision waiting to happen, where
  the second run either fails or, worse, quietly records the first run's app.
  Everything a run writes is keyed to its name, so simultaneous runs need
  different `-n` values.
- **Never asks you anything.** No prompts, no dialogs, no "pick a window" step.
  A session runs it, waits, and gets a file. Anything needing a human click is a
  design error here — that is exactly what made the existing tools unusable.

It also cleans up after every run, including failures. A leftover private screen
holds its slot and slowly spoils the pool for later sessions.

## What it will never do

**This is a small tool and it stays a small tool.** The temptation is to grow it
into a general recording suite. If a job needs more than "record this app doing
these few things", that job wants OBS.

Permanently out of scope:

- No audio, webcam, overlays, captions or cursor highlighting.

  **The file demoreel hands back is silent, and it will stay that way.** Worth
  saying outright, because `-d 20` looks like it produces something you could
  put straight on a website and it does not: a trailer with sound needs a second
  step elsewhere. That is the accepted cost of the tool staying this size.
  Capturing the app's own audio would mean a private sound channel per run, a
  second recorder and a merge at the end — a coherent design, and still a no.

- No editing, trimming or post-production.
- No graphical interface, no background service, no config file — options go on
  the command line.
- No plugins, no per-app profiles.
- No third kind of private screen. The ordinary one covers ordinary apps and
  `--gpu` covers the ones needing the card. The second was added because the
  first demonstrably could not do the job for Vulkan, not because more choices
  are interesting.
- No recording of your real screen. That is the entire thing it exists to avoid,
  and adding it back would make every other decision here pointless.

The test is that list, not how long the file is. A change earns its place if it
makes "record this app doing these few things" work somewhere it did not.

## Things that catch you out

**An app that only allows one copy at a time will not start here.** If a copy is
already running on your real desktop, the new one hands over to it and exits
successfully — so demoreel sees a healthy process that never showed a window.
finbreak does exactly this (FIBR-0204). Close the running copy first. The error
message says so, rather than looking like a demoreel bug.

**Nothing manages windows on the private screen.** None is needed to record one
app, and adding one is a dependency for no gain — the single window already has
focus, so demoreel does not try to give it any. An app whose dialogs need
arranging may misbehave; if that ever comes up the answer is a minimal window
manager, not more code here.

**An app that cannot use the older display system at all will not work.** Both
kinds of private screen rely on it. This is the honest limit of the design, not
a bug to fix.

**Not every window can be found and resized.** demoreel locates the window by
its name, and a few apps set none — `vkcube` is one. It says so and records
anyway, so you get the app at its own size rather than filling the frame.
Nothing is lost but the sizing.

## Constraints already verified on this machine

Checked by running them, not assumed. This section is for maintainers.

- `Xvfb`, `xauth`, `xdotool`, `wmctrl` and `ffmpeg` are installed. `xvfb-run`
  is not.
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
  This is why demoreel sets that variable to a name that cannot exist rather
  than clearing it.
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
- The `--gpu` display size comes from Xwayland's own geometry setting, not from
  the compositor. Without it, both `cage` and `weston` hand back Xwayland's
  rootful default of 640x480 and `-s` would be silently ignored.
- **The private display is private to this run, and that is enforced rather
  than assumed.** Both backends put an `MIT-MAGIC-COOKIE-1` cookie on the
  display. Measured before the cookie existed: a local client with no
  credential read the geometry and grabbed a frame of what was on screen.
  Measured after: the same client is refused, and one holding the run's cookie
  still works. File permissions on the socket are not an alternative — `Xvfb`
  listens on an abstract socket too, which has none.
- **The privacy promise is measured, not just argued.** Every other claim here
  has a measurement behind it; this one rested on the reasoning that nothing of
  the user's session is on the display, so nothing of it can be in frame. Tested
  instead: with KDE's Magnifier enabled and a window of one unique colour open
  on the real desktop, both backends recorded and every frame was decoded at
  full resolution. No pixel came within 40 of the marker colour — the closest
  was 135.8 under `Xvfb` and 117.8 under `--gpu` — and the whole `Xvfb`
  recording measured zero saturation, so nothing coloured reached it at all.
  The detector was shown able to fire: over a clip that really is the marker
  colour, encoded the same way, it matched every pixel.
- **Scripted `-a` actions work on the `--gpu` path**, not only under `Xvfb`.
  Measured: `-a 'click 130 453' -a 'key Down'` against `gtk4-demo` on the
  compositor selected the clicked row and then moved the selection down, both
  visible in the frames. Clicks and keystrokes both arrive; no extra flag, no
  different `DISPLAY`. Worth stating because the failure would have looked like
  a boring app rather than a broken feature.
- **A Wayland-only app is the design's limit.** `--nosocket=wayland` breaks such
  an app rather than redirecting it, and `--gpu` does not rescue it: that
  backend also pushes the app to X11, because a client rendering natively on the
  compositor is not in the X root window and `x11grab` cannot see it.

## Status

Working. One file, `demoreel`, Python 3 and the standard library only.

Verified by recording: a plain app, scripted typing, ending a run early with
`stop`, two concurrent recordings landing on different displays, and every
failure path leaving no stray `Xvfb` behind. Flatpak targets work too, with the
three flags shown above.

`--gpu` verified the same way, by looking at the frames: `vkcube` recorded as a
hardware-rendered spinning cube, an ordinary app sized to fill the frame,
a `--gpu` run and an `Xvfb` run side by side on different displays, and no
`cage` or `Xwayland` left running afterwards. It has since been used on a real
target — a hardware ray-traced renderer, recorded headlessly at 1280x800.

`--settle` verified against a window that is uniformly black for five seconds
and then draws: without it the recording is three seconds of black and the
blank check fails the run; with it the picture is there in the first frame.

## Checks

`./ci.sh` is the whole gate. Among its steps: the linter, at the version and
against the ruleset `ci.sh` and `ruff.toml` pin between them; a parse; a check
that every flag this README documents is one the tool accepts; a smoke recording
that samples a frame and fails if the app never reached the picture; its
counterpart, a run made to draw nothing, which must be refused rather than
returned; a run whose scripted `wait`, `type` and `key` must arrive, checked by
having the app itself write back what it received; a `-d 0` run ended with
`stop`; a check that a client with no auth cookie cannot reach the display; a
Flatpak command missing a flag, which must be named; and a run-state directory
we do not own, which must be refused. `.github/workflows/ci.yml` installs the
programs and runs that same script, and takes the linter version and the
documentation-only decision from it rather than restating them. Add a check to
`ci.sh`, never to the workflow.

It runs automatically before a push. A documentation-only push runs
`./ci.sh --docs` instead — the flag check and the readability check, not
nothing. `./ci.sh --docs-glob` is the only definition of what counts as
documentation here, and the full gate fails if the local git config has drifted
from it. The workflow does not match against that glob itself: it pipes the
changed paths into `./ci.sh --docs-mode` and runs whatever comes back, so the
decision has one home as well as its value. The pre-push hook is machine-wide,
so it still does its own matching against the glob.

## Versioning

`demoreel --version` reports the version.
[docs/standards/versioning-overrides.md](docs/standards/versioning-overrides.md)
names the surfaces that count as breaking, what reaching 1.0 requires, and how
the numbers move while the leading zero is there — which is not what most
people assume. That file is the only statement of it; this one would drift.

[CHANGELOG.md](CHANGELOG.md) records what each release contains. Nothing has
been tagged yet, so everything sits under `[Unreleased]`.

## Security

demoreel runs as you, gains no privilege and opens no network listener. The
private display is behind a one-off cookie and the run-state directory is
refused unless you own it. [SECURITY.md](SECURITY.md) names every boundary,
including the one still open — text you script with `-a` is visible to other
users of the machine while the run lasts — and says how to report anything not
listed there.

## Roadmap

`ROADMAP.md` is generated from the roadmap store and should not be hand-edited.
Query it with the roadmap verbs; a hand edit is reverted by the next write.

## License

MIT — see [LICENSE](LICENSE).
