# Changelog

All notable changes to demoreel are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
What counts as a breaking change here, and how the numbers move while the
leading zero is there, is
[docs/standards/versioning-overrides.md](docs/standards/versioning-overrides.md).

The `[Unreleased]` block stays at the top, always, even when empty.

## [Unreleased]

### Added

- **Draft translations in Russian, Ukrainian, Polish, Dutch, Korean and Arabic** (DEMO-0065)
  Each is a draft until a native speaker checks it, like the first batch.
  Arabic is the second right-to-left language beside Hebrew.

- **Draft translations in ten languages** (DEMO-0064)
  Messages and `--help` now come in German, French, Spanish, Italian,
  Brazilian Portuguese, Afrikaans, Hebrew, Japanese, and Simplified and
  Traditional Chinese. Each is a draft until a native speaker checks it,
  and `--help` says so on its last line. A command-line flag written
  straight against Chinese or Japanese text is now recognised as a flag,
  so the checks hold a translation to keep it. The manual page
  stays in English for now.

- **The checks refuse a translation that is incomplete or would print wrongly** (DEMO-0062)
  Before any change is accepted, every translation file must read cleanly,
  hold every message, keep each `{placeholder}` and command-line flag of
  the English, and, if marked confirmed, be unchanged since. Each language
  must also print the same file path on standard output as English.
  `./ci.sh --catalog-digest po/<code>.po` prints the fingerprint a
  confirmation records.

- **Messages can be translated, and English output is unchanged** (DEMO-0061)
  Every message on standard error and the text of `--help` now goes
  through a translation step that follows `LANGUAGE`, `LC_ALL`,
  `LC_MESSAGES` and `LANG`. Standard output, `motion`'s report and `--version` never
  change with the language, and `LC_ALL=C` always gives English. A
  translation file is treated as untrusted text (DEMO-0083).

### Changed

- **The 1.0 rule says which condition holds the version back** (DEMO-0139)
  1.0 waits only on a demoreel video being used on another project's
  README, store listing or release page. The display-path checks bind
  the gate, which a 1.0 release passes like any other.

### Security

- **`record` and `shot` take `--steps FILE`, or `--steps -` for standard input, so typed text stays out of the process list** (DEMO-0025)
  Text given with `-a type` sat in demoreel's own command line, which
  other local users can read, for the whole run. `--steps` reads the
  same steps one per line, and cannot be mixed with `-a`.

## [0.3.1] - 2026-09-30

**Theme:** Finishes what it recorded.

### Added

- **A script can style each line of text: `font`, `colour`, `outline`, `shadow`, `fade-in`, `fade-out`, `band` and `at`** (DEMO-0135)
  On a `text` line of an `edit` script, beside `size`. A font the machine
  does not have is refused, never swapped for another. The band fades
  with its text. `at top`, `at middle` or `at bottom` places it.

- **`demoreel edit`: make a finished film from a plain-text script of scenes, encoded once** (DEMO-0132)
  A script lists scenes in order: `clip FILE` with `from`, `to` and fades,
  `card SECONDS [PICTURE]`, and `text "WORDS"` on the scene above. Read
  from a file or from standard input. README, Finishing a recording.

- **`trim`, `caption`, `join` and `card`: one-step shortcuts over the same machinery as `edit`** (DEMO-0124)
  Cut the ends off a video, put text over part of it, put videos end to
  end, and make a clip from a picture or a line of text. DEMO-0127,
  DEMO-0128 and DEMO-0129 are the other three.

- **Fades, on request: `--fade-in`, `--fade-out`, `--fade-at` inside one recording, and `--crossfade` between clips** (DEMO-0131)

- **`demoreel motion`: report how often a video's picture changes and where it stands still** (DEMO-0125)
  Read-only. Prints plain `name: value` lines, or one JSON object with
  `--json`. Its `last change` is where to cut.

- **`demoreel poster`: save one frame of a video as a `.png` or `.jpg`** (DEMO-0126)

- **`demoreel check` reports whether the finishing commands and their text can run** (DEMO-0132)
  On lines of their own. They never change its exit status.

### Changed

- **The scope ceiling now allows finishing a recording, and says what editing stays out** (DEMO-0123)
  README, What it will never do: no layers, no transition other than a
  fade, no zoom, no moving text, no change of speed, and nothing removed
  from a video automatically.

## [0.3.0] - 2026-09-28

**Theme:** Friendly at a terminal.

### Added

- **The top of README shows demoreel at work: KCalc driven by scripted steps.** (DEMO-0059)
  A looping animated WebP of under 60 KB, in docs/media/, recorded by
  demoreel itself. The exact commands that made it sit beside it, so it
  is also a working example of scripted steps.

