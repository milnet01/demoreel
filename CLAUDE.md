# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## State

Working. The whole tool is one executable file, `demoreel` — Python 3, standard
library only, no build step, no dependency manifest. Runtime dependencies are
`xauth`, `ffmpeg` and `xdotool` on both backends; `Xvfb` for the default one;
`cage`, `Xwayland` and `wlr-randr` for `--gpu`, and `wf-recorder` for
`record --gpu`. `pactl` is optional: without it a run's app may be heard on
the speakers, and `record --audio` is refused. All are checked at startup
against what the run will use. The
finishing commands need `ffmpeg` and `ffprobe` alone, and `fc-match` to find a
bold font for text.

`ROADMAP.md` is generated from the roadmap store. Do not hand-edit it — use the
roadmap verbs, or the next write reverts your edit.

`README.md` is the design contract; `docs/specs/` holds the specs written
beside it. The sections below are the parts a session is most likely to break by accident.

Verify a change by running `./ci.sh`. Among its steps: the linter, a parse, a
check that every flag `README.md` documents is one the tool accepts, and a
smoke recording that samples a frame and fails if the app never reached the
picture. It is the same script CI runs, and it runs before a push. Add a check
there, never to the workflow. `./ci.sh --docs` is the documentation-only
subset, which a documentation-only push selects. `./ci.sh --finishing` runs
only the finishing commands' checks, which need no display; it is for working
on them, and the full gate runs them too. `./ci.sh --release-chain` runs only
the checks of tab completion, the release tag, the OBS scripts, attaching files
and `.githooks/pre-push`, against stand-ins and scratch repositories, so nothing
can reach a real remote. The full gate runs them too. A workflow runs only on
GitHub, so keep its logic in `ci.sh`, where those checks can reach it.

