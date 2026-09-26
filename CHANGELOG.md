# Changelog

All notable changes to demoreel are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
What counts as a breaking change here, and how the numbers move while the
leading zero is there, is
[docs/standards/versioning-overrides.md](docs/standards/versioning-overrides.md).

The `[Unreleased]` block stays at the top, always, even when empty.

## [Unreleased]

### Changed

- **Breaking: a `type` step now types its text exactly as written.** (DEMO-0101)
  `-a "type printf 'hi'"` used to type `printf hi`: the step was split
  like a shell command, which dropped quotes and squeezed repeated
  spaces, and an apostrophe stopped the whole recording with an error.
  Now everything after `type` and one space is typed as it stands. If
  you wrapped the text in an extra pair of double quotes to keep single
  quotes, remove them, or they will be typed too.

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