- **README has an Install section, and its quick start is written for a person.** (DEMO-0058)
  One install line per distro for openSUSE, Debian and Ubuntu, Fedora
  and Arch, the Packman and RPM Fusion step for an ffmpeg that can write
  the video, then clone, link and `demoreel check`. Every step was run in
  a clean container of each distro. The gate holds each install line to
  the package table `demoreel check` prints from. The quick start adds
  watching the video, and no longer names a path on one machine.

- **A man page, `demoreel.1`.** (DEMO-0057)
  Every command, option and step, the exit statuses, the files a run
  keeps, and the Flatpak and `--gpu` notes. `man ./demoreel.1` reads it
  in place until the 0.5.0 packages install it. The gate checks it names
  everything demoreel accepts and renders without a groff warning.

- **Tab completion for bash, zsh and fish, in `completions/`.** (DEMO-0056)
  Completes the subcommands, every option, the step names after `-a`,
  the names of recordings still running after `demoreel stop`, and the
  app's own command line after `--`. README § Tab completion says how to
  turn it on. The gate asks each shell what it offers and holds the answer
  against demoreel's own parser.

- **`demoreel --help` and `demoreel record --help` end with worked examples.** (DEMO-0050)
  A timed recording, `-d 0` with `stop`, scripted steps, `--gpu`, and a
  Flatpak with its three flags, ready to copy. The gate parses every
  example with demoreel's own parser, so none can go stale.

- **`demoreel check` says whether this machine can record, without recording.** (DEMO-0052)
  It checks every program each backend needs, that ffmpeg can encode the
  video, and that a private display starts; `--gpu` also needs a graphics
  render node. Anything missing comes with its install command.

- **A missing program is named with the command that installs it on your distro.** (DEMO-0051)
  openSUSE, Debian, Ubuntu, Fedora and Arch; the package names were looked
  up in each distro's own package index.

- **A `hold KEY SECONDS` step holds a key down, for apps that move while a key is held.** (DEMO-0098)
  `-a 'hold w 3'` walks forward for three seconds in a 3D scene. The key is
  let go however the step ends, a stop included.

- **At a terminal, a recording shows how long is left, then the video's length and size.** (DEMO-0053)
  One short line updates in place; a `-d 0` run shows how long it has been
  going. Output to a script or a file is unchanged.

- **A `--gpu` recording that barely changes now gets a note saying it may stutter.** (DEMO-0109)
  A busy 3D app recorded with --gpu came out as a slideshow with no
  message: the picture demoreel reads was refreshed only a few times a
  second. demoreel now measures how often the middle of a --gpu video
  changes, and says so when it is rarely. The stutter itself is fixed
  by DEMO-0111, below.

### Changed

- **A recording uses about half the memory it did.** (DEMO-0073)
  The video encoder now runs four threads, not a number scaled to the
  processor's cores. On
  a twelve-core machine its peak dropped from about 537 MB to about
  270 MB, with no dropped frames on a busy app.

- **`stop` and the end of a recording return about 0.1 s sooner.** (DEMO-0076)
  The blank check asks only whether one grey level covers more than 99.9%
  of a frame, and now counts one likely candidate instead of every value:
  under 1 ms on a busy 1600x1000 frame instead of about 100 ms, with the
  same answer. The halfway sample and `--settle` get the same saving.

- **A run whose private display stops answering now fails in about 13 seconds, not 38.** (DEMO-0078)
  Once a call to the display times out, the run has failed and returns no
  video. The recorder and the display are now ended at once, rather than
  each being given a graceful stop that could only run out its timeouts
  on the frozen display.

- **Error messages now say what happened, why, and what to do next.** (DEMO-0055)
  A mistyped `-a` step is caught before anything starts and shows how to
  write it, where it used to end the run with a Python traceback. Other
  failures point at `demoreel check`, the setting to raise, or the log
  that says why.

- **A stop ends the recording at once, instead of up to a fifth of a second late.** (DEMO-0075)
  That extra tail used to end up in the video: a median 107 ms, now under
  a millisecond. A stop during a scripted `wait` step also ends it at once,
  where it used to sit out the whole wait.

- **Breaking: `--gpu` now needs `cage`, `Xwayland`, `wlr-randr` and `xauth`, and `record --gpu` also `wf-recorder`; `xwfb-run` is no longer used.** (DEMO-0111)
  demoreel starts the compositor and the X screen itself, so it can size
  the screen before the X server starts. On openSUSE all of them are in
  the OSS repository.

- **Breaking: `record --gpu --cursor` is refused.** (DEMO-0111)
  The compositor's picture never has the pointer in it, so the option
  could not be honoured. `shot --gpu --cursor` still draws the pointer.

- **Breaking: the pointer now starts in the bottom-right corner, not the centre.** (DEMO-0103)
  A fresh private screen put the pointer in the middle, where it lit up
  whatever the app drew under it before any step ran, even with no
  pointer drawn. demoreel now parks it in the corner first. A bare
  `click` before any `move` now clicks the corner; give it a position,
  or `move` first, to click the middle.