To read a gate's saved output, such as a `cc-job` log, run `./ci.sh --summary
<log>` rather than reading the log. It prints the slowest steps, the steps
that skipped and, on a failure, only the step that failed.

`./ci.sh --option-places OPTION COMMAND...` lists every file that must name an
option of those commands, each present or missing.

`./ci.sh --perf` measures what each command costs and fails on CPU time or peak
memory over 1.5 times `docs/perf-baseline.tsv`. Wall time is recorded, not
judged. Run it by hand before a release: it takes minutes, refuses a load of 10
or more, and the gate does not run it. `./ci.sh --perf-baseline` replaces the
figures. They belong to the machine and ffmpeg the file's header names. Peak
memory is the largest single process, not the sum.

To give a new message its drafts in every language, run `./ci.sh
--add-message DRAFTS.json` after `./ci.sh --pot`. It checks each language
with `msgfmt -c` and the gate's catalog checks, and names the ones that fail.
It writes `po/` only when all pass. The file's shape is in the comment above
it in `ci.sh`.

The full gate ends by running itself again in a local `ubuntu:24.04` image
built from the same package list the workflow installs (`./ci.sh
--ci-packages`), so a difference in GitHub's older packages fails here first.
`./ci.sh --parity-build` builds the image; a changed package list or ruff
version changes its tag and asks for a rebuild. Without it the gate's last line
says the Ubuntu step was skipped. That is not a pass. GitHub's packages move
weekly and the image does not, so the step prints a note once the image is two
weeks old; rebuild then.

`packaging/` builds the `.deb`, the `.rpm` and the Arch package, and
`packaging/install.sh` alone decides where an installed file goes.
`./ci.sh --packages` builds all three and installs each in a clean container of
every distro it targets (`docs/specs/DEMO-0068-linux-packages.md`), then runs
README § Install from source in each (DEMO-0072). The full
gate runs it where `podman` is; GitHub runs it in its own job, and
`release.yml` runs it again to attach the files to a published release, in the
images `packaging/release-images` pins (`./ci.sh --release-images` refreshes it).
After the build wave its containers mount the files read-only.

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

It also finishes a recording: `edit` makes a film from a plain-text script of
scenes, `trim`, `caption`, `join` and `card` are one-scene shortcuts over the
same renderer, and `motion`, `poster`, `thumbnail` and `sheet` read a video
without changing it.
These work on files. They start no display and take no run name.

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
scope: webcam, cursor highlighting, a GUI, a daemon, a config file
format, plugins, per-app profiles, and recording the real screen. Anything
needing more than "record this app doing these few things, and make that
recording fit to publish" wants OBS and a video editor instead.

**Editing stops at finishing a recording and making a short trailer from
it.** `README.md` § What it will never do holds the list of what editing may
do, and nothing off it is built. Still out: a clip laid over another picture,
except one clip's window over its background; two clips on screen together
outside a transition; pan and rotate beyond the list's zoom; animating
a setting over time in general; and anything removed from a video
automatically. An `edit` script is a
list of scenes for one film. It is not a config file: it holds no settings
for demoreel and is read only when named.

**Do not report or reason about the line count.** Judge a change by whether it
earns its place against the list above, and say nothing about length.

**Sound is in scope, and only ever by the caller's choice.** An app's own
sound goes into a video only with `--audio`, and no recorded app's sound
reaches the user's speakers: `docs/specs/DEMO-0106-app-sound.md` is the
contract. A clip's sound kept through the finishing commands, and music under
a film, are `docs/specs/DEMO-0177-film-music.md`.

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
  unsetting `WAYLAND_DISPLAY` useless — see the trap below. Measured with GTK4:
  inherited → no window on Xvfb; unset → no window on Xvfb; set to an
  unresolvable name → window appears. Measured 2026-10-22, set empty → window
  appears for GTK3, GTK4, Qt, SDL (`ffplay`), a winit app, a Flatpak with and
  without `--nosocket=wayland`, and `vkcube` and `glxgears` on `--gpu`.
  `strace` shows libwayland then connecting to `/run/user/1000/`, which
  refuses.
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

- **The app's private sound output needs two variables, `PULSE_SINK` and
  `PIPEWIRE_NODE`, never one.** With `PULSE_SINK` alone, an ALSA app (`aplay`)
  goes through PipeWire's ALSA plugin to the user's speakers, and so does a
  native PipeWire app. Measured: dropping `PIPEWIRE_NODE` sent two of the
  gate's three tones to the real output. Do not "tidy" `Sound.env` down to
  one. A probe that plays sound outside demoreel needs both too.

- **`WAYLAND_DISPLAY` is set empty, not unset and not to a made-up name,
  and that is not a stylistic choice.** `wl_display_connect(NULL)`
  falls back to the hardcoded `$XDG_RUNTIME_DIR/wayland-0` when the variable is
  absent, so `env.pop()` sends the app straight to the user's real compositor;
  `Xvfb` then records black, `ffmpeg` exits 0 and every signal says success.
  An empty value is not absent to libwayland: the connection fails, and the
  toolkit falls back to X11. A made-up name does that too, but winit reads any
  non-empty value as "use Wayland" and never falls back, so it stopped every
  winit app at start (DEMO-0281). An inherited `WAYLAND_SOCKET` is removed
  from every process demoreel starts: libwayland reads it ahead of
  `WAYLAND_DISPLAY`, and winit when that is empty. With it set, a winit app
  aborted at start under the empty value, and `record --gpu` failed before
  recording (measured 2026-10-22). Do not "tidy" `WAYLAND_DISPLAY` back to a `pop()` or to a
  name. Do not neutralise `XDG_RUNTIME_DIR` instead: that variable also
  carries the D-Bus and PipeWire socket paths.
  Do not reach for `QT_QPA_PLATFORM=xcb` — same objection as the Flatpak note
  below, it is Qt-only.
- **The app is told `XDG_SESSION_TYPE=x11`, and that is what lets a Chromium
  or Electron app start.** Chromium picks Wayland when the inherited value is
  `wayland`, then exits when it cannot connect instead of falling back: a
  Brave Flatpak stopped at start with "Failed to initialize Wayland platform"
  (DEMO-0283). The value is true on both backends, since the app's display is
  X11 on each. Do not drop it as redundant beside the empty
  `WAYLAND_DISPLAY`, and do not swap it for `--ozone-platform=x11`, which is
  per-app knowledge.
- **stdout carries the finished path and nothing else.** The app's own output
  goes to our stderr, or to `--app-log`, never to stdout — a caller writing
  `out=$(demoreel record ...)` collects whatever the app printed otherwise.
  `subprocess.Popen` inherits the parent's stdout unless told not to, so the
  way to reintroduce the bug is to drop the `stdout=` argument, not to add
  anything. The finishing commands keep the rule: the path alone, and their
  plan on stderr. `motion` writes no file, so its report is what it prints on
  stdout.
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
  left an empty display behind, and that video is fine. So is a blank sample
  with the app gone within `CLOSING_GRACE`: its window goes before its process. The check exists
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
  one app needs no WM. So `xdotool windowactivate` is skipped, and
  `fill_frame` sets focus with `windowfocus`, which needs no WM. Do not drop
  it as redundant: GTK and Qt take keys without it, but a winit app ignores
  every `key` and `type` step until it is focused (DEMO-0206). An app whose
  dialogs need stacking or positioning may
  misbehave; the answer would be a minimal WM, not more code here.
- **Every message goes through `tr`, `trn`, `tr_help` or `tr_listed`, and
  never at import time.** The language is chosen in `main()`, so a message translated at
  import is always English, and passes every check that runs in English. The
  gate refuses one (DEMO-0060 INV-15). A message is one or more whole
  sentences; never join translated fragments, because word order differs
  between languages. A command line, a flag name, a path and stdout are never
  translated.
- **No code reads a meaning out of a translated string.** Where a caller needs
  a reason, it gets one from an exception or a return value: `TextUnavailable`
  is how `demoreel check` learns why text cannot be drawn. Splitting a message
  into lines to print each with the prefix is layout, and is fine.
- **`ci.sh` runs under `LC_ALL=C`**, so its English matches pass whatever the
  developer's locale. A step that tests a translation removes it for its own
  runs, with `env -u LC_ALL`, or it passes without testing anything. A changed
  English message also needs `./ci.sh --pot`, or the template step fails.

## Flatpak targets: plain first, three flags as the fallback

A plain `flatpak run <app-id>` records. Under demoreel's empty
`WAYLAND_DISPLAY`, Flatpak gives the sandbox no Wayland socket, so a
`sockets=fallback-x11;wayland` manifest binds X11, and to the private display
named in `DISPLAY`. Measured 2026-10-22 with finbreak and PeaZip (fallback-x11)
and VICE (x11 only), no flags, each drawing. Before DEMO-0281 the made-up name
counted as Wayland present, so fallback-x11 bound nothing and the flags were
required. A Brave Flatpak, which needed `XDG_SESSION_TYPE=x11` as well,
records plain since DEMO-0283, on both backends.

README keeps the three flags as the fallback for an app the plain command does
not bring up:

    demoreel record -o demo.mp4 -- \
      flatpak run --socket=x11 --nosocket=wayland --filesystem=/tmp/.X11-unix <app-id>

`--socket=x11` and `--filesystem=/tmp/.X11-unix` grant X11 to a manifest that
lacks it. `--nosocket=wayland` is a spare guard, kept in the recipe by the
user's decision (2026-10-22): it costs nothing, and holds if demoreel's
environment changes. Do not drop it from the recipe as dead. demoreel no
longer warns about missing flags (DEMO-0284, user's decision 2026-10-22): the
warning fired on plain commands that work.

**Do not swap the flags for `QT_QPA_PLATFORM=xcb`**, which is the fix most search
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

Moved to `.claude/rules/gpu-backend.md`, which loads when a session reads
`demoreel` or `ci.sh`. Read it before changing the `--gpu` path.

## The finishing commands

Moved to `.claude/rules/finishing-commands.md`, which loads when a session
reads `demoreel` or `ci.sh`. Read it before changing `edit`, its shortcuts,
`motion`, `poster`, `thumbnail` or `sheet`.

## Wayland-only apps: the limit of this design

An app that cannot speak X11 at all will not run on `Xvfb`, and
`--nosocket=wayland` breaks it rather than redirecting it. `--gpu` does not
help either — that backend pushes the app to X11, for the reason
`.claude/rules/gpu-backend.md` gives. This is
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