- **Breaking: a `type` step now types its text exactly as written.** (DEMO-0101)
  `-a "type printf 'hi'"` used to type `printf hi`: the step was split
  like a shell command, which dropped quotes and squeezed repeated
  spaces, and an apostrophe stopped the whole recording with an error.
  Now everything after `type` and one space is typed as it stands. If
  you wrapped the text in an extra pair of double quotes to keep single
  quotes, remove them, or they will be typed too.

### Fixed

- **On a distro whose ffmpeg cannot encode H.264, recording stops at once and says which ffmpeg to install.** (DEMO-0117)
  The ffmpeg that openSUSE and Fedora ship themselves leaves out libx264,
  which every recording uses. demoreel now names Packman (openSUSE) or RPM
  Fusion (Fedora).

- **A recording whose encoder died partway now fails, instead of handing back a file that will not play.** (DEMO-0116)
  demoreel reads the finished video back before it prints the path.

- **Closing the terminal mid-recording now finishes the video and leaves nothing running.** (DEMO-0115)
  It used to end demoreel on the spot and leave the private display running
  in the background. `shot` tidies up the same way when it is sent SIGTERM
  or SIGHUP. The recorder is also out of reach of the terminal's signals now, so
  it cannot be cut off before its file is finished.

- **Ctrl+C finishes a foreground recording properly, and README now says so.** (DEMO-0054)
  Ctrl+C at a terminal also reached the private display, which shut down
  with the app on it, so the final check for a blank picture was skipped.
  The display is now out of Ctrl+C's reach, and the check runs.

- **Busy 3D apps recorded with `--gpu` now come out smooth and at full size.** (DEMO-0111)
  demoreel used to read the picture from the X side, which a busy app
  refreshed only a few times a second, so a smooth game recorded as a
  slideshow. `record --gpu` now records the compositor's own picture
  with wf-recorder: on Vestige's fly-through at 1920x1080, 750 of 751
  frames were new, against 156 of 588 before. The stutter note stays,
  and now means the app itself drew few frames.

- **A blank `--gpu` recording no longer tells you to record with `--gpu`.** (DEMO-0110)
  Its advice now fits the backend that ran: on `--gpu` it names the app
  not having drawn yet, and `--settle`, which waits for it.

### Security

- **A symlink another user planted at `-o` or `--app-log` is refused instead of written through.** (DEMO-0082)
  demoreel resolved these paths itself, so the kernel's symlink protection
  never saw the link, and a planted /tmp/demo.mp4 could overwrite any file
  of yours it pointed at. A link you made yourself is still followed.

- **The private screen's lock is proven on before the app starts, on both backends.** (DEMO-0113)
  A client without the run's auth cookie must be refused and one holding it
  must connect. The old Xvfb check tried only the holder, which gets in
  before the lock as well as after. Measured: Xvfb's lock was already on in
  practice, because nothing connects before the cookie is written; the
  check now proves it instead of relying on that.

## [0.2.2] - 2026-09-26

### Added

- **`demoreel shot` saves one picture of an app, on the same private screen as a recording.** (DEMO-0100)
  `demoreel shot -o pic.png -- myapp` starts the app privately,
  waits for it to draw, runs any -a steps, saves one PNG and prints its
  path. Nothing from your real desktop can be in it. A flat picture
  fails the run, as a blank recording does. It takes record's options
  apart from -d, -r and -n, and the size need not be even.

### Fixed

- **A `shot` that fails now always says where it kept its logs.** (DEMO-0107)
  A shot that failed before taking its picture, for example because
  the app could not start, kept its small log folder in memory without
  saying where. Every failure now names the folder, so it can be read
  and then deleted.

- **A private display that stops answering now fails the run instead of hanging it.** (DEMO-0079)
  Each call to the display used to wait for as long as the display
  did, so a frozen display hung demoreel for good. Every window call
  and frame check now gives up after 10 seconds. The run then fails,
  saying the display stopped answering.

- **An app that resizes itself after demoreel sizes it is now warned about.** (DEMO-0099)
  The window used to record cropped or off to one side with no
  message, because the picture was not flat and every check passed.
  demoreel now checks the window when it checks for a blank display,
  and says what size the app chose, so you can record again with -s
  set to it.

## [0.2.1] - 2026-09-25

### Fixed

- **An app that makes the virtual display print a lot no longer freezes the recording.** (DEMO-0049)
  The display's messages went into a pipe nobody read after startup. An
  app loading many keyboard maps, GIMP among them, filled it, and the
  display and demoreel both hung with no timeout. They now go to a log
  file, kept when a run fails.

- **`demoreel stop` now waits for the video to be finished and checked before printing its path.** (DEMO-0047)
  It used to print the path the moment it signalled the run. A script
  reading the file straight away could get a half-written video, and a
  run that then failed its blank check had already handed back a path.
  Now `stop` prints the path only if the run succeeded, and otherwise
  exits with an error.

## [0.2.0] - 2026-09-20

### Changed

- **A recording still blank halfway through `-d` now fails there.** (DEMO-0008)
  The blank check used to look only at the end, so an app that drew
  something in the last moments passed with a mostly empty video. It now
  also looks halfway through the countdown. `-d 0` runs have no halfway
  point and keep the end check only. A run that used to succeed can now
  fail.

- **`-d` now gives a clip of about the length asked for, and runs start faster.** (DEMO-0012)
  `-d 3` used to produce about 4.2 seconds of video. It now produces
  about 3.2. Each run also finishes about 1.4 seconds sooner, because
  demoreel waits for things to actually happen instead of sleeping for a
  fixed time.

- **`demoreel stop` works straight after the run is launched.** (DEMO-0034)
  A run used to be unreachable until it was already recording, so a
  stop issued too early said no such recording existed. stop now finds a
  starting run, waits for it to record, and stops it. The retry loop the
  README showed is gone. A stop for a name that is not running now takes
  a second to say so.

### Fixed

- **Apps that title their window only the modern way, such as vkcube, are now found.** (DEMO-0043)
  demoreel looked only at a window's older title property, so these
  windows were never found. Every such run waited the full 20 second
  startup timeout and recorded the window at its own size, not filling
  the frame. A `--gpu -- vkcube` run now takes about 4 seconds instead of
  24.

- **Two runs started together under one name no longer both record.** (DEMO-0011)
  The later one's state file used to hide the earlier one from
  `demoreel stop`. The duplicate-name check is now a lock, so exactly one
  records and the other exits with an error.

- **The blank check no longer passes a video it could not look at.** (DEMO-0033)
  When its sample of the screen failed, the check used to report "not
  blank", so the run succeeded. That now fails the run with the reason,
  and --settle stops instead of waiting blind. A run that used to succeed
  can now fail, which is why this is in a MINOR.

## [0.1.1] - 2026-09-08

### Added

- **demoreel records a GUI app on a private virtual display.** One command
  takes the app to run and gives back a video file: it starts the display,
  launches the app on it, sizes the window to the frame, records with `ffmpeg`,
  optionally replays scripted actions, and tears everything down. Nothing of
  the user's real desktop is in frame, because the app never runs there.
  Two display backends: `Xvfb` by default, and `--gpu` for an app that needs
  the graphics card. Everything in this block is the first release; nothing has
  been tagged yet.

- **The pre-push gate ships with the repository.** (DEMO-0027)
  `git config core.hooksPath .githooks` turns it on after cloning. The gate
  previously reached this project through settings on one machine, so a fresh
  clone had `ci.sh` and nothing that ran it.

### Fixed

- **An app that exits without a window is no longer told it is a single-instance app.** (DEMO-0026)
  That was one possible cause stated as the established one. A command that
  simply finished without needing a window got the same message. It now says
  what happened, offers the hand-over as the likely cause, and names the
  other case.

### Security

- **The private display is behind an auth cookie on both backends.** (DEMO-0017)
  Every client is handed an `MIT-MAGIC-COOKIE-1` credential through an
  Xauthority file at mode 0600. Measured before the guard existed: a local
  process with no credential read the display's geometry and grabbed a frame
  of whatever was on screen. Socket permissions were no substitute, because
  `Xvfb` also listens on an abstract socket, which has none.

- **Text passed to `-a type` no longer appears in the system process list.** (DEMO-0018)
  It reaches `xdotool` on stdin instead of as an argument. It is still on
  demoreel's own command line, because the caller wrote it there, and
  SECURITY.md keeps that as a stated boundary rather than implying it is
  closed.

- **The run-state directory is checked before it is used.** (DEMO-0019)
  Without `XDG_RUNTIME_DIR` the fallback path is predictable, so on a shared
  machine another user can create it first. demoreel now refuses anything
  that is not a directory it owns, and looks with `lstat` so a planted
  symlink is seen rather than followed.

- **`demoreel stop` no longer signals a process it did not start.** (DEMO-0036)
  A run killed abruptly leaves its state file behind, and the system reuses
  process numbers -- so stop could send a terminating signal to whatever
  inherited the number. Reproduced against an unrelated `sleep`, which died.
  The run's start time is now recorded beside its process number and checked
  first.

- **The CI workflow keeps its token off disk and its values out of shell.** (DEMO-0037)
  Checkout no longer persists the job's credentials, where every later step
  could read them, and step values are passed through the environment rather
  than pasted into the script before the shell sees them. With DEMO-0038.
